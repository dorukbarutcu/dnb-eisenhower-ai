import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/local_task_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final LocalTaskDatasource localDatasource;

  TaskRepositoryImpl(this.localDatasource);

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    return await localDatasource.getTasks();
  }

  @override
  Future<void> saveTask(TaskEntity task) async {
    await localDatasource.saveTask(TaskModel.fromEntity(task));
  }

  @override
  Future<void> saveTasks(List<TaskEntity> tasks) async {
    final models = tasks.map((t) => TaskModel.fromEntity(t)).toList();
    await localDatasource.saveTasks(models);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await localDatasource.deleteTask(taskId);
  }

  @override
  Future<void> toggleTaskCompletion(String taskId) async {
    final tasks = await localDatasource.getTasks();
    final index = tasks.indexWhere((t) => t.taskId == taskId);
    if (index != -1) {
      final task = tasks[index];
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      await localDatasource.saveTask(TaskModel.fromEntity(updated));
    }
  }

  @override
  Future<void> clearAllTasks() async {
    await localDatasource.clearAll();
  }
}
