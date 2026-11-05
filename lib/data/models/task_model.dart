import 'package:uuid/uuid.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_source.dart';
import 'calendar_event_model.dart';

class TaskModel extends TaskEntity {
  TaskModel({
    required super.taskId,
    required super.title,
    required super.description,
    required super.source,
    required super.quadrant,
    required super.urgencyScore,
    required super.importanceScore,
    required super.reasoning,
    required super.calendarEvent,
    super.isCompleted = false,
    super.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawTaskId = json['task_id']?.toString();
    final taskId = (rawTaskId == null || rawTaskId.isEmpty)
        ? const Uuid().v4()
        : rawTaskId;

    final calendarJson = json['calendar_event'];
    final calendarEvent = calendarJson is Map<String, dynamic>
        ? CalendarEventModel.fromJson(calendarJson)
        : CalendarEventModel(
            shouldAdd: false,
            summary: json['title']?.toString() ?? '',
            description: json['description']?.toString() ?? '',
            colorId: '9',
            remindersMinutesBefore: [15, 60],
          );

    return TaskModel(
      taskId: taskId,
      title: json['title']?.toString() ?? 'Untitled Task',
      description: json['description']?.toString() ?? '',
      source: TaskSource.fromString(json['source']?.toString() ?? 'Manual_Text'),
      quadrant: EisenhowerQuadrant.fromCode(json['quadrant']?.toString() ?? 'Q2'),
      urgencyScore: int.tryParse(json['urgency_score']?.toString() ?? '1') ?? 1,
      importanceScore: int.tryParse(json['importance_score']?.toString() ?? '1') ?? 1,
      reasoning: json['reasoning']?.toString() ?? '',
      calendarEvent: calendarEvent,
      isCompleted: json['is_completed'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'title': title,
      'description': description,
      'source': source.value,
      'quadrant': quadrant.code,
      'urgency_score': urgencyScore,
      'importance_score': importanceScore,
      'reasoning': reasoning,
      'calendar_event': CalendarEventModel.fromEntity(calendarEvent).toJson(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      taskId: entity.taskId,
      title: entity.title,
      description: entity.description,
      source: entity.source,
      quadrant: entity.quadrant,
      urgencyScore: entity.urgencyScore,
      importanceScore: entity.importanceScore,
      reasoning: entity.reasoning,
      calendarEvent: entity.calendarEvent,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
    );
  }
}
