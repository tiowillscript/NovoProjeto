import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/classroom.dart';
import '../models/content_item.dart';
import '../models/lesson.dart';
import '../models/lesson_plan.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  final db = DatabaseService.instance;
  final auth = AuthService();
  late final SyncService syncService = SyncService(db);
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;

  List<Classroom> classes = [];
  List<Student> allStudents = [];
  List<Lesson> allLessons = [];
  List<ContentItem> contents = [];
  List<LessonPlan> plans = [];
  bool loading = true;
  bool dark = false;
  String teacherName = 'Professor';
  DateTime? lastSync;
  Map<String,dynamic> dashboard = const {
    'students':0,
    'monthLessons':0,
    'frequency':0.0,
    'recentAbsences':0,
  };

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await auth.initialize();
    await NotificationService.instance.initialize();
    final prefs = await SharedPreferences.getInstance();
    dark = prefs.getBool('dark') ?? false;
    teacherName = prefs.getString('teacherName') ?? 'Professor';
    lastSync = DateTime.tryParse(prefs.getString('lastSync') ?? '');
    await reload();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _tryAutoSync();
      }
    });
    _tryAutoSync();
  }

  Future<void> reload() async {
    loading = true;
    notifyListeners();
    classes = await db.classrooms();
    allStudents = await db.students();
    allLessons = await db.lessons();
    contents = await db.contents();
    plans = await db.plans();
    dashboard = await db.dashboardStats();
    await NotificationService.instance.rescheduleFromPreferences(classes);
    loading = false;
    notifyListeners();
  }

  Future<void> saveClass(Classroom classroom) async {
    await db.saveClassroom(classroom);
    await reload();
    _tryAutoSync();
  }

  Future<void> archiveClass(int id) async {
    await db.archiveClassroom(id);
    await reload();
    _tryAutoSync();
  }

  Future<void> unarchiveClass(int id) async {
    await db.unarchiveClassroom(id);
    await reload();
    _tryAutoSync();
  }

  Future<void> saveStudent(Student student) async {
    await db.saveStudent(student);
    await reload();
    _tryAutoSync();
  }

  Future<void> deactivateStudent(int id) async {
    await db.deleteStudent(id);
    await reload();
    _tryAutoSync();
  }

  Future<int> saveLesson(Lesson lesson) async {
    final id = await db.saveLesson(lesson);
    await reload();
    _tryAutoSync();
    return id;
  }

  Future<void> deleteLesson(int id) async {
    await db.deleteLesson(id);
    await reload();
    _tryAutoSync();
  }

  Future<void> saveContent(ContentItem content) async {
    await db.saveContent(content);
    await reload();
    _tryAutoSync();
  }

  Future<void> deleteContent(int id) async {
    await db.deleteContent(id);
    await reload();
    _tryAutoSync();
  }

  Future<void> savePlan(LessonPlan plan) async {
    await db.savePlan(plan);
    await reload();
    _tryAutoSync();
  }

  Future<void> deletePlan(int id) async {
    await db.deletePlan(id);
    await reload();
    _tryAutoSync();
  }

  Future<void> setDark(bool value) async {
    dark = value;
    await (await SharedPreferences.getInstance()).setBool('dark', value);
    notifyListeners();
  }

  Future<void> setTeacherName(String value) async {
    teacherName = value;
    await (await SharedPreferences.getInstance()).setString('teacherName', value);
    notifyListeners();
  }

  Future<String> sync() async {
    if (_syncing) return 'Já existe uma sincronização em andamento.';
    if (!auth.firebaseReady) {
      return 'Firebase ainda não foi configurado. O modo local continua funcionando normalmente.';
    }
    if (auth.user == null) {
      return 'Faça login com sua conta Firebase para sincronizar.';
    }
    _syncing = true;
    final message = await syncService.sync();
    _syncing = false;
    if (message.startsWith('Sincronização concluída')) {
      lastSync = DateTime.now();
      await (await SharedPreferences.getInstance())
          .setString('lastSync', lastSync!.toIso8601String());
      notifyListeners();
    }
    return message;
  }

  Future<void> _tryAutoSync() async {
    if (_syncing || !auth.firebaseReady || auth.user == null) return;
    final results = await Connectivity().checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) return;
    await sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tryAutoSync();
  }

  Classroom? get nextClass {
    if (classes.isEmpty) return null;
    final now = DateTime.now();
    final sorted = [...classes]
      ..sort((a, b) {
        final da = (a.weekday - now.weekday) % 7;
        final db = (b.weekday - now.weekday) % 7;
        if (da != db) return da.compareTo(db);
        return a.startTime.compareTo(b.startTime);
      });
    return sorted.first;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    super.dispose();
  }
}
