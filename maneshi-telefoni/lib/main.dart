import 'package:flutter/material.dart';

void main() => runApp(const ManeshiApp());

class ManeshiApp extends StatelessWidget {
  const ManeshiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner:false,title:'منشی تلفنی میراث ملک',theme:ThemeData(useMaterial3:true),home:const HomePage());
}
class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage>{
 final phone=TextEditingController(); String status='آماده تماس'; bool busy=false;
 final questions=['نوع ملک چیست؟','لطفاً آدرس کامل ملک را بفرمایید.','متراژ ملک چقدر است؟','سال ساخت ملک را می‌فرمایید؟','ملک در چه طبقه‌ای است؟','ساختمان چند واحد دارد؟','قیمت موردنظر چقدر است؟','توضیحات یا شرایط خاصی دارید؟'];
 void call(){final p=phone.text.trim(); if(p.isEmpty){setState(()=>status='شماره مشتری را وارد کنید.');return;} setState(()=>status='شماره $p برای تماس آماده شد.');}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('منشی تلفنی میراث ملک')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('منشی هوشمند فروش و اجاره',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('شماره مشتری را وارد کنید تا فرآیند تماس شروع شود.'),const SizedBox(height:20),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره موبایل مشتری',border:OutlineInputBorder())),const SizedBox(height:14),FilledButton.icon(onPressed:busy?null:call,icon:const Icon(Icons.phone),label:const Text('شروع تماس')),const SizedBox(height:15),Card(child:Padding(padding:const EdgeInsets.all(15),child:Text(status))),const SizedBox(height:20),const Text('سؤالات منشی',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),...questions.asMap().entries.map((e)=>ListTile(leading:CircleAvatar(child:Text('${e.key+1}')),title:Text(e.value))) ])));
}
