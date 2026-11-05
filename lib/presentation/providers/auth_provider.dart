import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import '../../core/network/google_auth_client.dart';

class GoogleAuthState {
  final GoogleSignInAccount? user;
  final bool isLoading;
  final String? errorMessage;

  const GoogleAuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  GoogleAuthState copyWith({
    GoogleSignInAccount? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GoogleAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class GoogleAuthNotifier extends Notifier<GoogleAuthState> {
  final GoogleAuthClientService _service = GoogleAuthClientService();

  @override
  GoogleAuthState build() {
    Future.microtask(_init);
    return const GoogleAuthState();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _service.initialize();
    state = state.copyWith(
      user: _service.currentUser,
      isLoading: false,
    );
    _service.onAuthStateChanged.listen((user) {
      state = state.copyWith(user: user, isLoading: false);
    });
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _service.signIn();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _service.signOut();
    state = const GoogleAuthState();
  }

  Future<auth.AuthClient?> getAuthenticatedClient() async {
    return await _service.getAuthenticatedClient();
  }
}

final googleAuthProvider =
    NotifierProvider<GoogleAuthNotifier, GoogleAuthState>(GoogleAuthNotifier.new);
