import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getAllTasks();
  Future<void> saveTask(TaskEntity task);
  Future<void> saveTasks(List<TaskEntity> tasks);
  Future<void> deleteTask(String taskId);
  Future<void> toggleTaskCompletion(String taskId);
  Future<void> clearAllTasks();
}
