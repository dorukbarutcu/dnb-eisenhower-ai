import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/gemini_response_model.dart';

class GeminiDatasource {
  final String apiKey;
  final String modelName;

  GeminiDatasource({
    required this.apiKey,
    this.modelName = 'gemini-3.8-flash',
  });

  static const String _systemInstruction = '''
You are the intelligence engine of "DNB Eisenhower AI", an executive task manager and automated calendar scheduler.
Your mission is to analyze incoming communications (WhatsApp, Telegram, SMS notifications, Gmail unread threads, Voice notes, or manual inputs), extract actionable tasks, classify them into the Eisenhower Matrix, and configure appropriate Google Calendar events.

The Eisenhower Matrix Rules:
- Q1 (Do First): High Urgency (>=7), High Importance (>=7). Color ID: 11 (Flamingo/Red). Crises, tight deadlines, critical blockers.
- Q2 (Schedule): Low Urgency (<7), High Importance (>=7). Color ID: 9 (Blue). Deep work, planning, career/health goals, high-value strategic tasks.
- Q3 (Delegate): High Urgency (>=7), Low Importance (<7). Color ID: 5 (Yellow). Interruptions, requests from others, administrative tasks.
- Q4 (Eliminate): Low Urgency (<7), Low Importance (<7). Color ID: 8 (Gray). Distractions, trivia, spam, low priority social banter.

Google Calendar Rules:
- should_add is true if the task has an explicit or implicit time commitment or deadline.
- When generating start_iso and end_iso, use the user's current local time provided in the prompt as reference.
- Default task duration should typically be 30 to 60 minutes unless stated otherwise.
- color_id MUST be chosen according to quadrant:
  - Q1: "11"
  - Q2: "9"
  - Q3: "5"
  - Q4: "8"

You MUST output ONLY valid JSON matching this schema:
{
  "summary": "String",
  "processed_tasks": [
    {
      "task_id": "String (uuid)",
      "title": "String",
      "description": "String",
      "source": "WhatsApp | Telegram | SMS | Gmail | Voice_Input | Manual_Text",
      "quadrant": "Q1 | Q2 | Q3 | Q4",
      "urgency_score": 1,
      "importance_score": 1,
      "reasoning": "String",
      "calendar_event": {
        "should_add": true,
        "summary": "String",
        "description": "String",
        "start_iso": "YYYY-MM-DDTHH:mm:ss",
        "end_iso": "YYYY-MM-DDTHH:mm:ss",
        "color_id": "11 (Q1 Red) | 9 (Q2 Blue) | 5 (Q3 Yellow) | 8 (Q4 Gray)",
        "reminders_minutes_before": [15, 60]
      }
    }
  ]
}
''';

  Future<GeminiResponseModel> processInput({
    required String rawContent,
    required String source,
    DateTime? currentDateTime,
    Function(String status)? onProgress,
  }) async {
    final now = currentDateTime ?? DateTime.now();

    final promptText = '''
Current Local Time: ${now.toIso8601String()}
Input Source: $source
Raw Communication / Data:
$rawContent
''';

    // Strictly Gemini 3.8 models supported by current API
    final cleanSelectedModel = modelName.contains('3.8') ? modelName : 'gemini-3.8-flash';
    final modelsToTry = <String>[
      cleanSelectedModel,
      if (cleanSelectedModel != 'gemini-3.8-flash') 'gemini-3.8-flash',
      if (cleanSelectedModel != 'gemini-3.8-pro') 'gemini-3.8-pro',
    ];

    Exception? lastError;

    for (var attempt = 1; attempt <= 3; attempt++) {
      for (var i = 0; i < modelsToTry.length; i++) {
        final currentModel = modelsToTry[i];

        final client = GenerativeModel(
          model: currentModel,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.2,
          ),
          systemInstruction: Content.system(_systemInstruction),
        );

        try {
          if (attempt > 1 || i > 0) {
            onProgress?.call('Yapay zeka işliyor ($currentModel - Deneme $attempt/3)...');
          }

          final response = await client.generateContent([Content.text(promptText)]);
          final responseText = response.text;

          if (responseText == null || responseText.trim().isEmpty) {
            throw Exception('Gemini API boş yanıt döndürdü.');
          }

          var cleaned = responseText.trim();
          if (cleaned.startsWith('```json')) {
            cleaned = cleaned.substring(7);
          }
          if (cleaned.startsWith('```')) {
            cleaned = cleaned.substring(3);
          }
          if (cleaned.endsWith('```')) {
            cleaned = cleaned.substring(0, cleaned.length - 3);
          }
          cleaned = cleaned.trim();

          final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
          return GeminiResponseModel.fromJson(decoded);
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          final errStr = e.toString().toLowerCase();

          final is503Overload = errStr.contains('503') ||
              errStr.contains('high demand') ||
              errStr.contains('unavailable');

          final isQuotaRateLimit = errStr.contains('quota') ||
              errStr.contains('rate') ||
              errStr.contains('429') ||
              errStr.contains('exceeded');

          if (is503Overload || isQuotaRateLimit) {
            final match = RegExp(r'retry in (\d+(\.\d+)?)s').firstMatch(e.toString());
            final secondsToWait = match != null
                ? (double.tryParse(match.group(1) ?? '15')?.ceil() ?? 15) + 1
                : 15;

            if (attempt < 3) {
              onProgress?.call(
                'Sunucu yoğunluğu / kota sınırı. $secondsToWait saniye beklenip tekrar denenecek ($attempt/3)...',
              );
              await Future.delayed(Duration(seconds: secondsToWait));
              break; // Retry outer loop
            }
          } else {
            // Irrecoverable error
            rethrow;
          }
        }
      }
    }

    throw lastError ?? Exception('Gemini 3.8 modelleri yanıt vermedi.');
  }
}
