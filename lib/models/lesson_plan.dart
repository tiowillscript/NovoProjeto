class LessonPlan {
  final int? id; final int? classroomId; final String title; final String module; final String description; final String objectives; final String content; final String activity; final int durationMinutes; final String status;
  const LessonPlan({this.id,this.classroomId,required this.title,this.module='',this.description='',this.objectives='',this.content='',this.activity='',this.durationMinutes=120,this.status='Planejada'});
  Map<String,dynamic> toMap()=>{'id':id,'classroom_id':classroomId,'title':title,'module':module,'description':description,'objectives':objectives,'content':content,'activity':activity,'duration_minutes':durationMinutes,'status':status};
  factory LessonPlan.fromMap(Map<String,dynamic> m)=>LessonPlan(id:m['id'],classroomId:m['classroom_id'],title:m['title']??'',module:m['module']??'',description:m['description']??'',objectives:m['objectives']??'',content:m['content']??'',activity:m['activity']??'',durationMinutes:m['duration_minutes']??120,status:m['status']??'Planejada');
}
