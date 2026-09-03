import 'dart:io';
import 'dart:typed_data';

/// Utilities for GZIP compression using Dart's built-in [GZipCodec].
class GzipUtils {
  GzipUtils._();

  /// Compresses [bytes] with GZIP and returns the compressed [Uint8List].
  static Uint8List compress(List<int> bytes) {
    return Uint8List.fromList(gzip.encode(bytes));
  }

  /// Decompresses a GZIP-encoded [Uint8List].
  static Uint8List decompress(List<int> bytes) {
    return Uint8List.fromList(gzip.decode(bytes));
  }
}
