import 'package:flutter/material.dart';
class AppTheme {
  static const seed=Color(0xFF8A3A58);
  static ThemeData light(){final scheme=ColorScheme.fromSeed(seedColor:seed,brightness:Brightness.light,surface:const Color(0xFFFFF8FA));return ThemeData(useMaterial3:true,colorScheme:scheme,scaffoldBackgroundColor:const Color(0xFFFFF8FA),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:Color(0xFFF0E4E8))),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:seed,width:1.5))),cardTheme:CardThemeData(elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),color:Colors.white));}
  static ThemeData dark(){return ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:seed,brightness:Brightness.dark));}
}
