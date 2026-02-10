import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/ledger_backup.dart';

class LedgerFileService {
  static const String _fileName = 'howmuch_ledger_backup.json';

  /// Get the persistent file path.
  /// Note: On Android, we try to use a directory that might survive/be accessible.
  Future<File> _getBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    // In a real scenario for "surviving uninstall", we might want to use
    // a more public directory, but that requires more permissions.
    // For now, we use the standard documents directory.
    return File('${directory.path}/$_fileName');
  }

  /// Save projects to a JSON file
  Future<void> saveToFile(LedgerBackup backup) async {
    try {
      final file = await _getBackupFile();
      final jsonString = jsonEncode(backup.toJson());
      await file.writeAsString(jsonString);
      print('Ledger data backed up to file: ${file.path}');
    } catch (e) {
      print('Error saving ledger file: $e');
    }
  }

  /// Load projects from a JSON file
  Future<LedgerBackup?> loadFromFile({File? specificFile}) async {
    try {
      final file = specificFile ?? await _getBackupFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final decoded = jsonDecode(jsonString);
        return LedgerBackup.fromJson(decoded);
      }
    } catch (e) {
      print('Error loading ledger file: $e');
    }
    return null;
  }

  /// Pick a file manually and load projects
  Future<LedgerBackup?> pickAndLoadBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        return loadFromFile(specificFile: File(result.files.single.path!));
      }
    } catch (e) {
      print('Error picking/loading ledger file: $e');
    }
    return null;
  }

  /// Get backup file path for manual sharing/export with timestamp
  Future<String?> getExportPath(LedgerBackup backup) async {
    try {
      final directory = await getTemporaryDirectory();
      final date = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'howmuch_ledger_$date.json';
      final file = File('${directory.path}/$fileName');

      final jsonString = jsonEncode(backup.toJson());
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      print('Error generating export path: $e');
    }
    return null;
  }

  /// Get internal backup path (checking existence)
  Future<String?> getInternalBackupPath() async {
    final file = await _getBackupFile();
    if (await file.exists()) return file.path;
    return null;
  }

  /// Search common external directories for matching backup files.
  /// Primarily for Android 'Download' folder discovery.
  Future<List<File>> findExternalBackups() async {
    final List<File> backupFiles = [];
    final List<String> rawPaths = [];

    if (Platform.isAndroid) {
      rawPaths.addAll([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/sdcard/Download',
        '/sdcard/Documents',
        '/storage/emulated/0/Download/KakaoTalk',
        '/storage/emulated/0/KakaoTalkDownload',
        '/sdcard/Download/KakaoTalk',
      ]);
    } else if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      rawPaths.add(docs.path);
    }

    // 1. Normalize paths (resolve /sdcard symlink)
    final Set<String> normalizedPaths = rawPaths.map((p) {
      return p.replaceFirst('/sdcard/', '/storage/emulated/0/');
    }).toSet();

    // 2. Remove redundant subdirectories (if we scan parent recursively, skip child)
    final List<String> searchPaths = normalizedPaths.toList()..sort();
    final List<String> uniqueSearchPaths = [];
    for (final path in searchPaths) {
      if (uniqueSearchPaths.any((parent) => path.startsWith('$parent/'))) {
        continue;
      }
      uniqueSearchPaths.add(path);
    }

    final Set<String> seenFingerprints = {};

    for (final path in uniqueSearchPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is File) {
              _processFile(entity, backupFiles, seenFingerprints);
            }
          }
        } catch (e) {
          debugPrint('Error scanning $path: $e');
          try {
            final entities = await dir.list().toList();
            for (final entity in entities) {
              if (entity is File) {
                _processFile(entity, backupFiles, seenFingerprints);
              }
            }
          } catch (e2) {
            debugPrint('Fallback scan also failed for $path: $e2');
          }
        }
      }
    }

    // Sort by modified date newest first
    backupFiles.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (e) {
        return 0;
      }
    });

    return backupFiles;
  }

  void _processFile(File file, List<File> list, Set<String> seenFingerprints) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    if (fileName.toLowerCase().startsWith('howmuch_ledger') &&
        fileName.toLowerCase().endsWith('.json')) {
      try {
        // Fingerprint: name + extension + size (best effort for deduplication across symlinks)
        final size = file.lengthSync();
        final fingerprint = '$fileName-$size';
        if (seenFingerprints.add(fingerprint)) {
          list.add(file);
        }
      } catch (e) {
        // Fallback to just path if stat fails
        if (seenFingerprints.add(file.path)) {
          list.add(file);
        }
      }
    }
  }
}
