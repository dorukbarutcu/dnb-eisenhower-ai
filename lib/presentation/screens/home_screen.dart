import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_source.dart';
import '../providers/auth_provider.dart';
import '../providers/gemini_config_provider.dart';
import '../providers/notification_listener_provider.dart';
import '../providers/task_matrix_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/matrix_quadrant_card.dart';
import '../widgets/voice_input_sheet.dart';
import 'settings_screen.dart';
import 'weekly_schedule_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixState = ref.watch(taskMatrixProvider);
    final authState = ref.watch(googleAuthProvider);
    final notifState = ref.watch(notificationListenerProvider);
    final geminiConfig = ref.watch(geminiConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.q2Blue.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grid_view_rounded, color: AppColors.q2Blue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Eisenhower AI'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Weekly Schedule',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status & Alert Banner
            if (!geminiConfig.isValid)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Gemini API key is required for AI task classification.',
                        style: TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                      child: const Text('SETUP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Live Service Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildStatusChip(
                    label: 'Notifications',
                    isActive: notifState.hasPermission,
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                    icon: Icons.notifications,
                    onTap: () => ref.read(notificationListenerProvider.notifier).openSettings(),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    label: 'Google Account',
                    isActive: authState.isAuthenticated,
                    activeColor: AppColors.q2Blue,
                    inactiveColor: Colors.grey,
                    icon: Icons.account_circle,
                    onTap: () {
                      if (!authState.isAuthenticated) {
                        ref.read(googleAuthProvider.notifier).signIn();
                      }
                    },
                  ),
                  const Spacer(),
                  if (authState.isAuthenticated)
                    IconButton(
                      tooltip: 'Sync unread Gmail',
                      icon: const Icon(Icons.mark_email_unread_outlined, size: 20),
                      onPressed: matrixState.isProcessing
                          ? null
                          : () => ref.read(taskMatrixProvider.notifier).fetchAndProcessGmail(),
                    ),
                ],
              ),
            ),

            // Processing Indicator
            if (matrixState.isProcessing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.q2Blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        matrixState.statusMessage ?? 'Processing...',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

            // Error display
            if (matrixState.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withAlpha(100)),
                ),
                child: Text(
                  matrixState.errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),

            // Eisenhower 2x2 Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: MatrixQuadrantCard(
                              quadrant: EisenhowerQuadrant.q1,
                              tasks: matrixState.q1Tasks,
                              onToggleTask: (id) => ref.read(taskMatrixProvider.notifier).toggleTask(id),
                              onDeleteTask: (id) => ref.read(taskMatrixProvider.notifier).deleteTask(id),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MatrixQuadrantCard(
                              quadrant: EisenhowerQuadrant.q2,
                              tasks: matrixState.q2Tasks,
                              onToggleTask: (id) => ref.read(taskMatrixProvider.notifier).toggleTask(id),
                              onDeleteTask: (id) => ref.read(taskMatrixProvider.notifier).deleteTask(id),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: MatrixQuadrantCard(
                              quadrant: EisenhowerQuadrant.q3,
                              tasks: matrixState.q3Tasks,
                              onToggleTask: (id) => ref.read(taskMatrixProvider.notifier).toggleTask(id),
                              onDeleteTask: (id) => ref.read(taskMatrixProvider.notifier).deleteTask(id),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MatrixQuadrantCard(
                              quadrant: EisenhowerQuadrant.q4,
                              tasks: matrixState.q4Tasks,
                              onToggleTask: (id) => ref.read(taskMatrixProvider.notifier).toggleTask(id),
                              onDeleteTask: (id) => ref.read(taskMatrixProvider.notifier).deleteTask(id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Voice Input
                  IconButton(
                    tooltip: 'Voice Input',
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.voicePurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 22),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const VoiceInputSheet(),
                      );
                    },
                  ),
                  // Manual Text / Note Input
                  IconButton(
                    tooltip: 'Add / Paste Task',
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.q2Blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddTaskDialog(),
                      );
                    },
                  ),
                  // Fetch Gmail
                  IconButton(
                    tooltip: 'Fetch Gmail',
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: authState.isAuthenticated ? AppColors.gmailRed : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mail, color: Colors.white, size: 22),
                    ),
                    onPressed: authState.isAuthenticated
                        ? () => ref.read(taskMatrixProvider.notifier).fetchAndProcessGmail()
                        : () => ref.read(googleAuthProvider.notifier).signIn(),
                  ),
                  // Weekly Schedule
                  IconButton(
                    tooltip: 'Weekly Calendar',
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.date_range, color: Colors.white, size: 22),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final color = isActive ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
