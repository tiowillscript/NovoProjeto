import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/classroom.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../utils/date_utils.dart';
import 'database_service.dart';

class ReportService {
  final DatabaseService db;
  ReportService(this.db);

  Future<File> frequencyPdf(
    Classroom classroom, {
    String teacherName = 'Professor',
  }) async {
    final data = await db.frequencyForClass(classroom.id!);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(
          'RELATÓRIO DE FREQUÊNCIA',
          classroom.name,
          teacherName,
        ),
        footer: _footer,
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Aluno',
              'Presenças',
              'Faltas',
              'Justificadas',
              'Frequência',
            ],
            data: data.values.map((row) {
              final total = (row['total'] as num?)?.toInt() ?? 0;
              final presents = (row['presents'] as num?)?.toInt() ?? 0;
              return [
                row['full_name'],
                '$presents',
                '${row['absents'] ?? 0}',
                '${row['justified'] ?? 0}',
                total == 0
                    ? '—'
                    : '${(presents / total * 100).toStringAsFixed(1)}%',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Gerado em ${displayDate(DateTime.now().toIso8601String())}'),
        ],
      ),
    );

    return _write(pdf, 'frequencia_${classroom.id}.pdf');
  }

  Future<File> classroomPdf(
    Classroom classroom, {
    required String teacherName,
  }) async {
    final students = await db.students(classroomId: classroom.id);
    final lessons = await db.lessons(classroomId: classroom.id);
    final frequency = await db.frequencyForClass(classroom.id!);
    final counts = await db.attendanceCountsByLesson();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(
          'RELATÓRIO DA TURMA',
          classroom.name,
          teacherName,
        ),
        footer: _footer,
        build: (ctx) => [
          _infoTable([
            ['Dia', weekdayName(classroom.weekday)],
            ['Horário', '${classroom.startTime} — ${classroom.endTime}'],
            ['Local', classroom.location.isEmpty ? 'Não informado' : classroom.location],
            ['Período', _period(classroom.startDate, classroom.endDate)],
            ['Alunos', '${students.where((s) => s.active).length} ativos'],
            ['Aulas registradas', '${lessons.length}'],
          ]),
          pw.SizedBox(height: 18),
          _title('Frequência dos alunos'),
          pw.TableHelper.fromTextArray(
            headers: const ['Aluno', 'Pres.', 'Faltas', 'Just.', 'Freq.'],
            data: frequency.values.map((row) {
              final total = (row['total'] as num?)?.toInt() ?? 0;
              final presents = (row['presents'] as num?)?.toInt() ?? 0;
              return [
                row['full_name'],
                '$presents',
                '${row['absents'] ?? 0}',
                '${row['justified'] ?? 0}',
                total == 0 ? '—' : '${(presents / total * 100).toStringAsFixed(1)}%',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 22),
          _title('Aulas e conteúdos'),
          if (lessons.isEmpty)
            pw.Text('Nenhuma aula registrada.')
          else
            ...lessons.map((lesson) {
              final c = counts[lesson.id] ?? const {
                'presents': 0,
                'absents': 0,
                'justified': 0,
              };
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(9),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${displayDate(lesson.date)} • ${lesson.startTime} — ${lesson.endTime}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${c['presents']} presentes • ${c['absents']} faltas • ${c['justified']} justificadas',
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Conteúdo: ${lesson.content.isEmpty ? 'Não informado' : lesson.content}',
                    ),
                    if (lesson.activities.isNotEmpty)
                      pw.Text('Atividades: ${lesson.activities}'),
                    if (lesson.observations.isNotEmpty)
                      pw.Text('Observações: ${lesson.observations}'),
                  ],
                ),
              );
            }),
        ],
      ),
    );

    return _write(pdf, 'turma_${classroom.id}.pdf');
  }

  Future<File> studentPdf(
    Student student,
    Classroom classroom, {
    required String teacherName,
  }) async {
    final history = await db.studentAttendanceHistory(student.id!);
    final notes = await db.studentNotes(student.id!);
    final total = history.length;
    final presents = history.where((x) => x['status'] == 'present').length;
    final absents = history.where((x) => x['status'] == 'absent').length;
    final justified = history.where((x) => x['status'] == 'justified').length;
    final percent = total == 0 ? 0.0 : presents / total * 100;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(
          'RELATÓRIO INDIVIDUAL DO ALUNO',
          classroom.name,
          teacherName,
        ),
        footer: _footer,
        build: (ctx) => [
          pw.Text(
            student.fullName,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (student.socialName.isNotEmpty) pw.Text('Nome social: ${student.socialName}'),
          pw.SizedBox(height: 12),
          _infoTable([
            ['Aulas', '$total'],
            ['Presenças', '$presents'],
            ['Faltas', '$absents'],
            ['Justificadas', '$justified'],
            ['Frequência', total == 0 ? '—' : '${percent.toStringAsFixed(1)}%'],
          ]),
          pw.SizedBox(height: 18),
          _title('Histórico de frequência'),
          if (history.isEmpty)
            pw.Text('Nenhum registro de frequência.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Data', 'Conteúdo', 'Status', 'Justificativa'],
              data: history.map((row) => [
                displayDate('${row['date'] ?? ''}'),
                _short('${row['content'] ?? ''}', 55),
                _attendanceLabel('${row['status'] ?? ''}'),
                _short('${row['note'] ?? ''}', 45),
              ]).toList(),
            ),
          pw.SizedBox(height: 18),
          _title('Observações do aluno'),
          if (notes.isEmpty)
            pw.Text('Nenhuma observação registrada.')
          else
            ...notes.map(
              (note) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Text(
                  '${displayDate('${note['date'] ?? ''}')} — ${note['note'] ?? ''}',
                ),
              ),
            ),
        ],
      ),
    );

    return _write(pdf, 'aluno_${student.id}.pdf');
  }

  Future<File> monthlyPdf({
    required List<Classroom> classrooms,
    required List<Student> students,
    required List<Lesson> lessons,
    required String teacherName,
    required DateTime month,
  }) async {
    final prefix = '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final monthLessons = lessons.where((l) => l.date.startsWith(prefix)).toList();
    final counts = await db.attendanceCountsByLesson();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(
          'RELATÓRIO MENSAL',
          '${month.month.toString().padLeft(2, '0')}/${month.year}',
          teacherName,
        ),
        footer: _footer,
        build: (ctx) => [
          _infoTable([
            ['Turmas ativas', '${classrooms.length}'],
            ['Alunos ativos', '${students.where((s) => s.active).length}'],
            ['Aulas realizadas no mês', '${monthLessons.length}'],
          ]),
          pw.SizedBox(height: 18),
          _title('Aulas do mês'),
          if (monthLessons.isEmpty)
            pw.Text('Nenhuma aula registrada neste mês.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Data', 'Turma', 'Pres.', 'Faltas', 'Conteúdo'],
              data: monthLessons.map((lesson) {
                final classroom = classrooms.where((c) => c.id == lesson.classroomId).firstOrNull;
                final c = counts[lesson.id] ?? const {'presents': 0, 'absents': 0};
                return [
                  displayDate(lesson.date),
                  classroom?.name ?? 'Turma',
                  '${c['presents'] ?? 0}',
                  '${c['absents'] ?? 0}',
                  _short(lesson.content, 70),
                ];
              }).toList(),
            ),
        ],
      ),
    );

    return _write(
      pdf,
      'mensal_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  Future<File> classCsv(Classroom classroom) async {
    final data = await db.frequencyForClass(classroom.id!);
    final rows = <List<dynamic>>[
      ['Aluno', 'Presenças', 'Faltas', 'Justificadas', 'Total', 'Frequência'],
    ];

    for (final row in data.values) {
      final total = (row['total'] as num?)?.toInt() ?? 0;
      final presents = (row['presents'] as num?)?.toInt() ?? 0;
      rows.add([
        row['full_name'],
        presents,
        row['absents'] ?? 0,
        row['justified'] ?? 0,
        total,
        total == 0 ? '' : (presents / total * 100).toStringAsFixed(1),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/frequencia_${classroom.id}.csv');
    await file.writeAsString(
      const ListToCsvConverter(fieldDelimiter: ';').convert(rows),
    );
    return file;
  }

  Future<File> classExcel(Classroom classroom) async {
    final data = await db.frequencyForClass(classroom.id!);
    final excel = Excel.createExcel();
    final sheet = excel['Frequência'];

    sheet.appendRow([
      TextCellValue('Aluno'),
      TextCellValue('Presenças'),
      TextCellValue('Faltas'),
      TextCellValue('Justificadas'),
      TextCellValue('Total'),
      TextCellValue('Frequência'),
    ]);

    for (final row in data.values) {
      final total = (row['total'] as num?)?.toInt() ?? 0;
      final presents = (row['presents'] as num?)?.toInt() ?? 0;
      sheet.appendRow([
        TextCellValue('${row['full_name']}'),
        IntCellValue(presents),
        IntCellValue((row['absents'] as num?)?.toInt() ?? 0),
        IntCellValue((row['justified'] as num?)?.toInt() ?? 0),
        IntCellValue(total),
        TextCellValue(
          total == 0 ? '' : '${(presents / total * 100).toStringAsFixed(1)}%',
        ),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/frequencia_${classroom.id}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  pw.Widget _header(String title, String subtitle, String teacherName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17),
        ),
        pw.Text(subtitle),
        pw.Text('Professor: $teacherName', style: const pw.TextStyle(fontSize: 9)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      );

  pw.Widget _title(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _infoTable(List<List<String>> rows) => pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: rows
            .map(
              (row) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      row[0],
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(row[1]),
                  ),
                ],
              ),
            )
            .toList(),
      );

  String _period(String start, String? end) {
    final a = start.isEmpty ? '—' : displayDate(start);
    final b = end == null || end.isEmpty ? 'em andamento' : displayDate(end);
    return '$a a $b';
  }

  String _short(String value, int max) {
    if (value.isEmpty) return '—';
    return value.length <= max ? value : '${value.substring(0, max - 1)}…';
  }

  String _attendanceLabel(String value) => switch (value) {
        'present' => 'Presente',
        'absent' => 'Falta',
        'justified' => 'Justificada',
        _ => value,
      };

  Future<File> _write(pw.Document pdf, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
