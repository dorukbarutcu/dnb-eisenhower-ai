import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import '../../data/datasources/calendar_remote_datasource.dart';
import 'auth_provider.dart';

class WeeklyCalendarState {
  final List<calendar.Event> events;
  final bool isLoading;
  final DateTime selectedWeekStart;
  final String? errorMessage;

  const WeeklyCalendarState({
    this.events = const [],
    this.isLoading = false,
    required this.selectedWeekStart,
    this.errorMessage,
  });

  WeeklyCalendarState copyWith({
    List<calendar.Event>? events,
    bool? isLoading,
    DateTime? selectedWeekStart,
    String? errorMessage,
  }) {
    return WeeklyCalendarState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      selectedWeekStart: selectedWeekStart ?? this.selectedWeekStart,
      errorMessage: errorMessage,
    );
  }
}

class WeeklyCalendarNotifier extends Notifier<WeeklyCalendarState> {
  static DateTime _getStartOfWeek(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: dt.weekday - 1));
  }

  @override
  WeeklyCalendarState build() {
    final start = _getStartOfWeek(DateTime.now());
    Future.microtask(fetchWeekEvents);
    return WeeklyCalendarState(selectedWeekStart: start);
  }

  void changeWeek(int weekDelta) {
    final nextStart = state.selectedWeekStart.add(Duration(days: weekDelta * 7));
    state = state.copyWith(selectedWeekStart: nextStart);
    fetchWeekEvents();
  }

  Future<void> fetchWeekEvents() async {
    final authClient = await ref.read(googleAuthProvider.notifier).getAuthenticatedClient();
    if (authClient == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final datasource = CalendarRemoteDatasource(authClient);
      final weekStart = state.selectedWeekStart;
      final weekEnd = weekStart.add(const Duration(days: 7));

      final items = await datasource.getEventsForRange(
        startTime: weekStart,
        endTime: weekEnd,
      );

      state = state.copyWith(events: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final weeklyCalendarProvider =
    NotifierProvider<WeeklyCalendarNotifier, WeeklyCalendarState>(WeeklyCalendarNotifier.new);
