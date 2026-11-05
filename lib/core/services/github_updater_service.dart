import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GitHubReleaseInfo {
  final String tagName;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String releaseUrl;
  final int apkSizeBytes;
  final bool isNewer;

  const GitHubReleaseInfo({
    required this.tagName,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.releaseUrl,
    required this.apkSizeBytes,
    required this.isNewer,
  });
}

class GitHubUpdaterService {
  static const String currentVersion = '1.0.3';
  static const String repoOwner = 'dorukbarutcu';
  static const String repoName = 'dnb-eisenhower-ai';

  static const MethodChannel _channel = MethodChannel('com.eisenhower.ai/updater');

  Future<GitHubReleaseInfo?> checkForUpdate() async {
    try {
      final client = HttpClient();
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'DNBEisenhowerAI-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('GitHub updater: HTTP ${response.statusCode}');
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final tagName = json['tag_name']?.toString() ?? '';
      final bodyText = json['body']?.toString() ?? '';
      final assets = json['assets'] as List<dynamic>?;

      String apkUrl = '';
      int apkSize = 0;

      if (assets != null) {
        for (final a in assets) {
          final name = a['name']?.toString() ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = a['browser_download_url']?.toString() ?? '';
            apkSize = (a['size'] as num?)?.toInt() ?? 0;
            break;
          }
        }
      }

      final cleanTag = tagName.replaceAll('v', '').trim();
      final isNewer = _isVersionGreater(cleanTag, currentVersion);
      final releaseHtmlUrl = json['html_url']?.toString() ?? 'https://github.com/$repoOwner/$repoName/releases/latest';

      return GitHubReleaseInfo(
        tagName: tagName,
        releaseNotes: bodyText,
        apkDownloadUrl: apkUrl,
        releaseUrl: releaseHtmlUrl,
        apkSizeBytes: apkSize,
        isNewer: isNewer,
      );
    } catch (e) {
      debugPrint('GitHub update check error: $e');
      return null;
    }
  }

  bool _isVersionGreater(String remote, String local) {
    try {
      final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final lParts = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (var i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> openInBrowser(String url) async {
    try {
      await _channel.invokeMethod('openUrl', {'url': url});
    } catch (_) {}
  }

  Future<void> downloadAndInstall({
    required String downloadUrl,
    Function(int received, int total)? onProgress,
  }) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(downloadUrl));
    request.headers.set('User-Agent', 'DNBEisenhowerAI-App');
    final response = await request.close();

    final total = response.contentLength;
    int received = 0;

    // Retrieve native app cache directory
    String? nativeCachePath;
    try {
      nativeCachePath = await _channel.invokeMethod<String>('getCachePath');
    } catch (_) {}
    final dirPath = nativeCachePath ?? Directory.systemTemp.path;
    final file = File('$dirPath/update.apk');
    if (await file.exists()) {
      await file.delete();
    }

    final sink = file.openWrite();
    await for (final chunk in response) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }
    await sink.flush();
    await sink.close();

    // Trigger native APK installer
    await _channel.invokeMethod('installApk', {'filePath': file.path});
  }
}
