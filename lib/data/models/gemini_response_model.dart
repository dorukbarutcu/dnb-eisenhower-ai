import 'task_model.dart';

class GeminiResponseModel {
  final String summary;
  final List<TaskModel> processedTasks;

  GeminiResponseModel({
    required this.summary,
    required this.processedTasks,
  });

  factory GeminiResponseModel.fromJson(Map<String, dynamic> json) {
    final tasksRaw = json['processed_tasks'];
    List<TaskModel> tasks = [];
    if (tasksRaw is List) {
      for (final item in tasksRaw) {
        if (item is Map<String, dynamic>) {
          try {
            tasks.add(TaskModel.fromJson(item));
          } catch (_) {}
        }
      }
    }

    return GeminiResponseModel(
      summary: json['summary']?.toString() ?? '',
      processedTasks: tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'processed_tasks': processedTasks.map((t) => t.toJson()).toList(),
    };
  }
}
