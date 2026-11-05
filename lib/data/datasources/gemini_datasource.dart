import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/gemini_response_model.dart';

class GeminiDatasource {
  final String apiKey;
  final String modelName;

  GeminiDatasource({
    required this.apiKey,
    this.modelName = 'gemini-3.6-flash',
  });

  static Future<List<String>> fetchSupportedModels(String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return [
        'gemini-3.6-flash',
        'gemini-3.5-flash',
        'gemini-3.5-flash-lite',
        'gemini-3.1-flash-lite',
        'gemini-3-flash-preview',
        'gemma-4-31b-it',
      ];
    }

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final models = json['models'] as List<dynamic>?;

        if (models != null) {
          final List<String> supported = [];
          for (final m in models) {
            final methods = m['supportedGenerationMethods'] as List<dynamic>?;
            if (methods != null && methods.contains('generateContent')) {
              var name = m['name']?.toString() ?? '';
              if (name.startsWith('models/')) name = name.substring(7);
              // Only keep active 3.x flash and gemma models (exclude deprecated 1.x and 2.x)
              if (!name.contains('1.5') && !name.contains('2.0') && !name.contains('2.5') && !name.contains('embedding') && !name.contains('image') && !name.contains('tts')) {
                supported.add(name);
              }
            }
          }
          if (supported.isNotEmpty) {
            return supported;
          }
        }
      }
    } catch (e) {
      debugPrint('Gemini fetchSupportedModels error: $e');
    }

    return [
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
      'gemini-3-flash-preview',
      'gemma-4-31b-it',
    ];
  }

  static const String _systemInstruction = '''
You are the intelligence engine of "DNB Eisenhower AI", an executive task manager and automated calendar scheduler.
Your mission is to analyze incoming communications (WhatsApp, Telegram, SMS notifications, Gmail unread threads, Voice notes, or manual inputs), extract actionable tasks, classify them into the Eisenhower Matrix, and configure appropriate Google Calendar events.

The Eisenhower Matrix Rules:
- Q1 (Do First): High Urgency (>=7), High Importance (>=7). Color ID: 11 (Flamingo/Red). Crises, tight deadlines, critical blockers.
- Q2 (Schedule): Low Urgency (<7), High Importance (>=7). Color ID: 9 (Blue). Deep work, planning, career/health goals, high-value strategic tasks.
- Q3 (Delegate): High Urgency (>=7), Low Importance (<7). Color ID: 5 (Yellow). Interruptions, requests from others, administrative tasks.
- Q4 (Eliminate): Low Urgency (<7), Low Importance (<7). Color ID: 8 (Gray). Distractions, trivia, spam, low priority social banter.

Non-Actionable Communications & Chatter:
- If the incoming message is casual chatter, greeting (e.g. "selam", "günaydın", "naber"), acknowledgment ("tamam", "ok", "anlaştık"), 2FA/OTP login code, or contains NO real to-do, task, obligation or meeting, DO NOT fabricate a task.
- In that case, return an empty list "processed_tasks": [] and explain why in "summary" (e.g. "Bilgilendirme/sohbet mesajı, yapılacak görev bulunamadı.").

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
$_systemInstruction

Current Local Time: ${now.toIso8601String()}
Input Source: $source
Raw Communication / Data:
$rawContent

Return ONLY the raw JSON object. Do not include markdown code fences or any conversational prefix.
''';

    final cleanSelected = modelName.trim().replaceAll('models/', '');
    final modelsToTry = {
      if (cleanSelected.isNotEmpty &&
          !cleanSelected.contains('2.5') &&
          !cleanSelected.contains('2.0') &&
          !cleanSelected.contains('1.5'))
        cleanSelected,
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
      'gemini-3-flash-preview',
      'gemma-4-31b-it',
    }.toList();

    Exception? lastError;

    for (var attempt = 1; attempt <= 2; attempt++) {
      for (var i = 0; i < modelsToTry.length; i++) {
        final currentModel = modelsToTry[i];
        debugPrint('Gemini REST: trying model $currentModel (attempt $attempt)...');

        try {
          onProgress?.call('Yapay zeka işliyor ($currentModel)...');

          final rawText = await _executeGenerateContent(
            model: currentModel,
            prompt: promptText,
          );

          if (rawText.trim().isEmpty) {
            throw Exception('Gemini boş yanıt döndürdü.');
          }

          var cleaned = rawText.trim();
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

          // Locate first { and last } to avoid any preamble
          final firstBrace = cleaned.indexOf('{');
          final lastBrace = cleaned.lastIndexOf('}');
          if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
            cleaned = cleaned.substring(firstBrace, lastBrace + 1);
          }

          final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
          return GeminiResponseModel.fromJson(decoded);
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          final errStr = e.toString().toLowerCase();
          debugPrint('Gemini REST error with $currentModel: $e');

          // 1. Invalid API key check
          if (errStr.contains('api_key_invalid') ||
              errStr.contains('api key not valid') ||
              errStr.contains('invalid_argument')) {
            throw Exception('Geçersiz Gemini API Anahtarı. Lütfen Ayarlar\'dan API anahtarınızı kontrol edin.');
          }

          // 2. Model not found (404) or unsupported -> seamlessly try next model
          if (errStr.contains('not found') ||
              errStr.contains('404') ||
              errStr.contains('not supported')) {
            onProgress?.call('$currentModel desteklenmiyor, sıradaki modele geçiliyor...');
            continue;
          }

          // 3. 503 Overload or 429 Rate Limit
          if (errStr.contains('503') ||
              errStr.contains('high demand') ||
              errStr.contains('quota') ||
              errStr.contains('429')) {
            if (attempt < 2 && i == modelsToTry.length - 1) {
              onProgress?.call('Kota/yoğunluk limiti. 10 saniye beklenip tekrar denenecek...');
              await Future.delayed(const Duration(seconds: 10));
              break;
            } else {
              continue;
            }
          }

          continue;
        }
      }
    }

    throw lastError ?? Exception('Gemini modellerine bağlanılamadı.');
  }

  Future<String> _executeGenerateContent({
    required String model,
    required String prompt,
  }) async {
    final client = HttpClient();
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${apiKey.trim()}',
    );

    final request = await client.postUrl(url);
    request.headers.set('Content-Type', 'application/json; charset=utf-8');

    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
      }
    };

    final bytes = utf8.encode(jsonEncode(payload));
    request.add(bytes);

    final response = await request.close().timeout(const Duration(seconds: 25));
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini yanıt üretmedi.');
      }
      final first = candidates[0] as Map<String, dynamic>;
      final content = first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini yanıt içeriği boş.');
      }
      return parts[0]['text']?.toString() ?? '';
    } else {
      String errMsg = 'HTTP ${response.statusCode}';
      try {
        final errJson = jsonDecode(body) as Map<String, dynamic>;
        final errObj = errJson['error'] as Map<String, dynamic>?;
        if (errObj != null) {
          errMsg = errObj['message']?.toString() ?? errMsg;
        }
      } catch (_) {}
      throw HttpException('[$model] $errMsg: $body', uri: url);
    }
  }
}
