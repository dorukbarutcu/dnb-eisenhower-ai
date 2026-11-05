import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_source.dart';
import '../providers/auth_provider.dart';
import '../providers/gemini_config_provider.dart';
import '../providers/notification_listener_provider.dart';
import '../providers/periodic_sync_provider.dart';
import '../providers/task_matrix_provider.dart';
import '../providers/updater_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/matrix_quadrant_card.dart';
import '../widgets/task_item_tile.dart';
import '../widgets/voice_input_sheet.dart';
import 'settings_screen.dart';
import 'weekly_schedule_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _is2x2Grid = true;
  int _selectedFilterIndex = 0; // 0: All, 1: Q1, 2: Q2, 3: Q3, 4: Q4

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.q2Blue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('DNB Eisenhower AI'),
          ],
        ),
        actions: [
          // View Switcher (2x2 Grid vs Odak Listesi)
          IconButton(
            tooltip: _is2x2Grid ? 'Liste Görünümüne Geç' : '2x2 Matris Görünümüne Geç',
            icon: Icon(
              _is2x2Grid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
              color: AppColors.q2Blue,
            ),
            onPressed: () {
              setState(() {
                _is2x2Grid = !_is2x2Grid;
              });
            },
          ),
          if (updaterState.hasUpdate)
            IconButton(
              tooltip: 'Yeni Güncelleme Mevcut (${updaterState.releaseInfo?.tagName})',
              icon: const Icon(Icons.system_update, color: Colors.amberAccent),
              onPressed: () => _showUpdateDialog(context, ref),
            ),
          IconButton(
            tooltip: 'Haftalık Çizelge & Analitik',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Ayarlar',
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
            // Status & Alert Banner if API key missing
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
                        'Gemini API anahtarı girilmedi. Ayarlar\'dan ekleyin.',
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
                      child: const Text('KURULUM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                      label: 'Bildirimler',
                      isActive: notifState.hasPermission,
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey,
                      icon: Icons.notifications,
                      onTap: () => ref.read(notificationListenerProvider.notifier).openSettings(),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      label: 'Google Hesabı',
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
                        tooltip: 'Okunmamış Gmail iletilerini tara',
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
                        matrixState.statusMessage ?? 'Yapay zeka işliyor...',
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

            // View Content (2x2 Grid vs Focused Spacious List)
            Expanded(
              child: _is2x2Grid
                  ? _build2x2MatrixGrid(matrixState)
                  : _buildFocusedListView(matrixState),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: AppColors.surfaceLight, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomActionButton(
                  icon: Icons.mic,
                  color: AppColors.voicePurple,
                  tooltip: 'Sesli Görev Ekle',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const VoiceInputSheet(),
                    );
                  },
                ),
                _buildBottomActionButton(
                  icon: Icons.add,
                  color: AppColors.q2Blue,
                  tooltip: 'Metin / Görev Yaz',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddTaskDialog(),
                    );
                  },
                ),
                _buildBottomActionButton(
                  icon: Icons.mail_outline_rounded,
                  color: authState.isAuthenticated ? AppColors.gmailRed : Colors.grey,
                  tooltip: 'Gmail Tara',
                  onTap: authState.isAuthenticated
                      ? () => ref.read(taskMatrixProvider.notifier).fetchAndProcessGmail()
                      : () => ref.read(googleAuthProvider.notifier).signIn(),
                ),
                _buildBottomActionButton(
                  icon: Icons.bar_chart_rounded,
                  color: Colors.tealAccent,
                  tooltip: 'Haftalık Çizelge & Analitik',
                  onTap: () {
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

  Widget _buildBottomActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(35),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(120), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      onPressed: onTap,
    );
  }

  Widget _build2x2MatrixGrid(TaskMatrixState matrixState) {
    return Padding(
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
    );
  }

  Widget _buildFocusedListView(TaskMatrixState matrixState) {
    final all = matrixState.tasks;
    final q1 = matrixState.q1Tasks;
    final q2 = matrixState.q2Tasks;
    final q3 = matrixState.q3Tasks;
    final q4 = matrixState.q4Tasks;

    List<TaskEntity> currentList;
    switch (_selectedFilterIndex) {
      case 1:
        currentList = q1;
        break;
      case 2:
        currentList = q2;
        break;
      case 3:
        currentList = q3;
        break;
      case 4:
        currentList = q4;
        break;
      default:
        currentList = all;
    }

    return Column(
      children: [
        // Horizontal Quadrant Filter Tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab(0, 'Tümü', all.length, AppColors.textPrimary),
                const SizedBox(width: 6),
                _buildFilterTab(1, 'Q1 İlk Yap', q1.length, AppColors.q1Red),
                const SizedBox(width: 6),
                _buildFilterTab(2, 'Q2 Planla', q2.length, AppColors.q2Blue),
                const SizedBox(width: 6),
                _buildFilterTab(3, 'Q3 Devret', q3.length, AppColors.q3Yellow),
                const SizedBox(width: 6),
                _buildFilterTab(4, 'Q4 Ele', q4.length, AppColors.q4Gray),
              ],
            ),
          ),
        ),

        // Full-Width Spacious Task List
        Expanded(
          child: currentList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: AppColors.textSecondary.withAlpha(80)),
                      const SizedBox(height: 8),
                      const Text(
                        'Bu sekmede henüz görev bulunmuyor.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: currentList.length,
                  itemBuilder: (ctx, index) {
                    final t = currentList[index];
                    return TaskItemTile(
                      task: t,
                      onToggle: () => ref.read(taskMatrixProvider.notifier).toggleTask(t.taskId),
                      onDelete: () => ref.read(taskMatrixProvider.notifier).deleteTask(t.taskId),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(int index, String label, int count, Color color) {
    final isSelected = _selectedFilterIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(35) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceLight.withAlpha(80),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
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
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.lightBlueAccent,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Tarayıcıdan İndir & Kur', style: TextStyle(fontSize: 12)),
                      onPressed: () => ref.read(updaterProvider.notifier).openReleaseInBrowser(),
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
