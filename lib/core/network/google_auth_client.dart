import 'dart:async';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class GoogleAuthClientService {
  static final GoogleAuthClientService _instance = GoogleAuthClientService._internal();
  factory GoogleAuthClientService() => _instance;
  GoogleAuthClientService._internal();

  static const List<String> scopes = [
    calendar.CalendarApi.calendarEventsScope,
    gmail.GmailApi.gmailReadonlyScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  GoogleSignInClientAuthorization? _authorization;
  bool _initialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  final _authChangeController = StreamController<GoogleSignInAccount?>.broadcast();
  Stream<GoogleSignInAccount?> get onAuthStateChanged => _authChangeController.stream;

  Future<void> initialize({String? serverClientId}) async {
    if (_initialized) return;
    try {
      await _googleSignIn.initialize(serverClientId: serverClientId);
      _googleSignIn.authenticationEvents.listen((event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            _currentUser = event.user;
            _authChangeController.add(_currentUser);
          case GoogleSignInAuthenticationEventSignOut():
            _currentUser = null;
            _authorization = null;
            _authChangeController.add(null);
        }
      });
      await _googleSignIn.attemptLightweightAuthentication();
      _initialized = true;
    } catch (e) {
      debugPrint('Google Sign-In init error: $e');
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      if (!_initialized) {
        await initialize();
      }
      final account = await _googleSignIn.authenticate();
      _currentUser = account;
      _authChangeController.add(_currentUser);
      await getAuthorization();
      return account;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _authorization = null;
    _authChangeController.add(null);
  }

  Future<GoogleSignInClientAuthorization?> getAuthorization() async {
    if (_currentUser == null) return null;
    try {
      _authorization = await _currentUser!.authorizationClient.authorizationForScopes(scopes)
          ?? await _currentUser!.authorizationClient.authorizeScopes(scopes);
      return _authorization;
    } catch (e) {
      debugPrint('Authorization error: $e');
      return null;
    }
  }

  Future<auth.AuthClient?> getAuthenticatedClient() async {
    final authz = _authorization ?? await getAuthorization();
    if (authz == null) return null;
    return authz.authClient(scopes: scopes);
  }
}
