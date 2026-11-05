import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/github_updater_service.dart';

class UpdaterState {
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final GitHubReleaseInfo? releaseInfo;
  final String? errorMessage;

  const UpdaterState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.releaseInfo,
    this.errorMessage,
  });

  bool get hasUpdate => releaseInfo != null && releaseInfo!.isNewer && releaseInfo!.apkDownloadUrl.isNotEmpty;

  UpdaterState copyWith({
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    GitHubReleaseInfo? releaseInfo,
    String? errorMessage,
  }) {
    return UpdaterState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      releaseInfo: releaseInfo ?? this.releaseInfo,
      errorMessage: errorMessage,
    );
  }
}

class UpdaterNotifier extends Notifier<UpdaterState> {
  final GitHubUpdaterService _service = GitHubUpdaterService();

  @override
  UpdaterState build() {
    Future.microtask(checkForUpdate);
    return const UpdaterState();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(isChecking: true, errorMessage: null);
    try {
      final info = await _service.checkForUpdate();
      state = state.copyWith(
        isChecking: false,
        releaseInfo: info,
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> downloadAndInstall() async {
    final info = state.releaseInfo;
    if (info == null || info.apkDownloadUrl.isEmpty) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0, errorMessage: null);

    try {
      await _service.downloadAndInstall(
        downloadUrl: info.apkDownloadUrl,
        onProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            state = state.copyWith(downloadProgress: progress);
          }
        },
      );
      state = state.copyWith(isDownloading: false, downloadProgress: 1.0);
    } catch (e) {
      state = state.copyWith(isDownloading: false, errorMessage: 'İndirme hatası: $e');
    }
  }

  Future<void> openReleaseInBrowser() async {
    final info = state.releaseInfo;
    if (info == null) return;
    final targetUrl = info.apkDownloadUrl.isNotEmpty ? info.apkDownloadUrl : info.releaseUrl;
    await _service.openInBrowser(targetUrl);
  }
}

final updaterProvider = NotifierProvider<UpdaterNotifier, UpdaterState>(UpdaterNotifier.new);
