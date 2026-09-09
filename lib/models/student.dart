class Student {
  final int? id;
  final int classroomId;
  final String fullName;
  final String socialName;
  final String birthDate;
  final String phone;
  final String email;
  final String guardian;
  final String guardianPhone;
  final String entryDate;
  final bool active;
  final String notes;
  final String? photoPath;

  const Student({this.id,required this.classroomId,required this.fullName,this.socialName='',this.birthDate='',this.phone='',this.email='',this.guardian='',this.guardianPhone='',required this.entryDate,this.active=true,this.notes='',this.photoPath});
  Map<String,dynamic> toMap()=>{'id':id,'classroom_id':classroomId,'full_name':fullName,'social_name':socialName,'birth_date':birthDate,'phone':phone,'email':email,'guardian':guardian,'guardian_phone':guardianPhone,'entry_date':entryDate,'active':active?1:0,'notes':notes,'photo_path':photoPath};
  factory Student.fromMap(Map<String,dynamic> m)=>Student(id:m['id'],classroomId:m['classroom_id'],fullName:m['full_name']??'',socialName:m['social_name']??'',birthDate:m['birth_date']??'',phone:m['phone']??'',email:m['email']??'',guardian:m['guardian']??'',guardianPhone:m['guardian_phone']??'',entryDate:m['entry_date']??'',active:(m['active']??1)==1,notes:m['notes']??'',photoPath:m['photo_path']);
}
