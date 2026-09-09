import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'screens1.dart';
part 'screens2.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final store = AppStore();
  await store.load();
  runApp(ChangeNotifierProvider.value(value: store, child: const AulaFacilApp()));
}

class AulaFacilApp extends StatelessWidget {
  const AulaFacilApp({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppStore>().dark;
    const seed = Color(0xFF8A3A58);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aula Fácil',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFFFF8FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark)),
      home: const MainShell(),
    );
  }
}

String id() => DateTime.now().microsecondsSinceEpoch.toString();
String brDate(String iso) {
  try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso)); } catch (_) { return iso; }
}
String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());
const weekNames = ['', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];

class AppStore extends ChangeNotifier {
  static const _key = 'aula_facil_data_v1';
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> lessons = [];
  String teacher = 'Professor';
  bool dark = false;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    teacher = p.getString('teacher') ?? 'Professor';
    dark = p.getBool('dark') ?? false;
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        classes = List<Map<String, dynamic>>.from((data['classes'] ?? []).map((e) => Map<String, dynamic>.from(e)));
        students = List<Map<String, dynamic>>.from((data['students'] ?? []).map((e) => Map<String, dynamic>.from(e)));
        lessons = List<Map<String, dynamic>>.from((data['lessons'] ?? []).map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode({'classes': classes, 'students': students, 'lessons': lessons}));
    await p.setString('teacher', teacher);
    await p.setBool('dark', dark);
    notifyListeners();
  }

  List<Map<String, dynamic>> studentsOf(String classId) => students.where((s) => s['classId'] == classId && s['active'] != false).toList()..sort((a,b)=>'${a['name']}'.compareTo('${b['name']}'));
  List<Map<String, dynamic>> lessonsOf(String classId) => lessons.where((l) => l['classId'] == classId).toList()..sort((a,b)=>'${b['date']}'.compareTo('${a['date']}'));

  Future<void> upsertClass(Map<String, dynamic> item) async {
    final i = classes.indexWhere((x) => x['id'] == item['id']);
    if (i < 0) classes.add(item); else classes[i] = item;
    await save();
  }
  Future<void> archiveClass(String classId) async {
    final i = classes.indexWhere((x) => x['id'] == classId);
    if (i >= 0) classes[i]['archived'] = true;
    await save();
  }
  Future<void> upsertStudent(Map<String, dynamic> item) async {
    final i = students.indexWhere((x) => x['id'] == item['id']);
    if (i < 0) students.add(item); else students[i] = item;
    await save();
  }
  Future<void> deactivateStudent(String studentId) async {
    final i = students.indexWhere((x) => x['id'] == studentId);
    if (i >= 0) students[i]['active'] = false;
    await save();
  }
  Future<void> saveLesson(Map<String, dynamic> item) async {
    final i = lessons.indexWhere((x) => x['id'] == item['id']);
    if (i < 0) lessons.add(item); else lessons[i] = item;
    await save();
  }
  Future<void> deleteLesson(String lessonId) async { lessons.removeWhere((x)=>x['id']==lessonId); await save(); }

  Map<String, int> attendanceForStudent(String studentId) {
    var p=0, a=0, j=0;
    for (final l in lessons) {
      final at = Map<String, dynamic>.from(l['attendance'] ?? {});
      if (at[studentId] == 'present') p++;
      if (at[studentId] == 'absent') a++;
      if (at[studentId] == 'justified') j++;
    }
    return {'present':p,'absent':a,'justified':j,'total':p+a+j};
  }
}

class MainShell extends StatefulWidget { const MainShell({super.key}); @override State<MainShell> createState()=>_MainShellState(); }
class _MainShellState extends State<MainShell> {
  int index=0;
  final pages = const [HomeScreen(), ClassesScreen(), CalendarScreen(), ReportsScreen(), ProfileScreen()];
  @override Widget build(BuildContext context)=>Scaffold(
    body: SafeArea(child: IndexedStack(index:index, children:pages)),
    bottomNavigationBar: NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const [
      NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Início'),
      NavigationDestination(icon:Icon(Icons.groups_outlined),selectedIcon:Icon(Icons.groups),label:'Turmas'),
      NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'Calendário'),
      NavigationDestination(icon:Icon(Icons.bar_chart_outlined),label:'Relatórios'),
      NavigationDestination(icon:Icon(Icons.person_outline),label:'Perfil'),
    ]),
  );
}

class PagePad extends StatelessWidget { final Widget child; const PagePad({super.key,required this.child}); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(16,18,16,12),child:child); }
class SectionTitle extends StatelessWidget { final String text; const SectionTitle(this.text,{super.key}); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:10,top:4),child:Text(text,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800))); }
