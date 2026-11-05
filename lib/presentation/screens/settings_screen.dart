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
  late final TextEditingController _androidClientIdController;
  late final TextEditingController _serverClientIdController;
  bool _showIntroGuide = false;

  static const String appPackageName = 'com.eisenhower.eisenhower_ai';
  static const String debugSha1 = 'B3:7B:7A:6C:5A:E9:34:D2:D5:1C:93:64:56:0F:EE:C3:25:48:CC:22';

  @override
  void initState() {
    super.initState();
    final config = ref.read(geminiConfigProvider);
    final authState = ref.read(googleAuthProvider);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _androidClientIdController = TextEditingController(text: authState.androidClientId);
    _serverClientIdController = TextEditingController(text: authState.serverClientId);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _androidClientIdController.dispose();
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
        title: const Text('Ayarlar & Entegrasyonlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gemini API Configuration
          _buildSectionHeader('Yapay Zeka Motoru (Google Gemini)'),
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
                    labelText: 'Gemini API Anahtarı',
                    hintText: 'AI Studio API Anahtarınızı girin',
                    prefixIcon: Icon(Icons.key, color: AppColors.q2Blue),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: geminiConfig.modelName,
                  decoration: const InputDecoration(
                    labelText: 'Model Seçimi',
                    prefixIcon: Icon(Icons.psychology, color: AppColors.q2Blue),
                  ),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'gemini-3.8-flash',
                      child: Text('gemini-3.8-flash (Gemini 3.8 Flash - Önerilen)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-2.5-flash',
                      child: Text('gemini-2.5-flash (Gemini 2.5 Flash - Kararlı)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-1.5-flash',
                      child: Text('gemini-1.5-flash (Gemini 1.5 Flash - Yüksek Kota)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-3.8-pro',
                      child: Text('gemini-3.8-pro (Gemini 3.8 Pro - Yüksek Akıl Yürütme)'),
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
                          const SnackBar(content: Text('Gemini ayarları kaydedildi!')),
                        );
                      }
                    },
                    child: const Text('Gemini Ayarlarını Kaydet'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Google Account Integration (Gmail & Calendar)
          _buildSectionHeader('Google Servisleri (Gmail & Google Calendar)'),
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

                // Kurulum Rehberi Butonu (Introduction)
                InkWell(
                  onTap: () => setState(() => _showIntroGuide = !_showIntroGuide),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.q2Blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.q2Blue.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: AppColors.q2Blue, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Google Cloud Kurulum Rehberi (Adım Adım)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.q2Blue,
                            ),
                          ),
                        ),
                        Icon(
                          _showIntroGuide ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.q2Blue,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showIntroGuide) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepItem(
                          step: '1',
                          title: 'Google Cloud Projesi',
                          desc: 'console.cloud.google.com üzerinde yeni bir proje açın veya mevcut projenizi seçin.',
                        ),
                        _buildStepItem(
                          step: '2',
                          title: 'API ve OAuth Kapsamlarını (Scopes) Etkinleştirin',
                          desc: '1) API Library\'den "Google Calendar API" ve "Gmail API" servislerini açın.\n2) "OAuth consent screen > Scopes" bölümünden ".../auth/gmail.readonly" ve ".../auth/calendar.events" kapsamlarını ekleyin.\n3) Test users bölümüne kendi Gmail adresinizi ekleyin.',
                        ),
                        _buildStepItem(
                          step: '3',
                          title: 'Android Client ID Oluşturun',
                          desc: 'Credentials > Create Credentials > OAuth client ID > Tür: Android seçin. Aşağıdaki Paket Adı ve SHA-1 parmak izini yapıştırın. Oluşan Client ID\'yi kopyalayın.',
                        ),
                        _buildStepItem(
                          step: '4',
                          title: 'Web Application Client ID Oluşturun (Zorunlu)',
                          desc: 'Yine Credentials > Create Credentials > OAuth client ID > Tür: Web application seçin. Oluşan Client ID\'yi kopyalayın (serverClientId olarak kullanılır).',
                        ),
                        _buildStepItem(
                          step: '5',
                          title: 'ID\'leri Aşağıya Yapıştırıp Kaydedin',
                          desc: 'Her iki ID\'yi aşağıdaki ilgili alanlara yapıştırıp "Kaydet"e basın, ardından giriş yapın.',
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

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
                    title: Text(authState.user?.displayName ?? 'Bağlı Hesap'),
                    subtitle: Text(authState.user?.email ?? ''),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.q2Blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.security_update_good, size: 18),
                      label: const Text('Gmail & Takvim Yetkisini Onayla'),
                      onPressed: () async {
                        final success = await ref.read(googleAuthProvider.notifier).requestScopes();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Gmail ve Takvim yetkisi başarıyla verildi!'
                                  : 'Yetkilendirme onaylanmadı.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                      onPressed: () => ref.read(googleAuthProvider.notifier).signOut(),
                      child: const Text('Google Hesabının Bağlantısını Kes'),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _androidClientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Android Client ID (Opsiyonel)',
                      hintText: 'xxxxxx.apps.googleusercontent.com',
                      prefixIcon: Icon(Icons.android, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverClientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Web Client ID (serverClientId - Zorunlu)',
                      hintText: 'yyyyyy.apps.googleusercontent.com',
                      prefixIcon: Icon(Icons.language, color: AppColors.q2Blue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Kimlik Bilgilerini Kaydet'),
                      onPressed: () async {
                        final androidId = _androidClientIdController.text.trim();
                        final serverId = _serverClientIdController.text.trim();
                        await ref.read(googleAuthProvider.notifier).updateCredentials(
                              androidClientId: androidId,
                              serverClientId: serverId,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kimlik bilgileri yerel hafızaya kaydedildi!')),
                          );
                        }
                      },
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
                              final androidId = _androidClientIdController.text.trim();
                              final serverId = _serverClientIdController.text.trim();
                              ref.read(googleAuthProvider.notifier).updateCredentials(
                                    androidClientId: androidId,
                                    serverClientId: serverId,
                                  );
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
          _buildSectionHeader('Android Bildirim Dinleyicisi'),
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
                                ? 'Bildirim Erişimi Aktif'
                                : 'Bildirim Erişimi Gerekli',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            notifState.hasPermission
                                ? 'WhatsApp ve Telegram bildirimleri dinleniyor'
                                : 'Android ayarlarından bildirim erişim iznini onaylayın',
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
                    label: const Text('Android Bildirim Ayarlarını Aç'),
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

  Widget _buildStepItem({required String step, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.q2Blue,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
