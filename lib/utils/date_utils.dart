import 'package:intl/intl.dart';

final brDate = DateFormat('dd/MM/yyyy');
String isoDate(DateTime d)=>DateFormat('yyyy-MM-dd').format(d);
String displayDate(String iso){ try{return brDate.format(DateTime.parse(iso));}catch(_){return iso;} }
String weekdayName(int w)=>const ['','Segunda-feira','Terça-feira','Quarta-feira','Quinta-feira','Sexta-feira','Sábado','Domingo'][w.clamp(1,7)];
