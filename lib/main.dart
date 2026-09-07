import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MirathMelkApp());

class Property {
  String code, type, title, address, owner, phone, price, area, rooms, year, link, desc;
  Map<String, String> options;
  Property({required this.code, required this.type, required this.title, required this.address, required this.owner, required this.phone, required this.price, required this.area, required this.rooms, required this.year, required this.link, required this.desc, required this.options});
  Map<String, dynamic> toJson() => {'code': code, 'type': type, 'title': title, 'address': address, 'owner': owner, 'phone': phone, 'price': price, 'area': area, 'rooms': rooms, 'year': year, 'link': link, 'desc': desc, 'options': options};
  factory Property.fromJson(Map<String, dynamic> j) => Property(code: '${j['code'] ?? ''}', type: '${j['type'] ?? 'آپارتمان'}', title: '${j['title'] ?? ''}', address: '${j['address'] ?? ''}', owner: '${j['owner'] ?? ''}', phone: '${j['phone'] ?? ''}', price: '${j['price'] ?? ''}', area: '${j['area'] ?? ''}', rooms: '${j['rooms'] ?? ''}', year: '${j['year'] ?? ''}', link: '${j['link'] ?? ''}', desc: '${j['desc'] ?? ''}', options: Map<String, String>.from((j['options'] as Map?)?.map((k,v) => MapEntry('$k', '$v')) ?? {}));
}

final List<Property> properties = [];
final List<String> clients = [];
final List<String> meetings = [];

class Store {
  static const _properties = 'mirath_properties_v2';
  static const _clients = 'mirath_clients_v2';
  static const _meetings = 'mirath_meetings_v2';
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    try {
      properties
        ..clear()
        ..addAll((jsonDecode(p.getString(_properties) ?? '[]') as List).map((e) => Property.fromJson(Map<String, dynamic>.from(e))));
      clients..clear()..addAll(p.getStringList(_clients) ?? []);
      meetings..clear()..addAll(p.getStringList(_meetings) ?? []);
    } catch (_) {}
  }
  static Future<void> saveProperties() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_properties, jsonEncode(properties.map((e) => e.toJson()).toList()));
  }
  static Future<void> saveClients() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_clients, clients);
  }
  static Future<void> saveMeetings() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_meetings, meetings);
  }
}

class MirathMelkApp extends StatelessWidget {
  const MirathMelkApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'میراث ملک',
    locale: const Locale('fa'),
    supportedLocales: const [Locale('fa')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff123b72))),
    home: const LoginPage(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController(), pass = TextEditingController();
  bool hidden = true;
  bool loading = false;
  Future<void> _login() async {
    setState(() => loading = true);
    await Store.load();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
    const Icon(Icons.apartment, size: 80),
    const SizedBox(height: 12),
    const Text('میراث ملک', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    const Text('سیستم مدیریت هوشمند دپارتمان املاک'),
    const SizedBox(height: 32),
    TextField(controller: user, decoration: const InputDecoration(labelText: 'نام کاربری', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: pass, obscureText: hidden, decoration: InputDecoration(labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility : Icons.visibility_off)))),
    const SizedBox(height: 18),
    SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: loading ? null : _login, child: Text(loading ? 'در حال بارگذاری...' : 'ورود به سامانه'))),
  ]))));
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  int tab = 0;
  StreamSubscription<List<SharedMediaFile>>? _shareSub;
  @override
  void initState() {
    super.initState();
    _shareSub = ReceiveSharingIntent.instance.getMediaStream().listen(_handleShared, onError: (_) {});
    ReceiveSharingIntent.instance.getInitialMedia().then(_handleShared).catchError((_) {});
  }
  Future<void> _handleShared(List<SharedMediaFile> items) async {
    for (final item in items) {
      final raw = '${item.message ?? ''} ${item.path}';
      final m = RegExp(r'https?://[^\s]+').firstMatch(raw);
      if (m != null && m.group(0)!.contains('divar.ir')) { await _importAndShow(m.group(0)!); ReceiveSharingIntent.instance.reset(); return; }
    }
  }
  Future<void> _importAndShow(String url) async {
    try {
      final p = await DivarImporter.fetch(url);
      if (!mounted) return;
      await showDialog(context: context, builder: (_) => PropertyForm(initial: p, onSave: (x) async { properties.add(x); await Store.saveProperties(); if (mounted) setState(() {}); }));
    } catch (e) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('دریافت اطلاعات دیوار'), content: Text('لینک دریافت شد اما اطلاعات صفحه قابل استخراج نبود.\n\n$url\n\n$e'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))]));
    }
  }
  @override void dispose() { _shareSub?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final pages = [HomePage(onRefresh: () => setState(() {})), PropertyPage(onRefresh: () => setState(() {}), onImport: _importAndShow), ClientPage(onRefresh: () => setState(() {})), const CommissionPage(), MeetingPage(onRefresh: () => setState(() {}))];
    return Scaffold(appBar: AppBar(title: const Text('میراث ملک'), centerTitle: true), body: pages[tab], bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard), label: 'خانه'), NavigationDestination(icon: Icon(Icons.home_work), label: 'ثبت فایل'), NavigationDestination(icon: Icon(Icons.people), label: 'مشتریان'), NavigationDestination(icon: Icon(Icons.calculate), label: 'کمیسیون'), NavigationDestination(icon: Icon(Icons.event), label: 'جلسات')]));
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onRefresh;
  const HomePage({super.key, required this.onRefresh});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('داشبورد مدیریت', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
    Wrap(spacing: 10, runSpacing: 10, children: [_box('فایل ملکی', properties.length, Icons.home_work), _box('مشتری', clients.length, Icons.people), _box('جلسه', meetings.length, Icons.event), _box('کمیسیون', null, Icons.calculate)]),
    const SizedBox(height: 20),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('ذخیره‌سازی فعال است', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('فایل‌ها، مشتری‌ها و جلسات روی حافظه برنامه ذخیره می‌شوند و بعد از بستن و باز کردن دوباره برنامه باقی می‌مانند.')]))),
  ]);
  Widget _box(String t, int? v, IconData i) => SizedBox(width: 165, height: 110, child: Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 32), Text(t), if (v != null) Text('$v', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])));
}

