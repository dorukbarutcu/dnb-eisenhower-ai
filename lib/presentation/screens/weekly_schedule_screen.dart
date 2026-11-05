import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_source.dart';
import '../providers/calendar_provider.dart';
import '../providers/task_matrix_provider.dart';

class WeeklyScheduleScreen extends ConsumerStatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  ConsumerState<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends ConsumerState<WeeklyScheduleScreen> {
  int _selectedDayIndex = -1; // -1 means all days

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
  Widget build(BuildContext context) {
    final weeklyCal = ref.watch(weeklyCalendarProvider);
    final matrixState = ref.watch(taskMatrixProvider);

    final weekStart = weeklyCal.selectedWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final headerStr = '${DateFormat('d MMM').format(weekStart)} - ${DateFormat('d MMM yyyy').format(weekEnd)}';

    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    // Calculate all tasks for this week
    final weekTasks = matrixState.tasks.where((t) {
      final start = t.calendarEvent.start;
      if (start == null) return false;
      return !start.isBefore(weekStart) && start.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    final q1Count = weekTasks.where((t) => t.quadrant == EisenhowerQuadrant.q1).length;
    final q2Count = weekTasks.where((t) => t.quadrant == EisenhowerQuadrant.q2).length;
    final q3Count = weekTasks.where((t) => t.quadrant == EisenhowerQuadrant.q3).length;
    final q4Count = weekTasks.where((t) => t.quadrant == EisenhowerQuadrant.q4).length;
    final totalTasks = weekTasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Çizelge & Analitik'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(weeklyCalendarProvider.notifier).fetchWeekEvents(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Switcher Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(weeklyCalendarProvider.notifier).changeWeek(-1),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: AppColors.q2Blue),
                    const SizedBox(width: 8),
                    Text(
                      headerStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref.read(weeklyCalendarProvider.notifier).changeWeek(1),
                ),
              ],
            ),
          ),
          if (weeklyCal.isLoading) const LinearProgressIndicator(minHeight: 2),

          // Scrollable Analytics & Schedule Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                // 1. Eisenhower Matrix Balance Card
                _buildMatrixBalanceCard(
                  total: totalTasks,
                  q1: q1Count,
                  q2: q2Count,
                  q3: q3Count,
                  q4: q4Count,
                ),
                const SizedBox(height: 14),

