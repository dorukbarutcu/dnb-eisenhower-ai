import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/network/google_auth_client.dart';

class GoogleAuthState {
  final GoogleSignInAccount? user;
  final bool isLoading;
  final String? errorMessage;
  final String androidClientId;
  final String serverClientId;

  const GoogleAuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.androidClientId = '',
    this.serverClientId = '',
  });

  bool get isAuthenticated => user != null;

  GoogleAuthState copyWith({
    GoogleSignInAccount? user,
    bool? isLoading,
    String? errorMessage,
    String? androidClientId,
    String? serverClientId,
  }) {
    return GoogleAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      androidClientId: androidClientId ?? this.androidClientId,
      serverClientId: serverClientId ?? this.serverClientId,
    );
  }
}

class GoogleAuthNotifier extends Notifier<GoogleAuthState> {
  final GoogleAuthClientService _service = GoogleAuthClientService();
  static const String _boxName = 'app_settings';
  static const String _keyAndroidClientId = 'google_android_client_id';
  static const String _keyServerClientId = 'google_server_client_id';

  @override
  GoogleAuthState build() {
    Future.microtask(_init);
    return const GoogleAuthState();
  }

  Future<void> _init() async {
    final box = await Hive.openBox(_boxName);
    final savedAndroidId = box.get(_keyAndroidClientId, defaultValue: '') as String;
    final savedServerId = box.get(_keyServerClientId, defaultValue: '') as String;

    state = state.copyWith(
      androidClientId: savedAndroidId,
      serverClientId: savedServerId,
    );

    await _service.initialize(
      clientId: savedAndroidId.isNotEmpty ? savedAndroidId : null,
      serverClientId: savedServerId.isNotEmpty ? savedServerId : null,
    );
    state = state.copyWith(
      user: _service.currentUser,
      isLoading: false,
    );

    _service.onAuthStateChanged.listen((user) {
      state = state.copyWith(user: user, isLoading: false);
    });
  }

  Future<void> updateCredentials({
    String? androidClientId,
    String? serverClientId,
  }) async {
    final box = await Hive.openBox(_boxName);
    if (androidClientId != null) {
      await box.put(_keyAndroidClientId, androidClientId);
    }
    if (serverClientId != null) {
      await box.put(_keyServerClientId, serverClientId);
    }

    state = state.copyWith(
      androidClientId: androidClientId ?? state.androidClientId,
      serverClientId: serverClientId ?? state.serverClientId,
      errorMessage: null,
    );

    await _service.initialize(
      clientId: state.androidClientId.isNotEmpty ? state.androidClientId : null,
      serverClientId: state.serverClientId.isNotEmpty ? state.serverClientId : null,
    );
  }

  Future<void> signIn() async {
    if (state.serverClientId.trim().isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Giriş yapabilmek için lütfen önce Google Cloud Console\'dan aldığınız Web Client ID (serverClientId) bilgisini girip "Kaydet"e basın.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _service.signIn(
        clientId: state.androidClientId.isNotEmpty ? state.androidClientId : null,
        serverClientId: state.serverClientId.isNotEmpty ? state.serverClientId : null,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      String readableError = e.toString();
      if (readableError.contains('MISSING_SERVER_CLIENT_ID') ||
          readableError.contains('requires a serverClientId')) {
        readableError =
            'Android CredentialManager hatası: Google Cloud Console\'dan "Web application" türünde oluşturulan Client ID (serverClientId) girilmelidir.';
      } else if (readableError.contains('clientConfigurationError') ||
          readableError.contains('10') ||
          readableError.contains('Developer Error')) {
        readableError =
            'Google Cloud OAuth yapılandırma hatası: SHA-1 parmak izi veya Web Client ID uyuşmuyor. Paket adının "com.eisenhower.eisenhower_ai" olduğundan emin olun.';
      } else if (readableError.contains('canceled') || readableError.contains('12501')) {
        readableError = 'Giriş işlemi kullanıcı tarafından iptal edildi.';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: readableError,
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _service.signOut();
    state = state.copyWith(user: null, isLoading: false);
  }

  Future<auth.AuthClient?> getAuthenticatedClient() async {
    return await _service.getAuthenticatedClient();
  }
}

final googleAuthProvider =
    NotifierProvider<GoogleAuthNotifier, GoogleAuthState>(GoogleAuthNotifier.new);
