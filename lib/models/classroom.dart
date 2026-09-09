class Classroom {
  final int? id;
  final String name;
  final int weekday; // DateTime.monday..sunday
  final String startTime;
  final String endTime;
  final String location;
  final String teacher;
  final String startDate;
  final String? endDate;
  final String description;
  final bool archived;

  const Classroom({this.id, required this.name, required this.weekday, required this.startTime, required this.endTime, this.location='', this.teacher='', required this.startDate, this.endDate, this.description='', this.archived=false});

  Map<String,dynamic> toMap()=>{'id':id,'name':name,'weekday':weekday,'start_time':startTime,'end_time':endTime,'location':location,'teacher':teacher,'start_date':startDate,'end_date':endDate,'description':description,'archived':archived?1:0};
  factory Classroom.fromMap(Map<String,dynamic> m)=>Classroom(id:m['id'] as int?,name:m['name']??'',weekday:m['weekday']??1,startTime:m['start_time']??'',endTime:m['end_time']??'',location:m['location']??'',teacher:m['teacher']??'',startDate:m['start_date']??'',endDate:m['end_date'],description:m['description']??'',archived:(m['archived']??0)==1);
  Classroom copyWith({int? id,String? name,int? weekday,String? startTime,String? endTime,String? location,String? teacher,String? startDate,String? endDate,String? description,bool? archived})=>Classroom(id:id??this.id,name:name??this.name,weekday:weekday??this.weekday,startTime:startTime??this.startTime,endTime:endTime??this.endTime,location:location??this.location,teacher:teacher??this.teacher,startDate:startDate??this.startDate,endDate:endDate??this.endDate,description:description??this.description,archived:archived??this.archived);
}
