import 'dart:async';
import 'package:flutter/services.dart';
import '../models/raw_notification_model.dart';

class NotificationStreamDatasource {
  static const MethodChannel _controlChannel =
      MethodChannel('com.eisenhower.ai/notifications_control');
  static const EventChannel _streamChannel =
      EventChannel('com.eisenhower.ai/notifications_stream');

  Future<bool> isNotificationAccessGranted() async {
    try {
      final bool? granted =
          await _controlChannel.invokeMethod<bool>('isNotificationAccessGranted');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _controlChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  Future<List<RawNotificationModel>> getPendingNotifications() async {
    try {
      final List<dynamic>? list =
          await _controlChannel.invokeMethod<List<dynamic>>('getPendingNotifications');
      if (list == null || list.isEmpty) return [];
      return list
          .whereType<Map>()
          .map((item) => RawNotificationModel.fromMap(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Stream<RawNotificationModel> get notificationStream {
    return _streamChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => RawNotificationModel.fromMap(event as Map));
  }
}
