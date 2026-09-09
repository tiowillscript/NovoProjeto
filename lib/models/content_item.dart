class ContentItem {
  final int? id; final String title; final String category; final String description;
  const ContentItem({this.id,required this.title,required this.category,this.description=''});
  Map<String,dynamic> toMap()=>{'id':id,'title':title,'category':category,'description':description};
  factory ContentItem.fromMap(Map<String,dynamic> m)=>ContentItem(id:m['id'],title:m['title']??'',category:m['category']??'Outros',description:m['description']??'');
}
