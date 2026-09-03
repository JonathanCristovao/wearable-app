import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity_record.dart';
import '../models/user_profile.dart';

/// Exports all activities organised by user into a ZIP file.
///
/// ZIP structure:
/// ```
/// activities_export_<timestamp>.zip
/// ├── usuarios.json                       ← list of all users + demographics
/// ├── <userId>_<userName>/
/// │   ├── metadata.json                   ← user demographics
/// │   └── <activityId>.json               ← full activity data
/// └── sem_usuario/
///     └── <activityId>.json               ← records with no associated user
/// ```
class ExportService {
  ExportService._();

  static Future<void> exportAllActivities({
    required List<ActivityRecord> records,
    required List<UserProfile> users,
  }) async {
    final archive = Archive();

    // ------------------------------------------------------------------
    // usuarios.json  – top-level manifest with all user demographics
    // ------------------------------------------------------------------
    final usersManifest = users
        .map(
          (u) => {
            'id': u.id,
            'name': u.name,
            'age': u.age,
            'weight_kg': u.weight,
            'height_cm': u.height,
            'injury': u.injury,
            'activityFrequency': u.activityFrequency,
            'disease': u.disease,
          },
        )
        .toList();

    _addJsonToArchive(
      archive,
      'usuarios.json',
      {'users': usersManifest, 'exportedAt': DateTime.now().toIso8601String()},
    );

    // ------------------------------------------------------------------
    // Per-user folders
    // ------------------------------------------------------------------
    final userMap = {for (final u in users) u.id: u};

    // Group records by userId (null → 'sem_usuario')
    final grouped = <String, List<ActivityRecord>>{};
    for (final record in records) {
      final key = record.userId ?? 'sem_usuario';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    for (final entry in grouped.entries) {
      final userId = entry.key;
      final userRecords = entry.value;
      final user = userMap[userId];

      final folderName = user != null
          ? _safeName('${user.id}_${user.name}')
          : 'sem_usuario';

      // metadata.json inside the user folder
      if (user != null) {
        _addJsonToArchive(archive, '$folderName/metadata.json', {
          'id': user.id,
          'name': user.name,
          'age': user.age,
          'weight_kg': user.weight,
          'height_cm': user.height,
          'injury': user.injury,
          'activityFrequency': user.activityFrequency,
          'disease': user.disease,
        });
      }

      // One JSON file per activity
      for (final record in userRecords) {
        final fileName = '$folderName/${record.id}.json';
        _addJsonToArchive(archive, fileName, record.toJson());
      }
    }

    // ------------------------------------------------------------------
    // Encode and write ZIP to a temp file
    // ------------------------------------------------------------------
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) throw StateError('ZIP encoding failed.');

    final tmpDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);
    final zipPath = '${tmpDir.path}/activities_export_$timestamp.zip';

    await File(zipPath).writeAsBytes(bytes, flush: true);

    // ------------------------------------------------------------------
    // Share / save via the system sheet
    // ------------------------------------------------------------------
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipPath, mimeType: 'application/zip')],
        subject: 'Exportação de Atividades – $timestamp',
        text: 'Exportação de ${records.length} atividade(s) de '
            '${users.length} usuário(s).',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static void _addJsonToArchive(
    Archive archive,
    String path,
    Object data,
  ) {
    final content = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    archive.addFile(ArchiveFile(path, content.length, content));
  }

  /// Removes characters that are unsafe in folder/file names.
  static String _safeName(String name) =>
      name.replaceAll(RegExp(r'[<>:"/\\|?*\s]'), '_');
}
