class Lesson {
  final int? id;
  final int classroomId;
  final String date;
  final String startTime;
  final String endTime;
  final String content;
  final String activities;
  final String observations;
  final int? planId;
  final int synced;

  const Lesson({this.id,required this.classroomId,required this.date,required this.startTime,required this.endTime,this.content='',this.activities='',this.observations='',this.planId,this.synced=0});
  Map<String,dynamic> toMap()=>{'id':id,'classroom_id':classroomId,'date':date,'start_time':startTime,'end_time':endTime,'content':content,'activities':activities,'observations':observations,'plan_id':planId,'synced':synced};
  factory Lesson.fromMap(Map<String,dynamic> m)=>Lesson(id:m['id'],classroomId:m['classroom_id'],date:m['date']??'',startTime:m['start_time']??'',endTime:m['end_time']??'',content:m['content']??'',activities:m['activities']??'',observations:m['observations']??'',planId:m['plan_id'],synced:m['synced']??0);
}