class PropertyPage extends StatefulWidget {
  final VoidCallback onRefresh; final Future<void> Function(String) onImport;
  const PropertyPage({super.key, required this.onRefresh, required this.onImport});
  @override State<PropertyPage> createState() => _PropertyPageState();
}
class _PropertyPageState extends State<PropertyPage> {
  final search = TextEditingController(), link = TextEditingController(); String filter = 'همه';
  final types = const ['همه','آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت','پیش‌فروش'];
  Future<void> _save(Property p) async { properties.add(p); await Store.saveProperties(); if (mounted) setState(() {}); widget.onRefresh(); }
  Future<void> _edit(Property p) async { await showDialog(context: context, builder: (_) => PropertyForm(initial: p, onSave: (x) async { final i = properties.indexOf(p); if (i >= 0) properties[i] = x; await Store.saveProperties(); if (mounted) setState(() {}); })); }
  Future<void> _add() async { await showDialog(context: context, builder: (_) => PropertyForm(onSave: _save)); }
  @override Widget build(BuildContext context) {
    final list = properties.where((p) { final t='${p.title} ${p.code} ${p.address} ${p.owner} ${p.phone}'.toLowerCase(); return (filter=='همه'||p.type==filter)&&t.contains(search.text.toLowerCase()); }).toList();
    return Column(children: [Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'جستجوی فایل',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:_add,icon:const Icon(Icons.add))])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:OutlinedButton.icon(onPressed:()=>showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('ثبت خودکار از لینک دیوار'),content:TextField(controller:link,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'لینک آگهی دیوار',border:OutlineInputBorder())),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('انصراف')),FilledButton(onPressed:(){final u=link.text.trim();if(u.isNotEmpty){Navigator.pop(context);widget.onImport(u);link.clear();}},child:const Text('دریافت و تکمیل فرم'))])),icon:const Icon(Icons.link),label:const Text('دریافت فایل از دیوار'))),
      const SizedBox(height:8),SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:10),child:Row(children:types.map((t)=>Padding(padding:const EdgeInsets.only(left:6),child:ChoiceChip(label:Text(t),selected:filter==t,onSelected:(_)=>setState(()=>filter=t)))).toList())),const SizedBox(height:8),
      Expanded(child:list.isEmpty?const Center(child:Text('هنوز فایلی ثبت نشده است')):ListView.builder(itemCount:list.length,itemBuilder:(_,i){final p=list[i];return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:5),child:ListTile(title:Text('${p.code} - ${p.title}'),subtitle:Text('${p.type} | ${p.area} متر | ${p.price}\n${p.address}'),isThreeLine:true,trailing:PopupMenuButton<String>(itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('ویرایش')),PopupMenuItem(value:'open',child:Text('باز کردن لینک'))],onSelected:(v)async{if(v=='edit')await _edit(p);if(v=='open'&&p.link.isNotEmpty)await launchUrl(Uri.parse(p.link),mode:LaunchMode.externalApplication);})));}))]);
  }
}

