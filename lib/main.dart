import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MirathApp());

String hp(String s) => sha256.convert(utf8.encode(s)).toString();

class UserAccount {
  String username, name, role, passwordHash;
  UserAccount({required this.username, required this.name, required this.role, required this.passwordHash});
  Map<String,dynamic> toJson() => {'username':username,'name':name,'role':role,'passwordHash':passwordHash};
  factory UserAccount.fromJson(Map<String,dynamic> j) => UserAccount(username:'${j['username']??''}',name:'${j['name']??''}',role:'${j['role']??'مشاور'}',passwordHash:'${j['passwordHash']??''}');
}

class Property {
  String code,type,title,address,owner,phone,price,area,rooms,year,link,desc,agent;
  Property({required this.code,required this.type,required this.title,required this.address,required this.owner,required this.phone,required this.price,required this.area,required this.rooms,required this.year,required this.link,required this.desc,required this.agent});
  Map<String,dynamic> toJson()=>{'code':code,'type':type,'title':title,'address':address,'owner':owner,'phone':phone,'price':price,'area':area,'rooms':rooms,'year':year,'link':link,'desc':desc,'agent':agent};
  factory Property.fromJson(Map<String,dynamic> j)=>Property(code:'${j['code']??''}',type:'${j['type']??'آپارتمان'}',title:'${j['title']??''}',address:'${j['address']??''}',owner:'${j['owner']??''}',phone:'${j['phone']??''}',price:'${j['price']??''}',area:'${j['area']??''}',rooms:'${j['rooms']??''}',year:'${j['year']??''}',link:'${j['link']??''}',desc:'${j['desc']??''}',agent:'${j['agent']??''}');
}

final properties=<Property>[];
final clients=<String>[];
final meetings=<String>[];
UserAccount? currentUser;

class Store {
  static const usersKey='mm_users', propertiesKey='mm_properties', clientsKey='mm_clients', meetingsKey='mm_meetings', darkKey='mm_dark';
  static Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
  static Future<List<UserAccount>> users() async {
    final p=await prefs;
    final raw=p.getString(usersKey);
    if(raw==null){
      final seed=[
        UserAccount(username:'admin',name:'مهندس مجتبی صفری',role:'مدیر',passwordHash:hp('1234')),
        UserAccount(username:'sales',name:'خانم طهماسبی پور',role:'مدیر فروش',passwordHash:hp('1234')),
        UserAccount(username:'consultant',name:'مشاور نمونه',role:'مشاور',passwordHash:hp('1234')),
      ];
      await saveUsers(seed);
      return seed;
    }
    return (jsonDecode(raw) as List).map((e)=>UserAccount.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  static Future<void> saveUsers(List<UserAccount> x) async { final p=await prefs; await p.setString(usersKey,jsonEncode(x.map((e)=>e.toJson()).toList())); }
  static Future<void> load() async {
    final p=await prefs;
    try { properties..clear()..addAll((jsonDecode(p.getString(propertiesKey)??'[]') as List).map((e)=>Property.fromJson(Map<String,dynamic>.from(e)))); } catch (_) { properties.clear(); }
    clients..clear()..addAll(p.getStringList(clientsKey)??[]);
    meetings..clear()..addAll(p.getStringList(meetingsKey)??[]);
  }
  static Future<void> saveProperties() async { final p=await prefs; await p.setString(propertiesKey,jsonEncode(properties.map((e)=>e.toJson()).toList())); }
  static Future<void> saveClients() async { final p=await prefs; await p.setStringList(clientsKey,clients); }
  static Future<void> saveMeetings() async { final p=await prefs; await p.setStringList(meetingsKey,meetings); }
  static Future<bool> dark() async => (await prefs).getBool(darkKey)??false;
  static Future<void> setDark(bool v) async => (await prefs).setBool(darkKey,v);
}

class MirathApp extends StatefulWidget { const MirathApp({super.key}); @override State<MirathApp> createState()=>_MirathAppState(); }
class _MirathAppState extends State<MirathApp> {
  bool dark=false;
  @override void initState(){super.initState(); Store.dark().then((v){if(mounted)setState(()=>dark=v);});}
  void setTheme(bool v){setState(()=>dark=v);Store.setDark(v);}
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'میراث ملک',locale:const Locale('fa'),supportedLocales:const[Locale('fa')],
    localizationsDelegates:GlobalMaterialLocalizations.delegates,themeMode:dark?ThemeMode.dark:ThemeMode.light,
    theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xffb8860b))),
    darkTheme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xffd6a84f),brightness:Brightness.dark)),
    home:LoginPage(onTheme:setTheme),
  );
}

