import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/classroom.dart';
import '../models/student.dart';
import '../models/lesson.dart';
import '../models/attendance.dart';
import '../models/content_item.dart';
import '../models/lesson_plan.dart';
import '../utils/date_utils.dart';

class DatabaseService {
  DatabaseService._(); static final instance=DatabaseService._(); Database? _db;
  Future<Database> get db async=>_db??=await _open();
  Future<Database> _open() async {
    final path=join(await getDatabasesPath(),'aula_facil.db');
    return openDatabase(path,version:2,onConfigure:(db)=>db.execute('PRAGMA foreign_keys = ON'),onCreate:(db,v) async {
      await db.execute('CREATE TABLE classrooms(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,weekday INTEGER NOT NULL,start_time TEXT,end_time TEXT,location TEXT,teacher TEXT,start_date TEXT,end_date TEXT,description TEXT,archived INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE students(id INTEGER PRIMARY KEY AUTOINCREMENT,classroom_id INTEGER NOT NULL,full_name TEXT NOT NULL,social_name TEXT,birth_date TEXT,phone TEXT,email TEXT,guardian TEXT,guardian_phone TEXT,entry_date TEXT,active INTEGER DEFAULT 1,notes TEXT,photo_path TEXT,FOREIGN KEY(classroom_id) REFERENCES classrooms(id))');
      await db.execute('CREATE TABLE lessons(id INTEGER PRIMARY KEY AUTOINCREMENT,classroom_id INTEGER NOT NULL,date TEXT NOT NULL,start_time TEXT,end_time TEXT,content TEXT,activities TEXT,observations TEXT,plan_id INTEGER,synced INTEGER DEFAULT 0,FOREIGN KEY(classroom_id) REFERENCES classrooms(id))');
      await db.execute('CREATE TABLE attendance(id INTEGER PRIMARY KEY AUTOINCREMENT,lesson_id INTEGER NOT NULL,student_id INTEGER NOT NULL,status TEXT NOT NULL,note TEXT,UNIQUE(lesson_id,student_id),FOREIGN KEY(lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,FOREIGN KEY(student_id) REFERENCES students(id))');
      await db.execute('CREATE TABLE contents(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,category TEXT,description TEXT)');
      await db.execute('CREATE TABLE lesson_plans(id INTEGER PRIMARY KEY AUTOINCREMENT,classroom_id INTEGER,title TEXT NOT NULL,module TEXT,description TEXT,objectives TEXT,content TEXT,activity TEXT,duration_minutes INTEGER,status TEXT,FOREIGN KEY(classroom_id) REFERENCES classrooms(id))');
      await db.execute('CREATE TABLE student_notes(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL,date TEXT NOT NULL,note TEXT NOT NULL,FOREIGN KEY(student_id) REFERENCES students(id))');
      await db.execute('CREATE TABLE attachments(id INTEGER PRIMARY KEY AUTOINCREMENT,lesson_id INTEGER NOT NULL,name TEXT NOT NULL,path TEXT NOT NULL,mime_type TEXT,FOREIGN KEY(lesson_id) REFERENCES lessons(id) ON DELETE CASCADE)');
      await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT)');
    },onUpgrade:(db,oldVersion,newVersion) async {
      if(oldVersion<2){
        await db.execute('CREATE TABLE IF NOT EXISTS attachments(id INTEGER PRIMARY KEY AUTOINCREMENT,lesson_id INTEGER NOT NULL,name TEXT NOT NULL,path TEXT NOT NULL,mime_type TEXT,FOREIGN KEY(lesson_id) REFERENCES lessons(id) ON DELETE CASCADE)');
      }
    });
  }

  Future<List<Classroom>> classrooms({bool includeArchived=false}) async { final d=await db; final rows=await d.query('classrooms',where:includeArchived?null:'archived=0',orderBy:'name'); return rows.map(Classroom.fromMap).toList(); }
  Future<int> saveClassroom(Classroom c) async { final d=await db; final m=c.toMap()..remove('id'); return c.id==null?d.insert('classrooms',m):((await d.update('classrooms',m,where:'id=?',whereArgs:[c.id]))>0?c.id!:0); }
  Future<void> archiveClassroom(int id) async {await (await db).update('classrooms',{'archived':1},where:'id=?',whereArgs:[id]);}
  Future<void> unarchiveClassroom(int id) async {await (await db).update('classrooms',{'archived':0},where:'id=?',whereArgs:[id]);}
  Future<void> deleteClassroom(int id) async {await (await db).delete('classrooms',where:'id=?',whereArgs:[id]);}

  Future<List<Student>> students({int? classroomId,bool activeOnly=false}) async { final d=await db; final cond=<String>[]; final args=<Object?>[]; if(classroomId!=null){cond.add('classroom_id=?');args.add(classroomId);} if(activeOnly)cond.add('active=1'); final rows=await d.query('students',where:cond.isEmpty?null:cond.join(' AND '),whereArgs:args.isEmpty?null:args,orderBy:'full_name'); return rows.map(Student.fromMap).toList(); }
  Future<int> saveStudent(Student s) async { final d=await db; final m=s.toMap()..remove('id'); return s.id==null?d.insert('students',m):((await d.update('students',m,where:'id=?',whereArgs:[s.id]))>0?s.id!:0); }
  Future<void> deleteStudent(int id) async {await (await db).update('students',{'active':0},where:'id=?',whereArgs:[id]);}

  Future<List<Lesson>> lessons({int? classroomId}) async { final d=await db; final rows=await d.query('lessons',where:classroomId==null?null:'classroom_id=?',whereArgs:classroomId==null?null:[classroomId],orderBy:'date DESC, id DESC'); return rows.map(Lesson.fromMap).toList(); }
  Future<int> saveLesson(Lesson l) async { final d=await db; final m=l.toMap()..remove('id'); return l.id==null?d.insert('lessons',m):((await d.update('lessons',m,where:'id=?',whereArgs:[l.id]))>0?l.id!:0); }
  Future<void> deleteLesson(int id) async {await (await db).delete('lessons',where:'id=?',whereArgs:[id]);}

  Future<List<AttendanceRecord>> attendance(int lessonId) async { final rows=await (await db).query('attendance',where:'lesson_id=?',whereArgs:[lessonId]); return rows.map(AttendanceRecord.fromMap).toList(); }
  Future<void> saveAttendance(AttendanceRecord a) async { final d=await db; final m=a.toMap()..remove('id'); await d.insert('attendance',m,conflictAlgorithm:ConflictAlgorithm.replace); }

  Future<List<ContentItem>> contents() async =>(await (await db).query('contents',orderBy:'category,title')).map(ContentItem.fromMap).toList();
  Future<int> saveContent(ContentItem c) async {final d=await db; final m=c.toMap()..remove('id'); return c.id==null?d.insert('contents',m):((await d.update('contents',m,where:'id=?',whereArgs:[c.id]))>0?c.id!:0);}
  Future<void> deleteContent(int id) async {await (await db).delete('contents',where:'id=?',whereArgs:[id]);}

  Future<List<LessonPlan>> plans() async =>(await (await db).query('lesson_plans',orderBy:'module,title')).map(LessonPlan.fromMap).toList();
  Future<int> savePlan(LessonPlan p) async {final m=p.toMap()..remove('id'); return p.id==null?(await db).insert('lesson_plans',m):((await (await db).update('lesson_plans',m,where:'id=?',whereArgs:[p.id]))>0?p.id!:0);}
  Future<void> deletePlan(int id) async {await (await db).delete('lesson_plans',where:'id=?',whereArgs:[id]);}

  Future<void> addStudentNote(int studentId,String date,String note) async {await (await db).insert('student_notes',{'student_id':studentId,'date':date,'note':note});}
  Future<List<Map<String,dynamic>>> studentNotes(int studentId) async=>(await db).query('student_notes',where:'student_id=?',whereArgs:[studentId],orderBy:'date DESC,id DESC');

  Future<List<Map<String,dynamic>>> studentAttendanceHistory(int studentId) async {
    return (await db).rawQuery(
      "SELECT l.id AS lesson_id,l.date,l.content,l.start_time,l.end_time,a.status,a.note "
      "FROM attendance a JOIN lessons l ON l.id=a.lesson_id "
      "WHERE a.student_id=? ORDER BY l.date DESC,l.id DESC",
      [studentId],
    );
  }

  Future<Map<int,Map<String,int>>> attendanceCountsByLesson() async {
    final rows=await (await db).rawQuery(
      "SELECT lesson_id, "
      "SUM(CASE WHEN status='present' THEN 1 ELSE 0 END) AS presents, "
      "SUM(CASE WHEN status='absent' THEN 1 ELSE 0 END) AS absents, "
      "SUM(CASE WHEN status='justified' THEN 1 ELSE 0 END) AS justified "
      "FROM attendance GROUP BY lesson_id",
    );
    return {
      for(final row in rows)
        row['lesson_id'] as int:{
          'presents':(row['presents'] as num?)?.toInt()??0,
          'absents':(row['absents'] as num?)?.toInt()??0,
          'justified':(row['justified'] as num?)?.toInt()??0,
        }
    };
  }


  Future<Map<String,dynamic>> classStats(int classroomId) async {
    final d=await db;
    final studentsCount=Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM students WHERE classroom_id=? AND active=1',[classroomId]))??0;
    final lessonCount=Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM lessons WHERE classroom_id=?',[classroomId]))??0;
    final counts=await d.rawQuery('SELECT SUM(CASE WHEN a.status="present" THEN 1 ELSE 0 END) p, COUNT(a.id) t FROM attendance a JOIN lessons l ON l.id=a.lesson_id WHERE l.classroom_id=?',[classroomId]);
    final p=(counts.first['p'] as num?)?.toDouble()??0; final t=(counts.first['t'] as num?)?.toDouble()??0;
    return {'students':studentsCount,'lessons':lessonCount,'frequency':t==0?0.0:p/t*100};
  }

  Future<Map<String,dynamic>> dashboardStats() async {
    final d=await db;
    final now=DateTime.now();
    final monthPrefix='${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}%';
    final students=Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM students WHERE active=1'))??0;
    final monthLessons=Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM lessons WHERE date LIKE ?',[monthPrefix]))??0;
    final attendance=await d.rawQuery(
      "SELECT SUM(CASE WHEN status='present' THEN 1 ELSE 0 END) AS presents, COUNT(*) AS total FROM attendance",
    );
    final presents=(attendance.first['presents'] as num?)?.toDouble()??0;
    final total=(attendance.first['total'] as num?)?.toDouble()??0;
    final recentLimit=isoDate(DateTime.now().subtract(const Duration(days:30)));
    final recentAbsences=Sqflite.firstIntValue(await d.rawQuery(
      "SELECT COUNT(*) FROM attendance a JOIN lessons l ON l.id=a.lesson_id WHERE a.status='absent' AND l.date>=?",
      [recentLimit],
    ))??0;
    return {
      'students':students,
      'monthLessons':monthLessons,
      'frequency':total==0?0.0:presents/total*100,
      'recentAbsences':recentAbsences,
    };
  }

  Future<Map<int,Map<String,dynamic>>> frequencyForClass(int classroomId) async {
    final d=await db;
    final rows=await d.rawQuery("SELECT s.id,s.full_name, "
      "SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END) AS presents, "
      "SUM(CASE WHEN a.status='absent' THEN 1 ELSE 0 END) AS absents, "
      "SUM(CASE WHEN a.status='justified' THEN 1 ELSE 0 END) AS justified, "
      "COUNT(a.id) AS total "
      "FROM students s LEFT JOIN attendance a ON a.student_id=s.id LEFT JOIN lessons l ON l.id=a.lesson_id "
      "WHERE s.classroom_id=? AND s.active=1 GROUP BY s.id ORDER BY s.full_name",[classroomId]);
    return {for(final r in rows) r['id'] as int:r};
  }

  Future<List<Map<String,dynamic>>> globalSearch(String q) async {
    final d=await db; final like='%$q%';
    final out=<Map<String,dynamic>>[];
    for(final r in await d.rawQuery('SELECT id,full_name AS title,"Aluno" AS type FROM students WHERE full_name LIKE ? LIMIT 15',[like])) out.add(r);
    for(final r in await d.rawQuery('SELECT id,name AS title,"Turma" AS type FROM classrooms WHERE name LIKE ? LIMIT 15',[like])) out.add(r);
    for(final r in await d.rawQuery('SELECT id,content AS title,"Aula" AS type FROM lessons WHERE content LIKE ? LIMIT 15',[like])) out.add(r);
    for(final r in await d.rawQuery('SELECT id,title,"Conteúdo" AS type FROM contents WHERE title LIKE ? LIMIT 15',[like])) out.add(r);
    return out;
  }

  Future<void> addAttachment(int lessonId,String name,String path,{String? mimeType}) async {await (await db).insert('attachments',{'lesson_id':lessonId,'name':name,'path':path,'mime_type':mimeType});}
  Future<List<Map<String,dynamic>>> attachments(int lessonId) async =>(await db).query('attachments',where:'lesson_id=?',whereArgs:[lessonId],orderBy:'id');
  Future<void> deleteAttachment(int id) async {await (await db).delete('attachments',where:'id=?',whereArgs:[id]);}



  Future<void> replaceFromBackup(Map<String,dynamic> backup) async {
    const order = [
      'attendance',
      'attachments',
      'student_notes',
      'lessons',
      'students',
      'lesson_plans',
      'contents',
      'classrooms',
    ];
    const insertOrder = [
      'classrooms',
      'students',
      'contents',
      'lesson_plans',
      'lessons',
      'student_notes',
      'attendance',
      'attachments',
    ];
    final d = await db;
    await d.transaction((txn) async {
      for (final table in order) {
        await txn.delete(table);
      }
      for (final table in insertOrder) {
        final rows = backup[table];
        if (rows is! List) continue;
        for (final raw in rows) {
          if (raw is Map) {
            await txn.insert(
              table,
              Map<String, Object?>.from(raw),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    });
  }

  Future<List<Map<String,Object?>>> dumpTable(String name) async =>(await db).query(name);
  Future<void> markLessonSynced(int id) async {await (await db).update('lessons',{'synced':1},where:'id=?',whereArgs:[id]);}
}
