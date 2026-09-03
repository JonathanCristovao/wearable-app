import 'package:firebase_auth/firebase_auth.dart';

/// Manages anonymous Firebase Authentication.
///
/// Call [signInAnonymously] once during app startup.
/// The authenticated [uid] is then available for building Storage paths.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;

  /// Returns the current anonymous user UID, or null if not authenticated.
  String? get uid {
    _currentUser ??= _auth.currentUser;
    return _currentUser?.uid;
  }

  bool get isAuthenticated {
    _currentUser ??= _auth.currentUser;
    return _currentUser != null;
  }

  /// Signs in anonymously, reusing the existing session if one is active.
  Future<void> signInAnonymously() async {
    // Reuse the existing Firebase session (survives app restarts).
    if (_auth.currentUser != null) {
      _currentUser = _auth.currentUser;
      return;
    }

    try {
      final credential = await _auth.signInAnonymously();
      _currentUser = credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException('Anonymous sign-in failed [${e.code}]: ${e.message}');
    }
  }

  /// Signs out and clears the local session reference.
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
