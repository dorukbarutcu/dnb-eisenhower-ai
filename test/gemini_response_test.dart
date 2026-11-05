import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:eisenhower_ai/data/models/gemini_response_model.dart';
import 'package:eisenhower_ai/domain/entities/task_source.dart';

void main() {
  group('Gemini Response Structured Contract Tests', () {
    test('Correctly parses contract JSON matching prompt spec', () {
      const rawJson = '''
{
  "summary": "Extracted 2 priority tasks from WhatsApp & Gmail",
  "processed_tasks": [
    {
      "task_id": "c1f72a50-936d-49f2-8418-2ad16a132bc2",
      "title": "Fix critical server payment gateway bug",
      "description": "WhatsApp alert from Devops team regarding Stripe 500 errors",
      "source": "WhatsApp",
      "quadrant": "Q1",
      "urgency_score": 9,
      "importance_score": 10,
      "reasoning": "Direct impact on company revenue and active customers",
      "calendar_event": {
        "should_add": true,
        "summary": "Fix critical server payment gateway bug",
        "description": "Investigate Stripe API failure logs",
        "start_iso": "2026-11-05T20:00:00",
        "end_iso": "2026-11-05T21:00:00",
        "color_id": "11 (Q1 Red)",
        "reminders_minutes_before": [15, 60]
      }
    },
    {
      "task_id": "b3e81a40-1234-4567-89ab-cdef01234567",
      "title": "Review Q4 product roadmap presentation",
      "description": "Email thread from Head of Product with roadmap deck",
      "source": "Gmail",
      "quadrant": "Q2",
      "urgency_score": 3,
      "importance_score": 8,
      "reasoning": "High strategic importance for company alignment, no immediate crisis deadline",
      "calendar_event": {
        "should_add": true,
        "summary": "Focus Block: Q4 Roadmap",
        "description": "Deep work review",
        "start_iso": "2026-11-06T09:00:00",
        "end_iso": "2026-11-06T10:30:00",
        "color_id": "9 (Q2 Blue)",
        "reminders_minutes_before": [30]
      }
    }
  ]
}
''';

      final Map<String, dynamic> decoded = jsonDecode(rawJson);
      final model = GeminiResponseModel.fromJson(decoded);

      expect(model.summary, 'Extracted 2 priority tasks from WhatsApp & Gmail');
      expect(model.processedTasks.length, 2);

      // Task 1: Q1
      final t1 = model.processedTasks[0];
      expect(t1.taskId, 'c1f72a50-936d-49f2-8418-2ad16a132bc2');
      expect(t1.source, TaskSource.whatsApp);
      expect(t1.quadrant, EisenhowerQuadrant.q1);
      expect(t1.urgencyScore, 9);
      expect(t1.importanceScore, 10);
      expect(t1.calendarEvent.shouldAdd, true);
      expect(t1.calendarEvent.colorId, '11');
      expect(t1.calendarEvent.remindersMinutesBefore, [15, 60]);

      // Task 2: Q2
      final t2 = model.processedTasks[1];
      expect(t2.taskId, 'b3e81a40-1234-4567-89ab-cdef01234567');
      expect(t2.source, TaskSource.gmail);
      expect(t2.quadrant, EisenhowerQuadrant.q2);
      expect(t2.urgencyScore, 3);
      expect(t2.importanceScore, 8);
      expect(t2.calendarEvent.colorId, '9');
      expect(t2.calendarEvent.remindersMinutesBefore, [30]);
    });
  });
}
