import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_source.dart';
import '../providers/auth_provider.dart';
import '../providers/gemini_config_provider.dart';
import '../providers/notification_listener_provider.dart';
import '../providers/periodic_sync_provider.dart';
import '../providers/task_matrix_provider.dart';
import '../providers/updater_provider.dart';
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
    final syncState = ref.watch(periodicSyncProvider);
    final updaterState = ref.watch(updaterProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            const Text('DNB Eisenhower AI'),
          ],
        ),
        actions: [
          if (updaterState.hasUpdate)
            IconButton(
              tooltip: 'Yeni Güncelleme Mevcut (${updaterState.releaseInfo?.tagName})',
              icon: const Icon(Icons.system_update, color: Colors.amberAccent),
              onPressed: () => _showUpdateDialog(context, ref),
            ),
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
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Gemini API key is required for AI task classification.',
                        style: TextStyle(fontSize: 11, color: Colors.amber),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      label: syncState.isSyncing
                          ? 'Taranıyor...'
                          : (syncState.isAutoSyncEnabled ? '1s Oto-Tarama' : 'Oto-Tarama Kapalı'),
                      isActive: syncState.isAutoSyncEnabled,
                      activeColor: Colors.tealAccent,
                      inactiveColor: Colors.grey,
                      icon: syncState.isSyncing ? Icons.sync : Icons.auto_mode,
                      onTap: () => ref.read(periodicSyncProvider.notifier).triggerSync(),
                    ),
                    if (authState.isAuthenticated) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Sync unread Gmail',
                        icon: const Icon(Icons.mark_email_unread_outlined, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: matrixState.isProcessing
                            ? null
                            : () => ref.read(taskMatrixProvider.notifier).fetchAndProcessGmail(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Processing Indicator
            if (matrixState.isProcessing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.q2Blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        matrixState.statusMessage ?? 'Processing...',
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

            // Error display
            if (matrixState.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withAlpha(100)),
                ),
                child: Text(
                  matrixState.errorMessage!,
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                ),
              ),

            // Eisenhower 2x2 Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          const SizedBox(width: 8),
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
                    const SizedBox(height: 8),
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
                          const SizedBox(width: 8),
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
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Voice Input',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.voicePurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 20),
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
                IconButton(
                  tooltip: 'Add / Paste Task',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.q2Blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddTaskDialog(),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Fetch Gmail',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: authState.isAuthenticated ? AppColors.gmailRed : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mail, color: Colors.white, size: 20),
                  ),
                  onPressed: authState.isAuthenticated
                      ? () => ref.read(taskMatrixProvider.notifier).fetchAndProcessGmail()
                      : () => ref.read(googleAuthProvider.notifier).signIn(),
                ),
                IconButton(
                  tooltip: 'Weekly Calendar',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.date_range, color: Colors.white, size: 20),
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

  void _showUpdateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final state = ref.watch(updaterProvider);
            final info = state.releaseInfo;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.system_update, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  Text('Yeni Sürüm: ${info?.tagName ?? ""}'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info?.releaseNotes.isNotEmpty == true
                        ? info!.releaseNotes
                        : 'GitHub üzerinde yeni bir kararlı sürüm yayınlandı.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (state.isDownloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: state.downloadProgress > 0 ? state.downloadProgress : null,
                      color: Colors.amberAccent,
                      backgroundColor: AppColors.surfaceLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İndiriliyor: %${(state.downloadProgress * 100).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
                    ),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(state.isDownloading ? 'İndiriliyor...' : 'İndir & Güncelle'),
                  onPressed: state.isDownloading
                      ? null
                      : () => ref.read(updaterProvider.notifier).downloadAndInstall(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
