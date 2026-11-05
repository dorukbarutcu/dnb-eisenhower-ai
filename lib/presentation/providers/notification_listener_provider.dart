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
  StreamSubscription<RawNotificationModel>? _sub;

  @override
  NotificationListenerState build() {
    ref.onDispose(() {
      _sub?.cancel();
    });
    Future.microtask(checkPermission);
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

  void startListening() {
    _sub?.cancel();
    _sub = _datasource.notificationStream.listen((notification) {
      final updatedList = [notification, ...state.recentNotifications];
      if (updatedList.length > 50) updatedList.removeLast();

      state = state.copyWith(
        recentNotifications: updatedList,
        isListening: true,
      );

      // Trigger automatic classification and scheduling
      ref.read(taskMatrixProvider.notifier).processNotification(notification);
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
