import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_source.dart';
import '../providers/calendar_provider.dart';
import '../providers/task_matrix_provider.dart';

class WeeklyScheduleScreen extends ConsumerWidget {
  const WeeklyScheduleScreen({super.key});

  Color _getQuadrantColor(EisenhowerQuadrant quadrant) {
    switch (quadrant) {
      case EisenhowerQuadrant.q1:
        return AppColors.q1Red;
      case EisenhowerQuadrant.q2:
        return AppColors.q2Blue;
      case EisenhowerQuadrant.q3:
        return AppColors.q3Yellow;
      case EisenhowerQuadrant.q4:
        return AppColors.q4Gray;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyCal = ref.watch(weeklyCalendarProvider);
    final matrixState = ref.watch(taskMatrixProvider);

    final weekStart = weeklyCal.selectedWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final headerStr = '${DateFormat('d MMM').format(weekStart)} - ${DateFormat('d MMM yyyy').format(weekEnd)}';

    // Group tasks that have scheduled calendar start dates in this week
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(weeklyCalendarProvider.notifier).fetchWeekEvents(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(weeklyCalendarProvider.notifier).changeWeek(-1),
                ),
                Text(
                  headerStr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref.read(weeklyCalendarProvider.notifier).changeWeek(1),
                ),
              ],
            ),
          ),
          if (weeklyCal.isLoading) const LinearProgressIndicator(minHeight: 2),

          // Days List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 7,
              itemBuilder: (ctx, index) {
                final day = days[index];
                final isToday = DateUtils.isSameDay(day, DateTime.now());

                // Find local tasks scheduled for this day
                final dayTasks = matrixState.tasks.where((t) {
                  final start = t.calendarEvent.start;
                  if (start == null) return false;
                  return DateUtils.isSameDay(start, day);
                }).toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.surface.withAlpha(240) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isToday ? AppColors.q2Blue : AppColors.surfaceLight.withAlpha(80),
                      width: isToday ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.q2Blue.withAlpha(30) : AppColors.surfaceLight.withAlpha(50),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM').format(day),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isToday ? AppColors.q2Blue : AppColors.textPrimary,
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.q2Blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Day Tasks
                      if (dayTasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'No scheduled tasks',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ...dayTasks.map((task) {
                          final color = _getQuadrantColor(task.quadrant);
                          final timeStr = task.calendarEvent.start != null
                              ? DateFormat('HH:mm').format(task.calendarEvent.start!.toLocal())
                              : '';

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              '${task.quadrant.code} • $timeStr • ${task.source.value}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            trailing: task.calendarEvent.googleCalendarEventId != null
                                ? const Tooltip(
                                    message: 'Synced with Google Calendar',
                                    child: Icon(Icons.cloud_done, size: 16, color: Colors.green),
                                  )
                                : null,
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
