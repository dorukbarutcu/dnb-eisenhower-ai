import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/notification_stream_datasource.dart';
import '../../data/models/raw_notification_model.dart';
import 'task_matrix_provider.dart';

class NotificationListenerState {
  final bool hasPermission;
  final bool isListening;
  final List<RawNotificationModel> recentNotifications;

  const NotificationListenerState({
    this.hasPermission = false,
    this.isListening = false,
    this.recentNotifications = const [],
  });

  NotificationListenerState copyWith({
    bool? hasPermission,
    bool? isListening,
    List<RawNotificationModel>? recentNotifications,
  }) {
    return NotificationListenerState(
      hasPermission: hasPermission ?? this.hasPermission,
      isListening: isListening ?? this.isListening,
      recentNotifications: recentNotifications ?? this.recentNotifications,
    );
  }
}

class NotificationListenerNotifier extends Notifier<NotificationListenerState> {
  final NotificationStreamDatasource _datasource = NotificationStreamDatasource();
  final Set<String> _processedKeys = {};
  StreamSubscription<RawNotificationModel>? _sub;

  @override
  NotificationListenerState build() {
    ref.onDispose(() {
      _sub?.cancel();
    });
    Future.microtask(() async {
      await checkPermission();
      await processPendingNotifications();
    });
    return const NotificationListenerState();
  }

  Future<void> checkPermission() async {
    final granted = await _datasource.isNotificationAccessGranted();
    state = state.copyWith(hasPermission: granted);
    if (granted && !state.isListening) {
      startListening();
    }
  }

  Future<void> openSettings() async {
    await _datasource.openNotificationSettings();
  }

  Future<void> processPendingNotifications() async {
    final pending = await _datasource.getPendingNotifications();
    for (final notif in pending) {
      if (!_isDuplicateOrNoise(notif)) {
        ref.read(taskMatrixProvider.notifier).processNotification(notif);
      }
    }
  }

  bool _isDuplicateOrNoise(RawNotificationModel notification) {
    final title = notification.title.trim();
    final text = notification.text.trim();
    if (text.isEmpty && title.isEmpty) return true;

    // Filter trivial notification banners
    final lower = text.toLowerCase();
    if (lower.contains('new messages') ||
        lower.contains('yeni mesaj') ||
        lower.contains('checking for new messages') ||
        lower == 'ok' ||
        lower == 'tamam' ||
        lower == '👍') {
      return true;
    }

    final key = '${notification.source.value}:$title:$text';
    if (_processedKeys.contains(key)) {
      return true;
    }
    _processedKeys.add(key);
    if (_processedKeys.length > 200) {
      _processedKeys.remove(_processedKeys.first);
    }
    return false;
  }

  void startListening() {
    _sub?.cancel();
    _sub = _datasource.notificationStream.listen((notification) {
      final updatedList = [notification, ...state.recentNotifications];
      if (updatedList.length > 50) updatedList.removeLast();

      state = state.copyWith(
        recentNotifications: updatedList,
        isListening: true,
      );

      // Trigger automatic classification and scheduling if not noise/duplicate
      if (!_isDuplicateOrNoise(notification)) {
        ref.read(taskMatrixProvider.notifier).processNotification(notification);
      } else {
        // Still keep in recent notifications list without running Gemini
      }
    });
    state = state.copyWith(isListening: true);
  }

  void stopListening() {
    _sub?.cancel();
    state = state.copyWith(isListening: false);
  }
}

final notificationListenerProvider = NotifierProvider<
    NotificationListenerNotifier, NotificationListenerState>(
  NotificationListenerNotifier.new,
);
