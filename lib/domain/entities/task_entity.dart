import 'calendar_event_entity.dart';
import 'task_source.dart';

class TaskEntity {
  final String taskId;
  final String title;
  final String description;
  final TaskSource source;
  final EisenhowerQuadrant quadrant;
  final int urgencyScore;
  final int importanceScore;
  final String reasoning;
  final CalendarEventEntity calendarEvent;
  final bool isCompleted;
  final DateTime createdAt;

  TaskEntity({
    required this.taskId,
    required this.title,
    required this.description,
    required this.source,
    required this.quadrant,
    required this.urgencyScore,
    required this.importanceScore,
    required this.reasoning,
    required this.calendarEvent,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskEntity copyWith({
    String? taskId,
    String? title,
    String? description,
    TaskSource? source,
    EisenhowerQuadrant? quadrant,
    int? urgencyScore,
    int? importanceScore,
    String? reasoning,
    CalendarEventEntity? calendarEvent,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskEntity(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      source: source ?? this.source,
      quadrant: quadrant ?? this.quadrant,
      urgencyScore: urgencyScore ?? this.urgencyScore,
      importanceScore: importanceScore ?? this.importanceScore,
      reasoning: reasoning ?? this.reasoning,
      calendarEvent: calendarEvent ?? this.calendarEvent,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
