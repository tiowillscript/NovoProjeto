part of 'main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=context.watch<AppStore>();
    final active=s.classes.where((c)=>c['archived']!=true).toList();
    final now=DateTime.now();
    Map<String,dynamic>? next;
    var best=99;
    for(final c in active){final d=((c['weekday']??1) as int-now.weekday)%7; if(d<best){best=d;next=c;}}
    final freqTotals=s.students.where((x)=>x['active']!=false).map((x)=>s.attendanceForStudent('${x['id']}')).toList();
    final p=freqTotals.fold<int>(0,(a,b)=>a+(b['present']??0)); final t=freqTotals.fold<int>(0,(a,b)=>a+(b['total']??0));
    return PagePad(child:ListView(children:[
      Text('Olá, ${s.teacher}!',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),
      Text(DateFormat("EEEE, dd/MM/yyyy",'pt_BR').format(now)), const SizedBox(height:18),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:next==null?const Text('Nenhuma turma ativa cadastrada.'):Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('PRÓXIMA AULA',style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.bold)),const SizedBox(height:8),
        Text('${next['name']}',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
        Text('${weekNames[next['weekday']]} • ${next['start']} — ${next['end']}'),
      ]))),
      const SizedBox(height:14), const SectionTitle('Resumo'),
      GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55,children:[
        StatCard(Icons.groups,'Turmas','${active.length}'), StatCard(Icons.person,'Alunos','${s.students.where((x)=>x['active']!=false).length}'),
        StatCard(Icons.school,'Aulas','${s.lessons.length}'), StatCard(Icons.percent,'Frequência',t==0?'—':'${(p/t*100).toStringAsFixed(0)}%'),
      ]),
      const SizedBox(height:14), const SectionTitle('Últimas aulas'),
      if(s.lessons.isEmpty) const Text('Ainda não há aulas registradas.') else ...([...s.lessons]..sort((a,b)=>'${b['date']}'.compareTo('${a['date']}'))).take(5).map((l){
        final c=s.classes.where((x)=>x['id']==l['classId']).cast<Map<String,dynamic>?>().firstOrNull;
        return Card(child:ListTile(leading:const Icon(Icons.menu_book),title:Text(l['content']?.toString().isNotEmpty==true?'${l['content']}':'Aula registrada'),subtitle:Text('${brDate('${l['date']}')} • ${c?['name']??'Turma'}')));
      }),
    ]));
  }
}

class StatCard extends StatelessWidget { final IconData icon; final String label,value; const StatCard(this.icon,this.label,this.value,{super.key}); @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(icon),const SizedBox(width:10),Expanded(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),Text(label)]))]))); }

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});
  @override Widget build(BuildContext context){ final s=context.watch<AppStore>(); final list=s.classes.where((c)=>c['archived']!=true).toList(); return Scaffold(
    appBar:AppBar(title:const Text('Turmas')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>showClassForm(context),icon:const Icon(Icons.add),label:const Text('Nova turma')),
    body:PagePad(child:list.isEmpty?const Center(child:Text('Cadastre sua primeira turma.')):ListView.separated(itemCount:list.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(ctx,i){final c=list[i]; return Card(child:ListTile(
      leading:CircleAvatar(child:Text('${s.studentsOf('${c['id']}').length}')),title:Text('${c['name']}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${weekNames[c['weekday']]} • ${c['start']} — ${c['end']}'),
      trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ClassDetailScreen(classId:'${c['id']}'))),
    ));})),
  );}
}

Future<void> showClassForm(BuildContext context,[Map<String,dynamic>? old]) async {
  final name=TextEditingController(text:'${old?['name']??''}'); final start=TextEditingController(text:'${old?['start']??'18:00'}'); final end=TextEditingController(text:'${old?['end']??'20:00'}'); final location=TextEditingController(text:'${old?['location']??''}'); var weekday=(old?['weekday']??DateTime.monday) as int;
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(old==null?'Nova turma':'Editar turma'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'Nome da turma')),const SizedBox(height:10),
    DropdownButtonFormField<int>(value:weekday,decoration:const InputDecoration(labelText:'Dia da semana'),items:List.generate(7,(i)=>DropdownMenuItem(value:i+1,child:Text(weekNames[i+1]))),onChanged:(v)=>setD(()=>weekday=v??1)),const SizedBox(height:10),
    Row(children:[Expanded(child:TextField(controller:start,decoration:const InputDecoration(labelText:'Início'))),const SizedBox(width:8),Expanded(child:TextField(controller:end,decoration:const InputDecoration(labelText:'Fim')))]),const SizedBox(height:10),
    TextField(controller:location,decoration:const InputDecoration(labelText:'Local')),
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:(){if(name.text.trim().isEmpty)return; context.read<AppStore>().upsertClass({'id':old?['id']??id(),'name':name.text.trim(),'weekday':weekday,'start':start.text.trim(),'end':end.text.trim(),'location':location.text.trim(),'archived':false});Navigator.pop(ctx);},child:const Text('Salvar'))]))));
}

