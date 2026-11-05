import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/network/google_auth_client.dart';

class GoogleAuthState {
  final GoogleSignInAccount? user;
  final bool isLoading;
  final String? errorMessage;
  final String serverClientId;

  const GoogleAuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.serverClientId = '',
  });

  bool get isAuthenticated => user != null;

  GoogleAuthState copyWith({
    GoogleSignInAccount? user,
    bool? isLoading,
    String? errorMessage,
    String? serverClientId,
  }) {
    return GoogleAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      serverClientId: serverClientId ?? this.serverClientId,
    );
  }
}

class GoogleAuthNotifier extends Notifier<GoogleAuthState> {
  final GoogleAuthClientService _service = GoogleAuthClientService();
  static const String _boxName = 'app_settings';
  static const String _keyServerClientId = 'google_server_client_id';

  @override
  GoogleAuthState build() {
    Future.microtask(_init);
    return const GoogleAuthState();
  }

  Future<void> _init() async {
    final box = await Hive.openBox(_boxName);
    final savedClientId = box.get(_keyServerClientId, defaultValue: '') as String;

    state = state.copyWith(serverClientId: savedClientId);

    await _service.initialize(serverClientId: savedClientId);
    state = state.copyWith(
      user: _service.currentUser,
      isLoading: false,
    );

    _service.onAuthStateChanged.listen((user) {
      state = state.copyWith(user: user, isLoading: false);
    });
  }

  Future<void> updateServerClientId(String clientId) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_keyServerClientId, clientId);
    state = state.copyWith(serverClientId: clientId, errorMessage: null);
    await _service.initialize(serverClientId: clientId);
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _service.signIn(
        serverClientId: state.serverClientId.isNotEmpty ? state.serverClientId : null,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      String readableError = e.toString();
      if (readableError.contains('clientConfigurationError') || readableError.contains('10') || readableError.contains('Developer Error')) {
        readableError = 'Google Cloud OAuth yapılandırma hatası: SHA-1 parmak izi ve OAuth Web Client ID (serverClientId) tanımlanmalıdır.';
      } else if (readableError.contains('canceled') || readableError.contains('12501')) {
        readableError = 'Giriş işlemi iptal edildi veya Google Cloud izinleri eşleşmiyor.';
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
