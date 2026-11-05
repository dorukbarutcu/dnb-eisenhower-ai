class CalendarEventEntity {
  final bool shouldAdd;
  final String summary;
  final String description;
  final DateTime? start;
  final DateTime? end;
  final String colorId;
  final List<int> remindersMinutesBefore;
  final String? googleCalendarEventId;

  CalendarEventEntity({
    required this.shouldAdd,
    required this.summary,
    required this.description,
    this.start,
    this.end,
    required this.colorId,
    required this.remindersMinutesBefore,
    this.googleCalendarEventId,
  });

  CalendarEventEntity copyWith({
    bool? shouldAdd,
    String? summary,
    String? description,
    DateTime? start,
    DateTime? end,
    String? colorId,
    List<int>? remindersMinutesBefore,
    String? googleCalendarEventId,
  }) {
    return CalendarEventEntity(
      shouldAdd: shouldAdd ?? this.shouldAdd,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      colorId: colorId ?? this.colorId,
      remindersMinutesBefore: remindersMinutesBefore ?? this.remindersMinutesBefore,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
    );
  }
}
