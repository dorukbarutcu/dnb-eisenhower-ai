import '../../domain/entities/task_source.dart';

class RawNotificationModel {
  final TaskSource source;
  final String packageName;
  final String title;
  final String text;
  final int postTime;

  RawNotificationModel({
    required this.source,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
  });

  factory RawNotificationModel.fromMap(Map<dynamic, dynamic> map) {
    final srcStr = map['source']?.toString() ?? 'WhatsApp';
    return RawNotificationModel(
      source: srcStr.toLowerCase().contains('telegram')
          ? TaskSource.telegram
          : TaskSource.whatsApp,
      packageName: map['packageName']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      postTime: (map['postTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
