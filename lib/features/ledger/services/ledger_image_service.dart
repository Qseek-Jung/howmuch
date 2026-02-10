import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class LedgerImageService {
  static const String _receiptsDirName = 'receipts';

  /// Get the directory where receipts are permanently stored.
  Future<Directory> _getReceiptsDirectory() async {
    final appDocs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDocs.path, _receiptsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies a picked file to permanent storage and returns the filename (relative path).
  Future<String?> copyToPermanent(XFile xFile) async {
    try {
      final dir = await _getReceiptsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(xFile.path)}';
      final permanentPath = p.join(dir.path, fileName);

      final File file = File(xFile.path);
      await file.copy(permanentPath);

      return fileName; // Store only the filename in the JSON
    } catch (e) {
      debugPrint('Error copying image to permanent storage: $e');
      return null;
    }
  }

  /// Returns a File object by resolving the path.
  /// Handles both absolute (legacy) and relative (new) paths.
  Future<File?> getPermanentFile(String path) async {
    if (path.isEmpty) return null;

    // Check if it's already an absolute path (legacy)
    if (p.isAbsolute(path)) {
      final file = File(path);
      if (await file.exists()) return file;

      // If absolute path doesn't exist, it might be a legacy path from a different device/install.
      // We can try to see if the filename exists in our receipts dir as a last resort.
      final fileName = p.basename(path);
      final dir = await _getReceiptsDirectory();
      final fallbackFile = File(p.join(dir.path, fileName));
      if (await fallbackFile.exists()) return fallbackFile;

      return null;
    }

    // New logic: path is just the filename relative to receipts dir
    final dir = await _getReceiptsDirectory();
    final file = File(p.join(dir.path, path));
    if (await file.exists()) return file;

    return null;
  }

  /// Static helper to check if a path is relative (just a filename)
  bool isRelative(String path) {
    return !p.isAbsolute(path) && !path.contains('/') && !path.contains('\\');
  }
}