class PropertyForm extends StatefulWidget {
  final Property? initial; final Future<void> Function(Property) onSave;
  const PropertyForm({super.key,this.initial,required this.onSave});
  @override State<PropertyForm> createState()=>_PropertyFormState();
}
class _PropertyFormState extends State<PropertyForm>{
  late final Map<String,TextEditingController> c;
  String type='آپارتمان';
  final types=['آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت','پیش‌فروش'];
  @override void initState(){super.initState();final p=widget.initial;c={for(final k in ['code','title','address','owner','phone','price','area','rooms','year','link','desc'])k:TextEditingController(text:p==null?'':{'code':p.code,'title':p.title,'address':p.address,'owner':p.owner,'phone':p.phone,'price':p.price,'area':p.area,'rooms':p.rooms,'year':p.year,'link':p.link,'desc':p.desc}[k]!)};if(p!=null)type=p.type;}
  @override void dispose(){for(final x in c.values)x.dispose();super.dispose();}
  Future<void> _save() async {final p=Property(code:c['code']!.text.trim().isEmpty?'M-${DateTime.now().millisecondsSinceEpoch}':c['code']!.text.trim(),type:type,title:c['title']!.text.trim(),address:c['address']!.text.trim(),owner:c['owner']!.text.trim(),phone:c['phone']!.text.trim(),price:c['price']!.text.trim(),area:c['area']!.text.trim(),rooms:c['rooms']!.text.trim(),year:c['year']!.text.trim(),link:c['link']!.text.trim(),desc:c['desc']!.text.trim(),options:{});await widget.onSave(p);if(mounted)Navigator.pop(context);}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.initial==null?'ثبت فایل ملک':'ویرایش فایل'),content:SizedBox(width:500,child:SingleChildScrollView(child:Column(children:[DropdownButtonFormField<String>(value:type,items:types.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>type=v!),decoration:const InputDecoration(labelText:'نوع ملک',border:OutlineInputBorder())),for(final k in ['code','title','address','owner','phone','price','area','rooms','year','link'])Padding(padding:const EdgeInsets.only(top:10),child:TextField(controller:c[k],decoration:InputDecoration(labelText:{'code':'کد فایل','title':'عنوان','address':'آدرس','owner':'نام مالک','phone':'شماره مالک','price':'قیمت','area':'متراژ','rooms':'تعداد اتاق','year':'سال ساخت','link':'لینک دیوار'}[k],border:const OutlineInputBorder()))),Padding(padding:const EdgeInsets.only(top:10),child:TextField(controller:c['desc'],maxLines:4,decoration:const InputDecoration(labelText:'توضیحات',border:OutlineInputBorder())))]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('انصراف')),FilledButton(onPressed:_save,child:const Text('ثبت و ذخیره'))]);
}

class ClientPage extends StatefulWidget { final VoidCallback onRefresh; const ClientPage({super.key,required this.onRefresh}); @override State<ClientPage> createState()=>_ClientPageState(); }
class _ClientPageState extends State<ClientPage>{ final c=TextEditingController(); Future<void> _add()async{if(c.text.trim().isEmpty)return;clients.add(c.text.trim());c.clear();await Store.saveClients();if(mounted)setState((){});widget.onRefresh();} @override Widget build(BuildContext context)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:c,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'نام و شماره مشتری',border:OutlineInputBorder())),),const SizedBox(width:8),IconButton.filled(onPressed:_add,icon:const Icon(Icons.add))])),Expanded(child:ListView.builder(itemCount:clients.length,itemBuilder:(_,i)=>Card(child:ListTile(title:Text(clients[i]),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{clients.removeAt(i);await Store.saveClients();if(mounted)setState((){});}))))]); }

