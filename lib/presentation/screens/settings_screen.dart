import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gemini_config_provider.dart';
import '../providers/notification_listener_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _serverClientIdController;

  static const String appPackageName = 'com.eisenhower.eisenhower_ai';
  static const String debugSha1 = 'B3:7B:7A:6C:5A:E9:34:D2:D5:1C:93:64:56:0F:EE:C3:25:48:CC:22';

  @override
  void initState() {
    super.initState();
    final config = ref.read(geminiConfigProvider);
    final authState = ref.read(googleAuthProvider);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _serverClientIdController = TextEditingController(text: authState.serverClientId);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _serverClientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geminiConfig = ref.watch(geminiConfigProvider);
    final authState = ref.watch(googleAuthProvider);
    final notifState = ref.watch(notificationListenerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Integrations'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gemini API Configuration
          _buildSectionHeader('Intelligence Engine (Gemini API)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'Enter your AI Studio API Key',
                    prefixIcon: Icon(Icons.key, color: AppColors.q2Blue),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: geminiConfig.modelName,
                  decoration: const InputDecoration(
                    labelText: 'Model Selection',
                    prefixIcon: Icon(Icons.psychology, color: AppColors.q2Blue),
                  ),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'gemini-2.5-flash',
                      child: Text('gemini-2.5-flash (En Güncel Flash)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-flash-latest',
                      child: Text('gemini-flash-latest (Otomatik Son Sürüm)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-2.5-pro',
                      child: Text('gemini-2.5-pro (Yüksek Akıl Yürütme)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(geminiConfigProvider.notifier).updateConfig(
                            apiKey: _apiKeyController.text.trim(),
                            modelName: val,
                          );
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.q2Blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await ref.read(geminiConfigProvider.notifier).updateConfig(
                            apiKey: _apiKeyController.text.trim(),
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gemini settings saved!')),
                        );
                      }
                    },
                    child: const Text('Save Gemini Configuration'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Google Account Integration (Gmail & Calendar)
          _buildSectionHeader('Google Services (Gmail & Calendar)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withAlpha(120)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (authState.isAuthenticated) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        (authState.user?.displayName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(authState.user?.displayName ?? 'Connected User'),
                    subtitle: Text(authState.user?.email ?? ''),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                      onPressed: () => ref.read(googleAuthProvider.notifier).signOut(),
                      child: const Text('Disconnect Google Account'),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Android Credential Manager üzerinden Gmail ve Calendar API erişimi için Google Cloud Console Web Client ID (serverClientId) gereklidir.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _serverClientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Web Client ID (serverClientId)',
                      hintText: 'xxxxxx.apps.googleusercontent.com',
                      prefixIcon: Icon(Icons.security, color: AppColors.q2Blue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final id = _serverClientIdController.text.trim();
                        await ref.read(googleAuthProvider.notifier).updateServerClientId(id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Client ID kaydedildi.')),
                          );
                        }
                      },
                      child: const Text('Kaydet'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCopyCard(
                    title: 'Paket Adı (Package Name)',
                    value: appPackageName,
                  ),
                  const SizedBox(height: 8),
                  _buildCopyCard(
                    title: 'Debug SHA-1 Parmak İzi',
                    value: debugSha1,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.q2Blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.account_circle, color: Colors.white),
                      label: authState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign In with Google'),
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              final id = _serverClientIdController.text.trim();
                              ref.read(googleAuthProvider.notifier).updateServerClientId(id);
                              ref.read(googleAuthProvider.notifier).signIn();
                            },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Android Notification Listener Service
          _buildSectionHeader('Android Notification Harvester'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      notifState.hasPermission ? Icons.notifications_active : Icons.notifications_off,
                      color: notifState.hasPermission ? Colors.green : Colors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notifState.hasPermission
                                ? 'Notification Access Granted'
                                : 'Notification Access Required',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            notifState.hasPermission
                                ? 'Actively intercepting WhatsApp and Telegram notifications'
                                : 'Grant notification listener permission in Android settings',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Open Android Notification Settings'),
                    onPressed: () async {
                      await ref.read(notificationListenerProvider.notifier).openSettings();
                      await ref.read(notificationListenerProvider.notifier).checkPermission();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: AppColors.q2Blue),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title panoya kopyalandı!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
