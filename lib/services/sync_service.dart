import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_service.dart';

class SyncService {
  final DatabaseService db;
  SyncService(this.db);

  Future<String> restoreFromCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Faça login para restaurar dados da nuvem.';
      final base = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final collections = <String, String>{
        'classrooms': 'turmas',
        'students': 'alunos',
        'lessons': 'aulas',
        'attendance': 'frequencias',
        'contents': 'conteudos',
        'lesson_plans': 'planejamentos',
        'student_notes': 'observacoes_alunos',
      };
      final backup = <String, dynamic>{
        'app': 'Aula Fácil',
        'version': 2,
      };
      var total = 0;
      for (final entry in collections.entries) {
        final snapshot = await base.collection(entry.value).get();
        final rows = <Map<String, dynamic>>[];
        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data.remove('syncedAt');
          rows.add(data);
        }
        total += rows.length;
        backup[entry.key] = rows;
      }

      final attachmentSnapshot = await base.collection('anexos').get();
      final attachmentRows = <Map<String, dynamic>>[];
      final documents = await getApplicationDocumentsDirectory();
      final attachmentDir = Directory(p.join(documents.path, 'attachments'));
      await attachmentDir.create(recursive: true);
      for (final doc in attachmentSnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data.remove('syncedAt');
        final url = data.remove('downloadUrl') as String?;
        final name = '${data['name'] ?? 'anexo'}';
        if (url != null && url.isNotEmpty) {
          try {
            final safeName = '${data['id'] ?? doc.id}_$name';
            final target = File(p.join(attachmentDir.path, safeName));
            await FirebaseStorage.instance.refFromURL(url).writeToFile(target);
            data['path'] = target.path;
          } catch (_) {
            data['path'] = '';
          }
        }
        attachmentRows.add(data);
      }
      backup['attachments'] = attachmentRows;
      total += attachmentRows.length;

      if (total == 0) return 'Nenhum dado foi encontrado na nuvem.';
      await db.replaceFromBackup(backup);
      return 'Dados restaurados da nuvem com sucesso.';
    } catch (e) {
      return 'Não foi possível restaurar da nuvem. Detalhes: $e';
    }
  }

  Future<String> sync() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'Usuário não autenticado no Firebase. Os dados continuam seguros no modo local.';
      }

      final base = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final tables = <String, String>{
        'classrooms': 'turmas',
        'students': 'alunos',
        'lessons': 'aulas',
        'attendance': 'frequencias',
        'contents': 'conteudos',
        'lesson_plans': 'planejamentos',
        'student_notes': 'observacoes_alunos',
      };

      for (final entry in tables.entries) {
        final rows = await db.dumpTable(entry.key);
        for (final row in rows) {
          final id = row['id'];
          if (id == null) continue;
          await base.collection(entry.value).doc('$id').set(
                {...row, 'syncedAt': FieldValue.serverTimestamp()},
                SetOptions(merge: true),
              );
        }
      }

      final attachments = await db.dumpTable('attachments');
      for (final row in attachments) {
        final id = row['id'];
        final path = row['path'] as String?;
        if (id == null || path == null) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/${user.uid}/attachments/$id/${row['name']}');
        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        await base.collection('anexos').doc('$id').set(
          {
            ...row,
            'downloadUrl': url,
            'syncedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      final lessons = await db.dumpTable('lessons');
      for (final row in lessons) {
        final id = row['id'];
        if (id is int) await db.markLessonSynced(id);
      }

      await base.set(
        {'lastSync': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return 'Sincronização concluída.';
    } catch (e) {
      return 'Não foi possível sincronizar agora. Seus dados locais foram preservados. Detalhes: $e';
    }
  }
}
