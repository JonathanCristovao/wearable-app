import 'dart:convert';
import 'dart:typed_data';

/// Utilities for JSON / JSONL serialization.
class JsonUtils {
  JsonUtils._();

  /// Serializes [records] as JSONL — one JSON object per line.
  ///
  /// JSONL is the preferred format for streaming sensor data because
  /// each line is independently parseable, which suits ML pipelines.
  static String toJsonL(List<Map<String, dynamic>> records) {
    return records.map(jsonEncode).join('\n');
  }

  /// Returns the UTF-8-encoded JSONL bytes for [records].
  static Uint8List toJsonLBytes(List<Map<String, dynamic>> records) {
    return Uint8List.fromList(utf8.encode(toJsonL(records)));
  }

  /// Parses a JSONL [source] back into a list of maps.
  static List<Map<String, dynamic>> fromJsonL(String source) {
    return source
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }
}