                // 2. 7-Day Workload Bar Chart
                _build7DayChart(
                  days: days,
                  tasks: matrixState.tasks,
                  selectedIndex: _selectedDayIndex,
                  onSelectDay: (idx) {
                    setState(() {
                      _selectedDayIndex = _selectedDayIndex == idx ? -1 : idx;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Section Title with Filter Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDayIndex == -1
                          ? 'Tüm Hafta Programı'
                          : '${DateFormat('EEEE, d MMMM').format(days[_selectedDayIndex])} Programı',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (_selectedDayIndex != -1)
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text('Tümünü Göster', style: TextStyle(fontSize: 11)),
                        onPressed: () => setState(() => _selectedDayIndex = -1),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Days or Selected Day Task List
                if (_selectedDayIndex != -1)
                  _buildDayScheduleCard(
                    day: days[_selectedDayIndex],
                    allTasks: matrixState.tasks,
                    isToday: DateUtils.isSameDay(days[_selectedDayIndex], DateTime.now()),
                  )
                else
                  ...days.map((day) {
                    final isToday = DateUtils.isSameDay(day, DateTime.now());
                    return _buildDayScheduleCard(
                      day: day,
                      allTasks: matrixState.tasks,
                      isToday: isToday,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixBalanceCard({
    required int total,
    required int q1,
    required int q2,
    required int q3,
    required int q4,
  }) {
    final q1Pct = total > 0 ? (q1 / total) : 0.0;
    final q2Pct = total > 0 ? (q2 / total) : 0.0;
    final q3Pct = total > 0 ? (q3 / total) : 0.0;
    final q4Pct = total > 0 ? (q4 / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.q2Blue),
                  SizedBox(width: 8),
                  Text(
                    'Eisenhower Haftalık Denge Dağılımı',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total Planlı Görev',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Multi-segmented Distribution Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? Container(color: AppColors.surfaceLight.withAlpha(80))
                  : Row(
                      children: [
                        if (q1 > 0) Expanded(flex: (q1Pct * 100).toInt(), child: Container(color: AppColors.q1Red)),
                        if (q2 > 0) Expanded(flex: (q2Pct * 100).toInt(), child: Container(color: AppColors.q2Blue)),
                        if (q3 > 0) Expanded(flex: (q3Pct * 100).toInt(), child: Container(color: AppColors.q3Yellow)),
                        if (q4 > 0) Expanded(flex: (q4Pct * 100).toInt(), child: Container(color: AppColors.q4Gray)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Quadrant Breakdown Pills
          Row(
            children: [
              _buildQuadrantStatPill(
                label: 'Q1 Yap',
                count: q1,
                pct: (q1Pct * 100).toStringAsFixed(0),
                color: AppColors.q1Red,
              ),
              const SizedBox(width: 6),
              _buildQuadrantStatPill(
                label: 'Q2 Planla',
                count: q2,
                pct: (q2Pct * 100).toStringAsFixed(0),
                color: AppColors.q2Blue,
              ),
              const SizedBox(width: 6),
              _buildQuadrantStatPill(
                label: 'Q3 Devret',
                count: q3,
                pct: (q3Pct * 100).toStringAsFixed(0),
                color: AppColors.q3Yellow,
              ),
              const SizedBox(width: 6),
              _buildQuadrantStatPill(
                label: 'Q4 Ele',
                count: q4,
                pct: (q4Pct * 100).toStringAsFixed(0),
                color: AppColors.q4Gray,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrantStatPill({
    required String label,
    required int count,
    required String pct,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              '$count (%$pct)',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build7DayChart({
    required List<DateTime> days,
    required List<TaskEntity> tasks,
    required int selectedIndex,
    required Function(int) onSelectDay,
  }) {
    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    // Find max tasks in any single day to normalize bar heights
    int maxDayTasks = 1;
    final List<int> dayCounts = [];

    for (final day in days) {
      final count = tasks.where((t) {
        final start = t.calendarEvent.start;
        if (start == null) return false;
        return DateUtils.isSameDay(start, day);
      }).length;
      dayCounts.add(count);
      if (count > maxDayTasks) maxDayTasks = count;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 18, color: Colors.tealAccent),
                  SizedBox(width: 8),
                  Text(
                    'Haftalık Günlük Yoğunluk Grafiği',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Text(
                'Güne dokunarak filtreleyin',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7-Day Bars Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final count = dayCounts[i];
              final isToday = DateUtils.isSameDay(days[i], DateTime.now());
              final isSelected = selectedIndex == i;
              final dayTasks = tasks.where((t) {
                final start = t.calendarEvent.start;
                if (start == null) return false;
                return DateUtils.isSameDay(start, days[i]);
              }).toList();

              final q1InDay = dayTasks.where((t) => t.quadrant == EisenhowerQuadrant.q1).length;
              final q2InDay = dayTasks.where((t) => t.quadrant == EisenhowerQuadrant.q2).length;
              final q3InDay = dayTasks.where((t) => t.quadrant == EisenhowerQuadrant.q3).length;
              final q4InDay = dayTasks.where((t) => t.quadrant == EisenhowerQuadrant.q4).length;

              // Compute normalized bar height (min 10px, max 80px)
              final barHeight = count == 0 ? 8.0 : (count / maxDayTasks) * 72.0 + 12.0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelectDay(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Task count badge
                        Text(
                          count > 0 ? '$count' : '',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.tealAccent : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Segmented Bar
                        Container(
                          height: barHeight,
                          width: isSelected ? 22 : 18,
                          decoration: BoxDecoration(
                            color: count == 0 ? AppColors.surfaceLight.withAlpha(50) : null,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.tealAccent
                                  : (isToday ? AppColors.q2Blue : Colors.transparent),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: count == 0
                                ? Container(color: AppColors.surfaceLight.withAlpha(60))
                                : Column(
                                    children: [
                                      if (q1InDay > 0)
                                        Expanded(flex: q1InDay, child: Container(color: AppColors.q1Red)),
                                      if (q2InDay > 0)
                                        Expanded(flex: q2InDay, child: Container(color: AppColors.q2Blue)),
                                      if (q3InDay > 0)
                                        Expanded(flex: q3InDay, child: Container(color: AppColors.q3Yellow)),
                                      if (q4InDay > 0)
                                        Expanded(flex: q4InDay, child: Container(color: AppColors.q4Gray)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Day Name
                        Text(
                          dayNames[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.tealAccent
                                : (isToday ? AppColors.q2Blue : AppColors.textSecondary),
                          ),
                        ),
                        // Day Number
                        Text(
                          DateFormat('d').format(days[i]),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.tealAccent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayScheduleCard({
    required DateTime day,
    required List<TaskEntity> allTasks,
    required bool isToday,
  }) {
    final dayTasks = allTasks.where((t) {
      final start = t.calendarEvent.start;
      if (start == null) return false;
      return DateUtils.isSameDay(start, day);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? AppColors.q2Blue : AppColors.surfaceLight.withAlpha(90),
          width: isToday ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isToday ? AppColors.q2Blue.withAlpha(30) : AppColors.surfaceLight.withAlpha(50),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(day),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isToday ? AppColors.q2Blue : AppColors.textPrimary,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.q2Blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BUGÜN',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${dayTasks.length} Görev',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Day Task Items
          if (dayTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Center(
                child: Text(
                  'Bu gün için planlanmış etkinlik yok.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: dayTasks.map((task) {
                  final color = _getQuadrantColor(task.quadrant);
                  final timeStr = task.calendarEvent.start != null
                      ? DateFormat('HH:mm').format(task.calendarEvent.start!.toLocal())
                      : '';
                  final isSynced = task.calendarEvent.googleCalendarEventId != null;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withAlpha(140),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: color, width: 3.5)),
                    ),
                    child: Row(
                      children: [
                        // Time Pill
                        if (timeStr.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              timeStr,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Title & details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${task.quadrant.code} • ${task.source.value}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                  if (isSynced) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.cloud_done, size: 12, color: Colors.green),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
