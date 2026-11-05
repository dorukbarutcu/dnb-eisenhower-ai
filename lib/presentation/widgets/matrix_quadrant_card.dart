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
        return 'Acil & Önemli';
      case EisenhowerQuadrant.q2:
        return 'Önemli & Acil Değil';
      case EisenhowerQuadrant.q3:
        return 'Acil & Önemsiz';
      case EisenhowerQuadrant.q4:
        return 'Acil Değil & Önemsiz';
    }
  }

  String _getShortTitle() {
    switch (quadrant) {
      case EisenhowerQuadrant.q1:
        return 'İlk Sen Yap';
      case EisenhowerQuadrant.q2:
        return 'Planla';
      case EisenhowerQuadrant.q3:
        return 'Devret';
      case EisenhowerQuadrant.q4:
        return 'Ele / Sil';
    }
  }

  IconData _getSourceIcon(TaskSource source) {
    switch (source) {
      case TaskSource.whatsApp:
      case TaskSource.telegram:
        return Icons.chat_bubble_outline;
      case TaskSource.sms:
        return Icons.sms_outlined;
      case TaskSource.gmail:
        return Icons.email_outlined;
      case TaskSource.voiceInput:
        return Icons.mic_none;
      case TaskSource.manualText:
        return Icons.edit_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getQuadrantColor();
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();

    return InkWell(
      onTap: () => _showQuadrantDetailSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(90), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quadrant.code,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getShortTitle(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tasks.length - completedCount}/${tasks.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                _getSubtitle(),
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Compact Task Rows (Clean, un-cramped display)
            Expanded(
              child: activeTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: completedCount > 0 ? Colors.green.withAlpha(120) : AppColors.textSecondary.withAlpha(80),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            completedCount > 0 ? '$completedCount tamamlandı' : 'Görev yok',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      itemCount: activeTasks.length > 3 ? 3 : activeTasks.length,
                      itemBuilder: (ctx, index) {
                        final t = activeTasks[index];
                        return InkWell(
                          onTap: () => onToggleTask(t.taskId),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.background.withAlpha(120),
                              borderRadius: BorderRadius.circular(6),
                              border: Border(left: BorderSide(color: color, width: 2.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(_getSourceIcon(t.source), size: 10, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Card Footer Indicator
            if (activeTasks.length > 3)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '+${activeTasks.length - 3} daha (Detaylar için dokun)',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuadrantDetailSheet(BuildContext context) {
    final color = _getQuadrantColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          quadrant.code,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quadrant.label,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _getSubtitle(),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'Bu kadranda görev bulunmuyor.',
                            style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
            );
          },
        );
      },
    );
  }
}
