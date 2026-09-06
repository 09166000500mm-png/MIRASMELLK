import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MirathMelkApp());

class MirathMelkApp extends StatelessWidget {
  const MirathMelkApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'میراث ملک',
    locale: const Locale('fa'),
    supportedLocales: const [Locale('fa')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff123b72)), fontFamily: 'sans'),
    home: const LoginPage(),
  );
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final u=TextEditingController(), p=TextEditingController(); bool hide=true;
  @override Widget build(BuildContext c)=>Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth:460),child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(children:[
    const Icon(Icons.apartment,size:82,color:Color(0xff123b72)), const SizedBox(height:12),
    const Text('میراث ملک',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),
    const Text('سیستم مدیریت هوشمند دپارتمان املاک'), const SizedBox(height:35),
    TextField(controller:u,decoration:const InputDecoration(labelText:'نام کاربری',prefixIcon:Icon(Icons.person),border:OutlineInputBorder())), const SizedBox(height:14),
    TextField(controller:p,obscureText:hide,decoration:InputDecoration(labelText:'رمز عبور',prefixIcon:const Icon(Icons.lock),border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility:Icons.visibility_off)))), const SizedBox(height:20),
    SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:()=>Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>const Dashboard())),child:const Text('ورود به سامانه',style:TextStyle(fontSize:18))))
  ]))));
}

class Property { String code,type,title,address,owner,phone,price,area,rooms,year,link,desc; Property({required this.code,required this.type,required this.title,required this.address,required this.owner,required this.phone,required this.price,required this.area,required this.rooms,required this.year,required this.link,required this.desc}); }
final List<Property> properties=[]; final List<String> clients=[];

class Dashboard extends StatefulWidget { const Dashboard({super.key}); @override State<Dashboard> createState()=>_DashboardState(); }
class _DashboardState extends State<Dashboard>{ int tab=0; @override Widget build(BuildContext c){ final pages=[const HomePage(),PropertyPage(onChanged:()=>setState((){})),ClientPage(),const CommissionPage(),const MeetingPage()]; return Scaffold(appBar:AppBar(title:const Text('میراث ملک'),centerTitle:true),body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const [NavigationDestination(icon:Icon(Icons.dashboard),label:'خانه'),NavigationDestination(icon:Icon(Icons.home_work),label:'فایل‌ها'),NavigationDestination(icon:Icon(Icons.people),label:'مشتریان'),NavigationDestination(icon:Icon(Icons.calculate),label:'کمیسیون'),NavigationDestination(icon:Icon(Icons.event),label:'جلسات')])); }}

class HomePage extends StatelessWidget { const HomePage({super.key}); @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[
  const Text('داشبورد مدیریت',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:18),
  Wrap(spacing:12,runSpacing:12,children:[_card('فایل ملکی','${properties.length}','home_work'),_card('مشتری','${clients.length}','people'),_card('جلسات','تقویم','event'),_card('کمیسیون','محاسبه','calculate')]),const SizedBox(height:20),
  Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('امکانات سامانه',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:10),const Text('ثبت و ویرایش فایل، جستجوی مشتری، محاسبه کمیسیون، ثبت جلسات و آماده‌سازی لینک و پیام برای مشتری.')])))
]); }
Widget _card(String a,String b,String i)=>SizedBox(width:170,height:115,child:Card(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i=='home_work'?Icons.home_work:i=='people'?Icons.people:i=='event'?Icons.event:Icons.calculate,size:34),Text(a),Text(b,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))]))); }

class PropertyPage extends StatefulWidget { final VoidCallback onChanged; const PropertyPage({super.key,required this.onChanged}); @override State<PropertyPage> createState()=>_PropertyPageState(); }
class _PropertyPageState extends State<PropertyPage>{ final search=TextEditingController(); String filter='همه';
 @override Widget build(BuildContext c){ final list=properties.where((x)=> (filter=='همه'||x.type==filter)&&('${x.title} ${x.code} ${x.address} ${x.owner}').contains(search.text)).toList(); return Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'جستجو',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton(onPressed:()=>showDialog(context:c,builder:(_)=>PropertyForm(onSave:(p){properties.add(p);setState((){});widget.onChanged();})),icon:const Icon(Icons.add_circle,size:34))])),SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:['همه','آپارتمان','ویلا','تجاری','زمین','باغ','مشارکت','پیش‌فروش'].map((x)=>Padding(padding:const EdgeInsets.only(left:6),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x)))).toList())),Expanded(child:list.isEmpty?const Center(child:Text('هنوز فایلی ثبت نشده است')):ListView.builder(itemCount:list.length,itemBuilder:(_,i){final p=list[i];return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:5),child:ListTile(title:Text('${p.code} - ${p.title}'),subtitle:Text('${p.type} | ${p.area} متر | ${p.price}\n${p.address}'),isThreeLine:true,trailing:PopupMenuButton(itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('ویرایش')),const PopupMenuItem(value:'sms',child:Text('پیامک')),],onSelected:(v)async{if(v=='edit')showDialog(context:c,builder:(_)=>PropertyForm(initial:p,onSave:(q){final n=properties.indexOf(p);properties[n]=q;setState((){});widget.onChanged();}));if(v=='sms'&&p.phone.isNotEmpty)await launchUrl(Uri.parse('sms:${p.phone}?body=${Uri.encodeComponent('سلام، در خصوص فایل ${p.title} از دپارتمان میراث ملک با شما تماس می‌گیریم.')}'));}));}))]); }
}

