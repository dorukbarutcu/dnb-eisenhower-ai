import '../../domain/entities/calendar_event_entity.dart';

class CalendarEventModel extends CalendarEventEntity {
  CalendarEventModel({
    required super.shouldAdd,
    required super.summary,
    required super.description,
    super.start,
    super.end,
    required super.colorId,
    required super.remindersMinutesBefore,
    super.googleCalendarEventId,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    final rawColor = json['color_id']?.toString() ?? '9';
    final cleanColor = rawColor.split(' ').first.trim();

    DateTime? startDt;
    if (json['start_iso'] != null) {
      try {
        startDt = DateTime.parse(json['start_iso'].toString());
      } catch (_) {}
    }

    DateTime? endDt;
    if (json['end_iso'] != null) {
      try {
        endDt = DateTime.parse(json['end_iso'].toString());
      } catch (_) {}
    }

    final remindersRaw = json['reminders_minutes_before'];
    List<int> reminders = [];
    if (remindersRaw is List) {
      reminders = remindersRaw.map((e) => int.tryParse(e.toString()) ?? 15).toList();
    } else {
      reminders = [15, 60];
    }

    return CalendarEventModel(
      shouldAdd: json['should_add'] == true,
      summary: json['summary']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      start: startDt,
      end: endDt,
      colorId: cleanColor,
      remindersMinutesBefore: reminders,
      googleCalendarEventId: json['google_calendar_event_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'should_add': shouldAdd,
      'summary': summary,
      'description': description,
      'start_iso': start?.toIso8601String(),
      'end_iso': end?.toIso8601String(),
      'color_id': colorId,
      'reminders_minutes_before': remindersMinutesBefore,
      'google_calendar_event_id': googleCalendarEventId,
    };
  }

  factory CalendarEventModel.fromEntity(CalendarEventEntity entity) {
    return CalendarEventModel(
      shouldAdd: entity.shouldAdd,
      summary: entity.summary,
      description: entity.description,
      start: entity.start,
      end: entity.end,
      colorId: entity.colorId,
      remindersMinutesBefore: entity.remindersMinutesBefore,
      googleCalendarEventId: entity.googleCalendarEventId,
    );
  }
}
