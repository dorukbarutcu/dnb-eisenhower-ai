import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/calendar_remote_datasource.dart';
import '../../data/datasources/gemini_datasource.dart';
import '../../data/datasources/gmail_remote_datasource.dart';
import '../../data/datasources/local_task_datasource.dart';
import '../../data/models/calendar_event_model.dart';
import '../../data/models/raw_notification_model.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_source.dart';
import '../../domain/repositories/task_repository.dart';
import 'auth_provider.dart';
import 'gemini_config_provider.dart';

class TaskMatrixState {
  final List<TaskEntity> tasks;
  final bool isProcessing;
  final int queueLength;
  final String? statusMessage;
  final String? lastSummary;
  final String? errorMessage;

  const TaskMatrixState({
    this.tasks = const [],
    this.isProcessing = false,
    this.queueLength = 0,
    this.statusMessage,
    this.lastSummary,
    this.errorMessage,
  });

  List<TaskEntity> get q1Tasks =>
      tasks.where((t) => t.quadrant == EisenhowerQuadrant.q1).toList();
  List<TaskEntity> get q2Tasks =>
      tasks.where((t) => t.quadrant == EisenhowerQuadrant.q2).toList();
  List<TaskEntity> get q3Tasks =>
      tasks.where((t) => t.quadrant == EisenhowerQuadrant.q3).toList();
  List<TaskEntity> get q4Tasks =>
      tasks.where((t) => t.quadrant == EisenhowerQuadrant.q4).toList();

  TaskMatrixState copyWith({
    List<TaskEntity>? tasks,
    bool? isProcessing,
    int? queueLength,
    String? statusMessage,
    String? lastSummary,
    String? errorMessage,
  }) {
    return TaskMatrixState(
      tasks: tasks ?? this.tasks,
      isProcessing: isProcessing ?? this.isProcessing,
      queueLength: queueLength ?? this.queueLength,
      statusMessage: statusMessage,
      lastSummary: lastSummary ?? this.lastSummary,
      errorMessage: errorMessage,
    );
  }
}

class _AnalysisQueueItem {
  final String content;
  final TaskSource source;
  final Completer<void> completer;

  _AnalysisQueueItem({
    required this.content,
    required this.source,
    required this.completer,
  });
}

class TaskMatrixNotifier extends Notifier<TaskMatrixState> {
  final TaskRepository _repository = TaskRepositoryImpl(LocalTaskDatasource());
  final List<_AnalysisQueueItem> _queue = [];
  bool _isWorkerRunning = false;

  @override
  TaskMatrixState build() {
    Future.microtask(loadTasks);
    return const TaskMatrixState();
  }

  Future<void> loadTasks() async {
    final list = await _repository.getAllTasks();
    state = state.copyWith(tasks: list);
  }

  Future<void> processInputContent({
    required String content,
    required TaskSource source,
  }) async {
    final clean = content.trim();
    if (clean.isEmpty) return;

    final completer = Completer<void>();
    _queue.add(_AnalysisQueueItem(content: clean, source: source, completer: completer));
    state = state.copyWith(queueLength: _queue.length);
    _drainQueue();
    return completer.future;
  }

  Future<void> _drainQueue() async {
    if (_isWorkerRunning) return;
    _isWorkerRunning = true;

    while (_queue.isNotEmpty) {
      final current = _queue.removeAt(0);
      final remaining = _queue.length;
      state = state.copyWith(
        isProcessing: true,
        queueLength: remaining,
        statusMessage: remaining > 0
            ? 'Gemini AI ile analiz ediliyor ($remaining sırada bekliyor)...'
            : 'Gemini AI ile analiz ediliyor...',
        errorMessage: null,
      );

      try {
        await _executeAnalysis(content: current.content, source: current.source);
        current.completer.complete();
      } catch (e, st) {
        current.completer.completeError(e, st);
      }
    }

    _isWorkerRunning = false;
    state = state.copyWith(
      isProcessing: false,
      queueLength: 0,
    );
  }

