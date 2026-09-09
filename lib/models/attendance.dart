enum AttendanceStatus { present, absent, justified }

class AttendanceRecord {
  final int? id;
  final int lessonId;
  final int studentId;
  final AttendanceStatus status;
  final String note;
  const AttendanceRecord({this.id,required this.lessonId,required this.studentId,required this.status,this.note=''});
  Map<String,dynamic> toMap()=>{'id':id,'lesson_id':lessonId,'student_id':studentId,'status':status.name,'note':note};
  factory AttendanceRecord.fromMap(Map<String,dynamic> m)=>AttendanceRecord(id:m['id'],lessonId:m['lesson_id'],studentId:m['student_id'],status:AttendanceStatus.values.firstWhere((e)=>e.name==(m['status']??'present'),orElse:()=>AttendanceStatus.present),note:m['note']??'');
}
