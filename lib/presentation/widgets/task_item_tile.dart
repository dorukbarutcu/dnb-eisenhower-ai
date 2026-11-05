import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_source.dart';

class TaskItemTile extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskItemTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  Color _getSourceColor(TaskSource source) {
    switch (source) {
      case TaskSource.whatsApp:
        return AppColors.whatsAppGreen;
      case TaskSource.telegram:
        return AppColors.telegramBlue;
      case TaskSource.gmail:
        return AppColors.gmailRed;
      case TaskSource.voiceInput:
        return AppColors.voicePurple;
      case TaskSource.manualText:
        return AppColors.manualIndigo;
    }
  }

  IconData _getSourceIcon(TaskSource source) {
    switch (source) {
      case TaskSource.whatsApp:
      case TaskSource.telegram:
        return Icons.chat_bubble_outline;
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
    final cal = task.calendarEvent;
    final dateStr = cal.start != null ? DateFormat('E, d MMM HH:mm').format(cal.start!.toLocal()) : null;

    return Dismissible(
      key: Key(task.taskId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withAlpha(200),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted ? Colors.transparent : AppColors.surfaceLight.withAlpha(120),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTaskDetails(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.q2Blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getSourceColor(task.source).withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getSourceIcon(task.source), size: 11, color: _getSourceColor(task.source)),
                                const SizedBox(width: 4),
                                Text(
                                  task.source.value,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _getSourceColor(task.source),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'U:${task.urgencyScore} / I:${task.importanceScore}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ),
                          if (cal.shouldAdd && dateStr != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.q2Blue.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today, size: 10, color: AppColors.q2Blue),
                                  const SizedBox(width: 3),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 10, color: AppColors.q2Blue),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                  onPressed: () => _showTaskDetails(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDelete();
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.surfaceLight),
              const SizedBox(height: 8),
              if (task.description.isNotEmpty) ...[
                const Text('Description', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(task.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
              ],
              const Text('AI Reasoning', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(task.reasoning.isEmpty ? 'No reasoning provided.' : task.reasoning,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              if (task.calendarEvent.shouldAdd) ...[
                const Text('Google Calendar Event',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'Event: ${task.calendarEvent.summary}\nTime: ${task.calendarEvent.start?.toLocal() ?? "Unspecified"}\nSynced: ${task.calendarEvent.googleCalendarEventId != null ? "Yes (Google ID: ${task.calendarEvent.googleCalendarEventId})" : "Pending"}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