  Future<void> _executeAnalysis({
    required String content,
    required TaskSource source,
  }) async {
    final config = ref.read(geminiConfigProvider);
    if (!config.isValid) {
      state = state.copyWith(
        errorMessage: 'Gemini API Key is missing. Please configure it in settings.',
      );
      return;
    }

    try {
      final geminiDatasource = GeminiDatasource(
        apiKey: config.apiKey,
        modelName: config.modelName,
      );

      final response = await geminiDatasource.processInput(
        rawContent: content,
        source: source.value,
        currentDateTime: DateTime.now(),
        onProgress: (msg) => state = state.copyWith(statusMessage: msg),
      );

      final authClient = await ref.read(googleAuthProvider.notifier).getAuthenticatedClient();
      CalendarRemoteDatasource? calendarDatasource;
      if (authClient != null) {
        calendarDatasource = CalendarRemoteDatasource(authClient);
      }

      final List<TaskEntity> finalizedTasks = [];

      for (final task in response.processedTasks) {
        var currentEvent = task.calendarEvent;

        // Synchronize with Google Calendar if enabled & client available
        if (currentEvent.shouldAdd && calendarDatasource != null) {
          try {
            state = state.copyWith(statusMessage: 'Syncing "${task.title}" to Google Calendar...');
            final eventModel = CalendarEventModel.fromEntity(currentEvent);
            final eventId = await calendarDatasource.createEvent(eventModel);
            if (eventId != null) {
              currentEvent = currentEvent.copyWith(googleCalendarEventId: eventId);
            }
          } catch (_) {}
        }

        finalizedTasks.add(task.copyWith(calendarEvent: currentEvent));
      }

      if (finalizedTasks.isNotEmpty) {
        await _repository.saveTasks(finalizedTasks);
        await loadTasks();
      }

      state = state.copyWith(
        lastSummary: response.summary,
        statusMessage: finalizedTasks.isNotEmpty
            ? '${finalizedTasks.length} görev matrise eklendi.'
            : (response.summary.isNotEmpty ? response.summary : 'İşlenecek görev bulunamadı.'),
      );
    } catch (e) {
      String msg = 'AI Processing Error: $e';
      final errLower = e.toString().toLowerCase();
      if (errLower.contains('503') || errLower.contains('high demand') || errLower.contains('unavailable')) {
        msg = 'Google Gemini sunucularında anlık aşırı yoğunluk yaşanıyor (503). Sistem otomatik olarak yeniden deneyecek.';
      } else if (errLower.contains('quota') || errLower.contains('limit')) {
        msg = 'Gemini API dakikalık kota sınırına ulaşıldı (Free Tier limit). Lütfen 15 saniye bekleyin.';
      }
      state = state.copyWith(
        errorMessage: msg,
      );
    }
  }

  Future<void> processNotification(RawNotificationModel notification) async {
    final content = 'From: ${notification.title}\nMessage: ${notification.text}';
    await processInputContent(content: content, source: notification.source);
  }

  Future<void> fetchAndProcessGmail() async {
    var authClient = await ref.read(googleAuthProvider.notifier).getAuthenticatedClient();
    if (authClient == null) {
      final authorized = await ref.read(googleAuthProvider.notifier).requestScopes();
      if (authorized) {
        authClient = await ref.read(googleAuthProvider.notifier).getAuthenticatedClient();
      }
    }

    if (authClient == null) {
      state = state.copyWith(
        errorMessage: 'Gmail erişim izni verilmedi. Lütfen Ayarlar > "Gmail ve Takvim İzinlerini Onayla" butonuna dokunun.',
      );
      return;
    }

    state = state.copyWith(isProcessing: true, statusMessage: 'Okunmamış Gmail iletileri taranıyor...');

    try {
      final gmailDatasource = GmailRemoteDatasource(authClient);
      final unread = await gmailDatasource.fetchUnreadEmails(maxResults: 10);

      if (unread.isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          statusMessage: 'Okunmamış önemli e-posta bulunamadı.',
        );
        return;
      }

      final combined = unread.map((e) => e.toPromptSummary()).join('\n---\n');
      await processInputContent(content: combined, source: TaskSource.gmail);
    } catch (e) {
      if (e.toString().contains('insufficient_scope')) {
        state = state.copyWith(
          isProcessing: false,
          errorMessage: 'Gmail yetkisi eksik. Lütfen açılan onay ekranında "İzin Ver (Allow)" seçeneğini onaylayın.',
        );
        await ref.read(googleAuthProvider.notifier).requestScopes();
      } else {
        state = state.copyWith(
          isProcessing: false,
          errorMessage: 'Gmail Hatası: $e',
        );
      }
    }
  }

  Future<void> toggleTask(String taskId) async {
    await _repository.toggleTaskCompletion(taskId);
    await loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    final task = state.tasks.firstWhere((t) => t.taskId == taskId);
    if (task.calendarEvent.googleCalendarEventId != null) {
      final authClient = await ref.read(googleAuthProvider.notifier).getAuthenticatedClient();
      if (authClient != null) {
        final calendarDs = CalendarRemoteDatasource(authClient);
        await calendarDs.deleteEvent(task.calendarEvent.googleCalendarEventId!);
      }
    }
    await _repository.deleteTask(taskId);
    await loadTasks();
  }

  Future<void> clearAll() async {
    await _repository.clearAllTasks();
    await loadTasks();
  }
}

final taskMatrixProvider =
    NotifierProvider<TaskMatrixNotifier, TaskMatrixState>(TaskMatrixNotifier.new);
