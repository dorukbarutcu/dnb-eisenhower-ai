import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import '../models/calendar_event_model.dart';

class CalendarRemoteDatasource {
  final auth.AuthClient authClient;
  late final calendar.CalendarApi _calendarApi;

  CalendarRemoteDatasource(this.authClient) {
    _calendarApi = calendar.CalendarApi(authClient);
  }

  Future<String?> createEvent(CalendarEventModel eventSpec) async {
    final start = eventSpec.start ?? DateTime.now().add(const Duration(hours: 1));
    final end = eventSpec.end ?? start.add(const Duration(minutes: 45));

    final remindersList = eventSpec.remindersMinutesBefore.map((min) {
      return calendar.EventReminder(method: 'popup', minutes: min);
    }).toList();

    final event = calendar.Event(
      summary: eventSpec.summary,
      description: eventSpec.description,
      start: calendar.EventDateTime(
        dateTime: start.toUtc(),
        timeZone: 'UTC',
      ),
      end: calendar.EventDateTime(
        dateTime: end.toUtc(),
        timeZone: 'UTC',
      ),
      colorId: eventSpec.colorId,
      reminders: remindersList.isNotEmpty
          ? calendar.EventReminders(
              useDefault: false,
              overrides: remindersList,
            )
          : calendar.EventReminders(useDefault: true),
    );

    final inserted = await _calendarApi.events.insert(event, 'primary');
    return inserted.id;
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _calendarApi.events.delete('primary', eventId);
    } catch (_) {}
  }

  Future<List<calendar.Event>> getEventsForRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final result = await _calendarApi.events.list(
      'primary',
      timeMin: startTime.toUtc(),
      timeMax: endTime.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );
    return result.items ?? [];
  }
}