class ClassDetailScreen extends StatelessWidget { final String classId; const ClassDetailScreen({super.key,required this.classId});
  @override Widget build(BuildContext context){final s=context.watch<AppStore>(); final c=s.classes.where((x)=>x['id']==classId).first; final students=s.studentsOf(classId); final lessons=s.lessonsOf(classId); return Scaffold(appBar:AppBar(title:Text('${c['name']}'),actions:[PopupMenuButton<String>(onSelected:(v){if(v=='edit')showClassForm(context,c); if(v=='archive'){s.archiveClass(classId);Navigator.pop(context);}},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Editar')),PopupMenuItem(value:'archive',child:Text('Arquivar'))])]),body:PagePad(child:ListView(children:[
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${weekNames[c['weekday']]}',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),Text('${c['start']} — ${c['end']}'),if('${c['location']}'.isNotEmpty)Text('${c['location']}'),const SizedBox(height:14),Wrap(spacing:8,runSpacing:8,children:[FilledButton.icon(onPressed:students.isEmpty?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AttendanceScreen(classId:classId))),icon:const Icon(Icons.fact_check),label:const Text('Fazer chamada')),OutlinedButton.icon(onPressed:()=>showStudentForm(context,classId),icon:const Icon(Icons.person_add),label:const Text('Novo aluno')),OutlinedButton.icon(onPressed:()=>showLessonForm(context,classId),icon:const Icon(Icons.menu_book),label:const Text('Registrar aula'))])]))),
    const SectionTitle('Alunos'), if(students.isEmpty)const Text('Nenhum aluno cadastrado.') else ...students.map((st){final f=s.attendanceForStudent('${st['id']}'); final total=f['total']??0; final pct=total==0?null:(f['present']??0)/total*100; return Card(child:ListTile(leading:CircleAvatar(child:Text('${st['name']}'.substring(0,1).toUpperCase())),title:Text('${st['name']}'),subtitle:Text(pct==null?'Sem frequência':'Frequência ${pct.toStringAsFixed(0)}% • ${f['absent']} faltas'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')showStudentForm(context,classId,st);if(v=='remove')s.deactivateStudent('${st['id']}');},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Editar')),PopupMenuItem(value:'remove',child:Text('Inativar'))])));}),
    const SectionTitle('Aulas'), if(lessons.isEmpty)const Text('Nenhuma aula registrada.') else ...lessons.map((l)=>Card(child:ListTile(title:Text(l['content']?.toString().isNotEmpty==true?'${l['content']}':'Aula de ${brDate('${l['date']}')}'),subtitle:Text('${brDate('${l['date']}')} • ${l['activities']??''}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>s.deleteLesson('${l['id']}'))))),
  ])));}
}

Future<void> showStudentForm(BuildContext context,String classId,[Map<String,dynamic>? old]) async {final name=TextEditingController(text:'${old?['name']??''}');final phone=TextEditingController(text:'${old?['phone']??''}');final note=TextEditingController(text:'${old?['note']??''}');await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(old==null?'Novo aluno':'Editar aluno'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Nome completo')),const SizedBox(height:10),TextField(controller:phone,decoration:const InputDecoration(labelText:'Telefone')),const SizedBox(height:10),TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Observações'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:(){if(name.text.trim().isEmpty)return;context.read<AppStore>().upsertStudent({'id':old?['id']??id(),'classId':classId,'name':name.text.trim(),'phone':phone.text.trim(),'note':note.text.trim(),'active':true});Navigator.pop(ctx);},child:const Text('Salvar'))]));}
