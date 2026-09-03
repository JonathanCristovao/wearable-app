import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';

/// Handles all Firebase Storage upload operations.
///
/// Every path is automatically scoped to the authenticated user:
///   sensor-data/users/{uid}/{relativePath}
///
/// All uploads are retried up to [_maxRetries] times with
/// exponential back-off before throwing a [StorageException].
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _auth = AuthService();

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Uploads raw [data] bytes to [relativePath] under the user's folder.
  Future<void> uploadBytes({
    required String relativePath,
    required Uint8List data,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    final ref = _storage.ref(_userPath(relativePath));
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: customMetadata,
    );

    await _withRetry(() => ref.putData(data, metadata));
  }

  /// Uploads a UTF-8 [content] string to [relativePath] under the user's folder.
  Future<void> uploadString({
    required String relativePath,
    required String content,
    required String contentType,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    await uploadBytes(
      relativePath: relativePath,
      data: bytes,
      contentType: contentType,
    );
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  String _userPath(String relativePath) {
    final uid = _auth.uid;
    if (uid == null) {
      throw StateError('StorageService: user is not authenticated');
    }
    return 'sensor-data/users/$uid/$relativePath';
  }

  Future<void> _withRetry(Future<void> Function() action) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await action();
        return;
      } on FirebaseException catch (e) {
        if (attempt == _maxRetries) {
          throw StorageException(
            'Upload failed after $_maxRetries attempts [${e.code}]: ${e.message}',
          );
        }
        // Exponential back-off: 2 s, 4 s, …
        await Future<void>.delayed(_retryDelay * attempt);
      }
    }
  }
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