class LuxuryLogo extends StatelessWidget { const LuxuryLogo({super.key}); @override Widget build(BuildContext context)=>Column(children:[Container(width:150,height:95,decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[Color(0xff081522),Color(0xff1b3044)]),border:Border.all(color:const Color(0xffd6a84f),width:2)),child:const Center(child:Icon(Icons.apartment,size:58,color:Color(0xfff4c45b)))),const SizedBox(height:8),const Text('میراث ملک',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),const Text('مدیریت هوشمند املاک',style:TextStyle(fontSize:13))]); }

class LoginPage extends StatefulWidget { final void Function(bool) onTheme; const LoginPage({super.key,required this.onTheme}); @override State<LoginPage> createState()=>_LoginState(); }
class _LoginState extends State<LoginPage>{
  final u=TextEditingController(),p=TextEditingController(); bool hide=true,busy=false; String error='';
  Future<void> login() async {
    setState(()=>busy=true); final list=await Store.users(); UserAccount? found;
    for(final x in list){if(x.username==u.text.trim()){found=x;break;}}
    if(found==null||found.passwordHash!=hp(p.text)){setState((){busy=false;error='نام کاربری یا رمز عبور اشتباه است';});return;}
    currentUser=found; await Store.load(); if(!mounted)return;
    Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>Dashboard(onTheme:widget.onTheme)));
  }
  @override Widget build(BuildContext context)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Column(children:[
    const LuxuryLogo(),const SizedBox(height:10),const Text('مدیریت مهندس مجتبی صفری',style:TextStyle(fontWeight:FontWeight.bold)),const Text('مدیر فروش خانم طهماسبی پور'),const SizedBox(height:28),
    TextField(controller:u,decoration:const InputDecoration(labelText:'نام کاربری',prefixIcon:Icon(Icons.person),border:OutlineInputBorder())),const SizedBox(height:12),
    TextField(controller:p,obscureText:hide,decoration:InputDecoration(labelText:'رمز عبور',prefixIcon:const Icon(Icons.lock),border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility:Icons.visibility_off)))),
    if(error.isNotEmpty)Padding(padding:const EdgeInsets.all(8),child:Text(error,style:TextStyle(color:Theme.of(context).colorScheme.error))),const SizedBox(height:18),
    SizedBox(width:double.infinity,height:52,child:FilledButton(onPressed:busy?null:login,child:Text(busy?'در حال ورود...':'ورود به سامانه'))),const SizedBox(height:12),
    const Text('ورود اولیه مدیر: admin / 1234',style:TextStyle(fontSize:12)),
  ]))));
}
}

class Dashboard extends StatefulWidget { final void Function(bool) onTheme; const Dashboard({super.key,required this.onTheme}); @override State<Dashboard> createState()=>_DashboardState(); }
class _DashboardState extends State<Dashboard>{int tab=0; @override Widget build(BuildContext context){
  final pages=[const HomePage(),PropertyPage(refresh:()=>setState((){})),ClientPage(refresh:()=>setState((){})),const CommissionPage(),MeetingPage(refresh:()=>setState((){}))];
  return Scaffold(appBar:AppBar(title:const Row(children:[Icon(Icons.apartment),SizedBox(width:8),Text('میراث ملک')]),actions:[IconButton(onPressed:()=>showDialog(context:context,builder:(_)=>SettingsPage(onTheme:onTheme)),icon:const Icon(Icons.settings))]),body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
    NavigationDestination(icon:Icon(Icons.dashboard),label:'خانه'),NavigationDestination(icon:Icon(Icons.home_work),label:'فایل‌ها'),NavigationDestination(icon:Icon(Icons.people),label:'مشتریان'),NavigationDestination(icon:Icon(Icons.calculate),label:'کمیسیون'),NavigationDestination(icon:Icon(Icons.event),label:'جلسات')
  ]));
}}

