import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final config = ref.read(geminiConfigProvider);
    _apiKeyController = TextEditingController(text: config.apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
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
                      value: 'gemini-1.5-flash',
                      child: Text('gemini-1.5-flash (Fast & Efficient)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-1.5-pro',
                      child: Text('gemini-1.5-pro (High Reasoning)'),
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
                    'Connect your Google Account to automatically pull unread Gmail messages and sync scheduled Eisenhower tasks directly into Google Calendar.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      icon: const Icon(Icons.account_circle, color: Colors.white),
                      label: authState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In with Google'),
                      onPressed: authState.isLoading
                          ? null
                          : () => ref.read(googleAuthProvider.notifier).signIn(),
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