class CommissionPage extends StatefulWidget { const CommissionPage({super.key}); @override State<CommissionPage> createState()=>_CommissionPageState(); }
class _CommissionPageState extends State<CommissionPage>{final price=TextEditingController();double rate=.005;@override Widget build(BuildContext context){final n=double.tryParse(price.text.replaceAll(',','').replaceAll('٬',''))??0;final commission=n*rate;final vat=commission*.10;return ListView(padding:const EdgeInsets.all(16),children:[const Text('محاسبه کمیسیون',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:16),TextField(controller:price,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'قیمت معامله',border:OutlineInputBorder())),const SizedBox(height:12),DropdownButtonFormField<double>(value:rate,items:const[DropdownMenuItem(value:.005,child:Text('۰٫۵٪')),DropdownMenuItem(value:.01,child:Text('۱٪')),DropdownMenuItem(value:.25,child:Text('۲۵٪'))],onChanged:(v)=>setState(()=>rate=v!),decoration:const InputDecoration(labelText:'درصد کمیسیون',border:OutlineInputBorder())),const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[Text('کمیسیون: ${commission.toStringAsFixed(0)}'),Text('مالیات ۱۰٪: ${vat.toStringAsFixed(0)}'),Text('جمع: ${(commission+vat).toStringAsFixed(0)}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20))])))]);}}

class MeetingPage extends StatefulWidget { final VoidCallback onRefresh; const MeetingPage({super.key,required this.onRefresh}); @override State<MeetingPage> createState()=>_MeetingPageState(); }
class _MeetingPageState extends State<MeetingPage>{final c=TextEditingController();Future<void>_add()async{if(c.text.trim().isEmpty)return;meetings.add(c.text.trim());c.clear();await Store.saveMeetings();if(mounted)setState((){});widget.onRefresh();} @override Widget build(BuildContext context)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:c,decoration:const InputDecoration(labelText:'جلسه / قرار ملاقات',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:_add,icon:const Icon(Icons.add))])),Expanded(child:ListView.builder(itemCount:meetings.length,itemBuilder:(_,i)=>Card(child:ListTile(title:Text(meetings[i]),leading:const Icon(Icons.event),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{meetings.removeAt(i);await Store.saveMeetings();if(mounted)setState((){});}))))]);}

class DivarImporter {
  static Future<Property> fetch(String url) async {
    final uri=Uri.tryParse(url); if(uri==null||!uri.host.contains('divar.ir'))throw Exception('لینک دیوار معتبر نیست.');
    final r=await http.get(uri,headers:{'User-Agent':'Mozilla/5.0','Accept-Language':'fa-IR,fa;q=0.9'}).timeout(const Duration(seconds:15));
    if(r.statusCode<200||r.statusCode>=400)throw Exception('پاسخ دیوار: ${r.statusCode}');
    final html=utf8.decode(r.bodyBytes,allowMalformed:true);String meta(String p){final m=RegExp('<meta[^>]+(?:property|name)=["\\\']$p["\\\'][^>]+content=["\\\']([^"\\\']*)["\\\']',caseSensitive:false).firstMatch(html);return _clean(m?.group(1)??'');}
    String title=meta('og:title');if(title.isEmpty)title=_clean(RegExp(r'<title[^>]*>(.*?)</title>',caseSensitive:false,dotAll:true).firstMatch(html)?.group(1)??'');
    final description=meta('og:description');final text=_clean(html.replaceAll(RegExp(r'<script[^>]*>.*?</script>',caseSensitive:false,dotAll:true),' ').replaceAll(RegExp(r'<style[^>]*>.*?</style>',caseSensitive:false,dotAll:true),' ').replaceAll(RegExp(r'<[^>]+>'),' '));
    return Property(code:'DIV-${DateTime.now().millisecondsSinceEpoch}',type:_guessType(title,text),title:title.isEmpty?'فایل واردشده از دیوار':title,address:_find(text,[r'(?:آدرس|محله|منطقه)\D{0,5}([^|]{3,80})']),owner:'',phone:_find(text,[r'(09\d{9})']),price:_find(text,[r'([\d۰-۹,.]+)\s*(?:تومان|میلیارد|میلیون)']),area:_find(text,[r'(\d+(?:\.\d+)?)\s*(?:متر|متری)']),rooms:_find(text,[r'(\d+)\s*اتاق']),year:_find(text,[r'(?:ساخت|سال ساخت)\D{0,8}(\d{4})']),link:url,desc:description.isNotEmpty?description:text.substring(0,text.length>600?600:text.length),options:{'لینک منبع':url});
  }
  static String _find(String t,List<String> ps){for(final p in ps){final m=RegExp(p,caseSensitive:false).firstMatch(t);if(m!=null)return _clean(m.group(1)??m.group(0)??'');}return '';}
  static String _clean(String s)=>s.replaceAll(RegExp(r'\s+'),' ').replaceAll('&amp;','&').trim();
  static String _guessType(String a,String b){final x='$a $b';if(x.contains('ویلا'))return'ویلا';if(x.contains('زمین'))return'زمین';if(x.contains('باغ'))return'باغ';if(x.contains('تجاری'))return'تجاری';return'آپارتمان';}
}
