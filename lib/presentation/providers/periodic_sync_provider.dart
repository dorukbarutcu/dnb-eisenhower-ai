import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_provider.dart';
import 'notification_listener_provider.dart';
import 'task_matrix_provider.dart';

class PeriodicSyncState {
  final bool isAutoSyncEnabled;
  final DateTime? lastSyncTime;
  final DateTime? nextSyncTime;
  final bool isSyncing;
  final String? syncStatus;

  const PeriodicSyncState({
    this.isAutoSyncEnabled = true,
    this.lastSyncTime,
    this.nextSyncTime,
    this.isSyncing = false,
    this.syncStatus,
  });

  PeriodicSyncState copyWith({
    bool? isAutoSyncEnabled,
    DateTime? lastSyncTime,
    DateTime? nextSyncTime,
    bool? isSyncing,
    String? syncStatus,
  }) {
    return PeriodicSyncState(
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      nextSyncTime: nextSyncTime ?? this.nextSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class PeriodicSyncNotifier extends Notifier<PeriodicSyncState> {
  static const String _boxName = 'app_settings';
  static const String _keyEnabled = 'auto_hourly_sync';
  static const String _keyLastSync = 'last_hourly_sync';

  Timer? _timer;

  @override
  PeriodicSyncState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    Future.microtask(_init);
    return const PeriodicSyncState();
  }

  Future<void> _init() async {
    final box = await Hive.openBox(_boxName);
    final enabled = box.get(_keyEnabled, defaultValue: true) as bool;
    final lastSyncMs = box.get(_keyLastSync, defaultValue: null) as int?;
    final lastSync = lastSyncMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs) : null;
    final nextSync = lastSync != null ? lastSync.add(const Duration(hours: 1)) : DateTime.now().add(const Duration(hours: 1));

    state = PeriodicSyncState(
      isAutoSyncEnabled: enabled,
      lastSyncTime: lastSync,
      nextSyncTime: nextSync,
    );

    if (enabled) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    // Check every hour (3600 seconds)
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      if (state.isAutoSyncEnabled) {
        triggerSync();
      }
    });
  }

  Future<void> toggleAutoSync(bool enabled) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_keyEnabled, enabled);

    if (enabled) {
      _startTimer();
      state = state.copyWith(
        isAutoSyncEnabled: true,
        nextSyncTime: DateTime.now().add(const Duration(hours: 1)),
      );
    } else {
      _timer?.cancel();
      state = state.copyWith(
        isAutoSyncEnabled: false,
        nextSyncTime: null,
      );
    }
  }

  Future<void> triggerSync() async {
    if (state.isSyncing) return;

    state = state.copyWith(
      isSyncing: true,
      syncStatus: 'Saatlik otomatik tarama yapılıyor (Gmail & Bildirimler)...',
    );

    try {
      // 1. Process pending notifications from native queue
      await ref.read(notificationListenerProvider.notifier).processPendingNotifications();

      // 2. Fetch unread emails if Google account is connected
      final authClient = await ref.read(googleAuthProvider.notifier).getAuthenticatedClient();
      if (authClient != null) {
        await ref.read(taskMatrixProvider.notifier).fetchAndProcessGmail();
      }

      final now = DateTime.now();
      final box = await Hive.openBox(_boxName);
      await box.put(_keyLastSync, now.millisecondsSinceEpoch);

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: now,
        nextSyncTime: now.add(const Duration(hours: 1)),
        syncStatus: 'Tarama tamamlandı.',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncStatus: 'Tarama hatası: $e',
      );
    }
  }
}

final periodicSyncProvider =
    NotifierProvider<PeriodicSyncNotifier, PeriodicSyncState>(PeriodicSyncNotifier.new);