class HomePage extends StatelessWidget { const HomePage({super.key}); @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
  Text('سلام ${currentUser?.name??''}',style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),Text(currentUser?.role??''),const SizedBox(height:20),
  Wrap(spacing:10,runSpacing:10,children:[card('فایل ملکی',properties.length,Icons.home_work),card('مشتری',clients.length,Icons.people),card('جلسه',meetings.length,Icons.event)]),const SizedBox(height:20),
  Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:const[Text('میراث ملک',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),SizedBox(height:8),Text('مدیریت مهندس مجتبی صفری'),Text('مدیر فروش خانم طهماسبی پور'),SizedBox(height:6),Text('ذخیره‌سازی محلی فعال است و اطلاعات پس از بستن برنامه باقی می‌ماند.')]))),
]);
Widget card(String t,int n,IconData i)=>SizedBox(width:160,height:110,child:Card(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,size:32),Text(t),Text('$n',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))])));
}

class PropertyPage extends StatefulWidget { final VoidCallback refresh; const PropertyPage({super.key,required this.refresh}); @override State<PropertyPage> createState()=>_PropertyState(); }
class _PropertyState extends State<PropertyPage>{String filter='همه';final search=TextEditingController();final types=const['همه','آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت','پیش‌فروش'];bool get manager=>currentUser?.role=='مدیر'||currentUser?.role=='مدیر فروش';
Future<void> add()async{await showDialog(context:context,builder:(_)=>PropertyForm(onSave:(p)async{properties.add(p);await Store.saveProperties();setState((){});}));}
Future<void> edit(Property p)async{await showDialog(context:context,builder:(_)=>PropertyForm(initial:p,onSave:(x)async{final i=properties.indexOf(p);if(i>=0)properties[i]=x;await Store.saveProperties();setState((){});}));}
@override Widget build(BuildContext context){final list=properties.where((p){final visible=manager||p.agent==currentUser?.username;final q='${p.code} ${p.title} ${p.type}'.toLowerCase();return visible&&(filter=='همه'||p.type==filter)&&q.contains(search.text.toLowerCase());}).toList();return Column(children:[
  Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'جستجوی فایل',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:add,icon:const Icon(Icons.add))])),
  SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:types.map((t)=>Padding(padding:const EdgeInsets.all(4),child:ChoiceChip(label:Text(t),selected:filter==t,onSelected:(_){setState(()=>filter=t);})) ).toList())),
  Expanded(child:list.isEmpty?const Center(child:Text('فایلی ثبت نشده است')):ListView.builder(itemCount:list.length,itemBuilder:(_,i){final p=list[i];final full=manager||p.agent==currentUser?.username;return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:5),child:ListTile(title:Text('${p.code} - ${p.title}'),subtitle:Text(full?'${p.type} | ${p.area} متر | ${p.price}\nمالک: ${p.owner} | ${p.phone}\nآدرس: ${p.address}':'${p.type} | ${p.area} متر | ${p.price}\nشماره و آدرس مالک مخفی است'),isThreeLine:true,trailing:IconButton(onPressed:()=>edit(p),icon:const Icon(Icons.edit))));}))
]);}
}

