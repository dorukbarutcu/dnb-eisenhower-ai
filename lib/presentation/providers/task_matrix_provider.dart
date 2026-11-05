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
  final String? statusMessage;
  final String? lastSummary;
  final String? errorMessage;

  const TaskMatrixState({
    this.tasks = const [],
    this.isProcessing = false,
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
    String? statusMessage,
    String? lastSummary,
    String? errorMessage,
  }) {
    return TaskMatrixState(
      tasks: tasks ?? this.tasks,
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: statusMessage,
      lastSummary: lastSummary ?? this.lastSummary,
      errorMessage: errorMessage,
    );
  }
}

class TaskMatrixNotifier extends Notifier<TaskMatrixState> {
  final TaskRepository _repository = TaskRepositoryImpl(LocalTaskDatasource());

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
    final config = ref.read(geminiConfigProvider);
    if (!config.isValid) {
      state = state.copyWith(
        errorMessage: 'Gemini API Key is missing. Please configure it in settings.',
      );
      return;
    }

    state = state.copyWith(
      isProcessing: true,
      statusMessage: 'Analyzing with Gemini AI...',
      errorMessage: null,
    );

    try {
      final geminiDatasource = GeminiDatasource(
        apiKey: config.apiKey,
        modelName: config.modelName,
      );

      final response = await geminiDatasource.processInput(
        rawContent: content,
        source: source.value,
        currentDateTime: DateTime.now(),
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

      await _repository.saveTasks(finalizedTasks);
      await loadTasks();

      state = state.copyWith(
        isProcessing: false,
        lastSummary: response.summary,
        statusMessage: 'Processed ${finalizedTasks.length} task(s) successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'AI Processing Error: $e',
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
