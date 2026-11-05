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

  Stream<RawNotificationModel> get notificationStream {
    return _streamChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => RawNotificationModel.fromMap(event as Map));
  }
}