class PropertyForm extends StatefulWidget { final Property? initial; final Future<void> Function(Property) onSave; const PropertyForm({super.key,this.initial,required this.onSave}); @override State<PropertyForm> createState()=>_PropertyFormState(); }
class _PropertyFormState extends State<PropertyForm>{late final Map<String,TextEditingController> c;String type='آپارتمان';final types=const['آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت','پیش‌فروش'];
@override void initState(){super.initState();final p=widget.initial;final vals={'code':p?.code??'','title':p?.title??'','address':p?.address??'','owner':p?.owner??'','phone':p?.phone??'','price':p?.price??'','area':p?.area??'','rooms':p?.rooms??'','year':p?.year??'','link':p?.link??'','desc':p?.desc??''};c={for(final k in vals.keys)k:TextEditingController(text:vals[k])};if(p!=null)type=p.type;}
@override void dispose(){for(final x in c.values)x.dispose();super.dispose();}Widget f(String k,String l)=>Padding(padding:const EdgeInsets.only(bottom:9),child:TextField(controller:c[k],decoration:InputDecoration(labelText:l,border:const OutlineInputBorder())));
Future<void> save()async{final p=Property(code:c['code']!.text.trim().isEmpty?'M-${DateTime.now().millisecondsSinceEpoch}':c['code']!.text.trim(),type:type,title:c['title']!.text.trim(),address:c['address']!.text.trim(),owner:c['owner']!.text.trim(),phone:c['phone']!.text.trim(),price:c['price']!.text.trim(),area:c['area']!.text.trim(),rooms:c['rooms']!.text.trim(),year:c['year']!.text.trim(),link:c['link']!.text.trim(),desc:c['desc']!.text.trim(),agent:widget.initial?.agent??currentUser?.username??'');await widget.onSave(p);if(mounted)Navigator.pop(context);}
@override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.initial==null?'ثبت فایل ملک':'ویرایش فایل'),content:SizedBox(width:520,child:SingleChildScrollView(child:Column(children:[DropdownButtonFormField<String>(initialValue:type,items:types.map((x)=>DropdownMenuItem<String>(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)setState(()=>type=v);},decoration:const InputDecoration(labelText:'نوع ملک',border:OutlineInputBorder())),const SizedBox(height:10),f('code','کد فایل'),f('title','عنوان'),f('address','آدرس مالک'),f('owner','نام مالک'),f('phone','شماره مالک'),f('price','قیمت'),f('area','متراژ'),f('rooms','تعداد خواب'),f('year','سال ساخت'),f('link','لینک دیوار'),f('desc','توضیحات')]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('انصراف')),FilledButton(onPressed:save,child:const Text('ذخیره'))]);}
}

class ClientPage extends StatefulWidget{final VoidCallback refresh;const ClientPage({super.key,required this.refresh});@override State<ClientPage> createState()=>_ClientState();}
class _ClientState extends State<ClientPage>{final c=TextEditingController();@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('مشتریان',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),Row(children:[Expanded(child:TextField(controller:c,decoration:const InputDecoration(labelText:'نام یا شماره مشتری',border:OutlineInputBorder()))),IconButton.filled(onPressed:()async{if(c.text.trim().isNotEmpty){clients.add(c.text.trim());await Store.saveClients();c.clear();setState((){});}},icon:const Icon(Icons.add))]),...clients.asMap().entries.map((e)=>ListTile(leading:const Icon(Icons.person),title:Text(e.value))) ]);}

class CommissionPage extends StatefulWidget{const CommissionPage({super.key});@override State<CommissionPage> createState()=>_CommissionState();}
class _CommissionState extends State<CommissionPage>{final price=TextEditingController();double rate=.5;bool vat=true;@override Widget build(BuildContext context){final p=double.tryParse(price.text.replaceAll(',',''))??0;final base=p*rate/100;final total=vat?base*1.1:base;return ListView(padding:const EdgeInsets.all(16),children:[const Text('محاسبه کمیسیون',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),TextField(controller:price,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مبلغ معامله',border:OutlineInputBorder())),DropdownButtonFormField<double>(initialValue:rate,items:<double>[.5,1,25].map((x)=>DropdownMenuItem<double>(value:x,child:Text('$x درصد'))).toList(),onChanged:(v){if(v!=null)setState(()=>rate=v);},decoration:const InputDecoration(labelText:'نرخ کمیسیون')),SwitchListTile(title:const Text('۱۰٪ مالیات ارزش افزوده'),value:vat,onChanged:(v)=>setState(()=>vat=v)),Card(child:Padding(padding:const EdgeInsets.all(18),child:Text('کمیسیون: ${base.toStringAsFixed(0)}\nمبلغ نهایی: ${total.toStringAsFixed(0)}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))))]);}}