class PropertyForm extends StatefulWidget { final Property? initial; final void Function(Property) onSave; const PropertyForm({super.key,this.initial,required this.onSave}); @override State<PropertyForm> createState()=>_PropertyFormState(); }
class _PropertyFormState extends State<PropertyForm>{ late final Map<String,TextEditingController> f; String type='آپارتمان'; @override void initState(){super.initState();final p=widget.initial;type=p?.type??'آپارتمان';f={for(final k in ['کد فایل','عنوان','آدرس','نام مالک','تلفن مالک','قیمت','متراژ','تعداد اتاق','سال ساخت','لینک دیوار','توضیحات'])k:TextEditingController(text: _v(p,k))};} String _v(Property? p,String k)=>p==null?'':({'کد فایل':p.code,'عنوان':p.title,'آدرس':p.address,'نام مالک':p.owner,'تلفن مالک':p.phone,'قیمت':p.price,'متراژ':p.area,'تعداد اتاق':p.rooms,'سال ساخت':p.year,'لینک دیوار':p.link,'توضیحات':p.desc}[k]??''); @override Widget build(BuildContext c)=>AlertDialog(title:Text(widget.initial==null?'ثبت فایل جدید':'ویرایش فایل'),content:SizedBox(width:520,child:SingleChildScrollView(child:Column(children:[DropdownButtonFormField(value:type,items:['آپارتمان','ویلا','تجاری','زمین','باغ','مشارکت','پیش‌فروش'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>type=x!),decoration:const InputDecoration(labelText:'نوع ملک')), ...f.entries.map((e)=>Padding(padding:const EdgeInsets.only(top:8),child:TextField(controller:e.value,maxLines:e.key=='توضیحات'?3:1,decoration:InputDecoration(labelText:e.key,border:const OutlineInputBorder()))))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('انصراف')),FilledButton(onPressed:(){final q=Property(code:f['کد فایل']!.text,type:type,title:f['عنوان']!.text,address:f['آدرس']!.text,owner:f['نام مالک']!.text,phone:f['تلفن مالک']!.text,price:f['قیمت']!.text,area:f['متراژ']!.text,rooms:f['تعداد اتاق']!.text,year:f['سال ساخت']!.text,link:f['لینک دیوار']!.text,desc:f['توضیحات']!.text);widget.onSave(q);Navigator.pop(c);},child:const Text('ذخیره'))]); }
}

class ClientPage extends StatefulWidget { const ClientPage({super.key}); @override State<ClientPage> createState()=>_ClientPageState(); }
class _ClientPageState extends State<ClientPage>{final t=TextEditingController();@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(18),child:Column(children:[TextField(controller:t,decoration:const InputDecoration(labelText:'شماره / نام مشتری',border:OutlineInputBorder()),keyboardType:TextInputType.phone),const SizedBox(height:10),FilledButton.icon(onPressed:(){if(t.text.trim().isNotEmpty){clients.add(t.text.trim());t.clear();setState((){});}},icon:const Icon(Icons.person_add),label:const Text('ثبت مشتری')),Expanded(child:ListView.builder(itemCount:clients.length,itemBuilder:(_,i)=>Card(child:ListTile(title:Text(clients[i]),trailing:IconButton(icon:const Icon(Icons.sms),onPressed:()=>launchUrl(Uri.parse('sms:${clients[i]}')))))))]));}

class CommissionPage extends StatefulWidget { const CommissionPage({super.key}); @override State<CommissionPage> createState()=>_CommissionPageState(); }
class _CommissionPageState extends State<CommissionPage>{final price=TextEditingController();double rate=.005;@override Widget build(BuildContext c){final p=double.tryParse(price.text.replaceAll(',',''))??0;final base=p*rate;final vat=base*.1;return Padding(padding:const EdgeInsets.all(20),child:Column(children:[TextField(controller:price,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مبلغ معامله (تومان)',border:OutlineInputBorder())),const SizedBox(height:14),DropdownButtonFormField<double>(value:rate,items:const [DropdownMenuItem(value:.005,child:Text('۰.۵٪')),DropdownMenuItem(value:.25,child:Text('۲۵٪')),DropdownMenuItem(value:.01,child:Text('۱٪'))],onChanged:(v)=>setState(()=>rate=v!),decoration:const InputDecoration(labelText:'درصد کمیسیون')),const SizedBox(height:25),Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[Text('کمیسیون: ${base.toStringAsFixed(0)} تومان'),Text('مالیات ۱۰٪: ${vat.toStringAsFixed(0)} تومان'),Text('جمع: ${(base+vat).toStringAsFixed(0)} تومان',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))]))) ]);}}

class MeetingPage extends StatefulWidget { const MeetingPage({super.key}); @override State<MeetingPage> createState()=>_MeetingPageState(); }
class _MeetingPageState extends State<MeetingPage>{final title=TextEditingController();final date=TextEditingController();final items=<String>[];@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(18),child:Column(children:[TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان جلسه',border:OutlineInputBorder())),const SizedBox(height:8),TextField(controller:date,decoration:const InputDecoration(labelText:'تاریخ و ساعت',border:OutlineInputBorder())),const SizedBox(height:8),FilledButton(onPressed:(){if(title.text.isNotEmpty){setState((){items.add('${title.text} - ${date.text}');title.clear();date.clear();});}},child:const Text('ثبت جلسه')),Expanded(child:ListView(children:items.map((x)=>Card(child:ListTile(leading:const Icon(Icons.event),title:Text(x)))).toList()))]));}
