import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_source.dart';
import 'task_item_tile.dart';

class MatrixQuadrantCard extends StatelessWidget {
  final EisenhowerQuadrant quadrant;
  final List<TaskEntity> tasks;
  final Function(String taskId) onToggleTask;
  final Function(String taskId) onDeleteTask;

  const MatrixQuadrantCard({
    super.key,
    required this.quadrant,
    required this.tasks,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  Color _getQuadrantColor() {
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

  String _getSubtitle() {
    switch (quadrant) {
      case EisenhowerQuadrant.q1:
        return 'Urgent & Important';
      case EisenhowerQuadrant.q2:
        return 'Important & Not Urgent';
      case EisenhowerQuadrant.q3:
        return 'Urgent & Not Important';
      case EisenhowerQuadrant.q4:
        return 'Not Urgent & Not Important';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getQuadrantColor();
    final completedCount = tasks.where((t) => t.isCompleted).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(70), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              quadrant.code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              quadrant.label.split('(').first.trim(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitle(),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length - completedCount}/${tasks.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Task List Body
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks in ${quadrant.code}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: tasks.length,
                    itemBuilder: (ctx, index) {
                      final t = tasks[index];
                      return TaskItemTile(
                        task: t,
                        onToggle: () => onToggleTask(t.taskId),
                        onDelete: () => onDeleteTask(t.taskId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
