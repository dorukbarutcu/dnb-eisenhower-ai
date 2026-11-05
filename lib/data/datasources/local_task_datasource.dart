import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

class LocalTaskDatasource {
  static const String boxName = 'eisenhower_tasks';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<List<TaskModel>> getTasks() async {
    final box = await _getBox();
    final List<TaskModel> list = [];
    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw != null) {
        try {
          final Map<String, dynamic> map = jsonDecode(raw.toString());
          list.add(TaskModel.fromJson(map));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveTask(TaskModel task) async {
    final box = await _getBox();
    await box.put(task.taskId, jsonEncode(task.toJson()));
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final box = await _getBox();
    final Map<String, String> entries = {
      for (final t in tasks) t.taskId: jsonEncode(t.toJson())
    };
    await box.putAll(entries);
  }

  Future<void> deleteTask(String taskId) async {
    final box = await _getBox();
    await box.delete(taskId);
  }

  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}