class MeetingPage extends StatefulWidget{final VoidCallback refresh;const MeetingPage({super.key,required this.refresh});@override State<MeetingPage> createState()=>_MeetingState();}
class _MeetingState extends State<MeetingPage>{final c=TextEditingController();@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('جلسات و قرارها',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),Row(children:[Expanded(child:TextField(controller:c,decoration:const InputDecoration(labelText:'موضوع جلسه',border:OutlineInputBorder()))),IconButton.filled(onPressed:()async{if(c.text.trim().isNotEmpty){meetings.add(c.text.trim());await Store.saveMeetings();c.clear();setState((){});}},icon:const Icon(Icons.add))]),...meetings.map((e)=>ListTile(leading:const Icon(Icons.event),title:Text(e))) ]);}

class SettingsPage extends StatefulWidget{final void Function(bool) onTheme;const SettingsPage({super.key,required this.onTheme});@override State<SettingsPage> createState()=>_SettingsState();}
class _SettingsState extends State<SettingsPage>{bool dark=false;final old=TextEditingController(),nw=TextEditingController(),nw2=TextEditingController();List<UserAccount> users=[];
@override void initState(){super.initState();Store.dark().then((v){if(mounted)setState(()=>dark=v);});Store.users().then((v){if(mounted)setState(()=>users=v);});}
void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
Future<void> changePassword()async{if(nw.text.isEmpty||nw.text!=nw2.text){msg('رمز جدید یکسان نیست');return;}final list=await Store.users();final me=list.firstWhere((x)=>x.username==currentUser!.username);if(me.passwordHash!=hp(old.text)){msg('رمز فعلی اشتباه است');return;}me.passwordHash=hp(nw.text);await Store.saveUsers(list);currentUser=me;msg('رمز عبور تغییر کرد');old.clear();nw.clear();nw2.clear();}
Future<void> addConsultant()async{final u=TextEditingController(),n=TextEditingController(),p=TextEditingController();await showDialog(context:context,builder:(d)=>AlertDialog(title:const Text('افزودن مشاور'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:u,decoration:const InputDecoration(labelText:'نام کاربری')),TextField(controller:n,decoration:const InputDecoration(labelText:'نام مشاور')),TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'رمز اولیه'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('انصراف')),FilledButton(onPressed:()async{if(u.text.trim().isEmpty||p.text.isEmpty)return;users.add(UserAccount(username:u.text.trim(),name:n.text.trim(),role:'مشاور',passwordHash:hp(p.text)));await Store.saveUsers(users);if(mounted){setState((){});Navigator.pop(d);}},child:const Text('ذخیره'))]));}
@override Widget build(BuildContext context)=>AlertDialog(title:const Text('تنظیمات و دسترسی‌ها'),content:SizedBox(width:560,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SwitchListTile(title:const Text('تم تاریک'),value:dark,onChanged:(v){setState(()=>dark=v);widget.onTheme(v);}),const Divider(),const Text('تغییر رمز عبور',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),TextField(controller:old,obscureText:true,decoration:const InputDecoration(labelText:'رمز فعلی')),TextField(controller:nw,obscureText:true,decoration:const InputDecoration(labelText:'رمز جدید')),TextField(controller:nw2,obscureText:true,decoration:const InputDecoration(labelText:'تکرار رمز جدید')),FilledButton(onPressed:changePassword,child:const Text('تغییر رمز')),const Divider(),if(currentUser?.role=='مدیر')Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('مدیریت مشاورها',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),IconButton(onPressed:addConsultant,icon:const Icon(Icons.person_add))]),...users.map((x)=>ListTile(leading:Icon(x.role=='مشاور'?Icons.person:Icons.admin_panel_settings),title:Text(x.name),subtitle:Text('${x.username} — ${x.role}'))),const Divider(),const Text('مدیریت مهندس مجتبی صفری',style:TextStyle(fontWeight:FontWeight.bold)),const Text('مدیر فروش خانم طهماسبی پور'),const SizedBox(height:8),const Text('مدیر و مدیر فروش: دسترسی کامل. مشاور: فایل خودش با اطلاعات کامل؛ فایل سایر مشاورها بدون شماره و آدرس مالک.')]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('بستن'))]);}
}
