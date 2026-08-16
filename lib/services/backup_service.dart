import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_state.dart';

/// Export / import full Expens backup JSON files.
class BackupService {
  /// Write backup to a temp file and open the system share sheet
  /// (Drive, Files, WhatsApp, AirDrop, etc.).
  static Future<void> exportShare(AppState state) async {
    final json = state.exportBackupJson();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'expens_backup_$stamp.json'));
    await file.writeAsString(json, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Expens backup $stamp',
        text:
            'Expens full data backup — restore in Settings → Import on a new phone.',
      ),
    );
  }

  /// Pick a `.json` backup and return its text, or null if cancelled.
  static Future<String?> pickBackupJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return utf8.decode(file.bytes!);
    }
    final path = file.path;
    if (path == null || path.isEmpty) return null;
    return File(path).readAsString();
  }
}
