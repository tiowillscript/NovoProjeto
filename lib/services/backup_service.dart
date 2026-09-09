import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'database_service.dart';

class BackupService {
  final DatabaseService db;
  BackupService(this.db);

  static const tables = [
    'classrooms',
    'students',
    'lessons',
    'attendance',
    'contents',
    'lesson_plans',
    'student_notes',
    'attachments',
  ];

  Future<File> exportJson() async {
    final data = <String, dynamic>{
      'app': 'Aula Fácil',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    for (final table in tables) {
      data[table] = await db.dumpTable(table);
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/aula_facil_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  Future<void> restoreJson(File file) async {
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Arquivo de backup inválido.');
    }
    if (raw['app'] != null && raw['app'] != 'Aula Fácil') {
      throw const FormatException('Este arquivo não é um backup do Aula Fácil.');
    }
    if (!raw.containsKey('classrooms') || !raw.containsKey('students')) {
      throw const FormatException('Backup incompleto ou incompatível.');
    }
    await db.replaceFromBackup(raw);
  }
}
