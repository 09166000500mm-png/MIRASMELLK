import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
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
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        const Icon(Icons.apartment, size: 80),
        const SizedBox(height: 12),
        const Text('میراث ملک', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const Text('سیستم مدیریت هوشمند دپارتمان املاک'),
        const SizedBox(height: 32),
        TextField(controller: user, decoration: const InputDecoration(labelText: 'نام کاربری', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: hidden, decoration: InputDecoration(
          labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder(),
          suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility : Icons.visibility_off)),
        )),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, height: 52, child: FilledButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard())),
          child: const Text('ورود به سامانه'),
        )),
      ])),
    )),
  );
}

class Property {
  String code, type, title, address, owner, phone, price, area, rooms, year, link, desc;
  Map<String, String> options;
  Property({required this.code, required this.type, required this.title, required this.address, required this.owner,
    required this.phone, required this.price, required this.area, required this.rooms, required this.year,
    required this.link, required this.desc, required this.options});
}
final List<Property> properties = [];
final List<String> clients = [];
final List<String> meetings = [];

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
      final match = RegExp(r'https?://[^\s]+').firstMatch(raw);
      final url = match?.group(0);
      if (url != null && url.contains('divar.ir')) {
        if (!mounted) return;
        await _importAndShow(url);
        ReceiveSharingIntent.instance.reset();
        return;
      }
    }
  }

  Future<void> _importAndShow(String url) async {
    try {
      final p = await DivarImporter.fetch(url);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => PropertyForm(initial: p, onSave: (updated) {
        properties.add(updated);
        setState(() {});
      }));
    } catch (e) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('دریافت اطلاعات دیوار'),
        content: Text('لینک دریافت شد، اما اطلاعات صفحه در حال حاضر قابل استخراج نبود.\n\nلینک:\n$url\n\n$e'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
      ));
    }
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      PropertyPage(onChanged: () => setState(() {}), onImport: _importAndShow),
      const ClientPage(),
      const CommissionPage(),
      const MeetingPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('میراث ملک'), centerTitle: true),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'خانه'),
        NavigationDestination(icon: Icon(Icons.home_work), label: 'ثبت فایل'),
        NavigationDestination(icon: Icon(Icons.people), label: 'مشتریان'),
        NavigationDestination(icon: Icon(Icons.calculate), label: 'کمیسیون'),
        NavigationDestination(icon: Icon(Icons.event), label: 'جلسات'),
      ]),
    );
  }
}

class DivarImporter {
  static Future<Property> fetch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('divar.ir')) throw Exception('لینک دیوار معتبر نیست.');
    final response = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
      'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.7',
    }).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 400) throw Exception('پاسخ دیوار: ${response.statusCode}');
    final html = utf8.decode(response.bodyBytes, allowMalformed: true);
    String meta(String property) {
      final p = RegExp('<meta[^>]+(?:property|name)=["\']$property["\'][^>]+content=["\']([^"\']*)["\']', caseSensitive: false).firstMatch(html);
      return _clean(p?.group(1) ?? '');
    }
    String title = meta('og:title');
    if (title.isEmpty) title = _clean(RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html)?.group(1) ?? '');
    final description = meta('og:description');
    final text = _clean(html.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' '));
    final price = _find(text, [r'([\d۰-۹,.]+)\s*(?:تومان|میلیارد|میلیون)']);
    final area = _find(text, [r'(\d+(?:\.\d+)?)\s*(?:متر|متری)']);
    final rooms = _find(text, [r'(\d+)\s*اتاق']);
    final year = _find(text, [r'(?:ساخت|سال ساخت)\D{0,8}(\d{4})']);
    final floor = _find(text, [r'(?:طبقه)\D{0,8}(\d+)']);
    final phone = _find(text, [r'(09\d{9})']);
    final address = _find(text, [r'(?:آدرس|محله|منطقه)\D{0,5}([^|]{3,80})']);
    return Property(
      code: 'DIV-${DateTime.now().millisecondsSinceEpoch}',
      type: _guessType(title, text),
      title: title.isEmpty ? 'فایل واردشده از دیوار' : title,
      address: address,
      owner: '', phone: phone, price: price, area: area, rooms: rooms, year: year,
      link: url,
      desc: description.isNotEmpty ? description : text.substring(0, text.length > 600 ? 600 : text.length),
      options: {'لینک منبع': url, if (text.contains('شخصی')) 'شخصی / مالک': ''},
    );
  }
  static String _find(String text, List<String> patterns) {
    for (final p in patterns) {
      final m = RegExp(p, caseSensitive: false).firstMatch(text);
      if (m != null) return _clean(m.group(1) ?? m.group(0) ?? '');
    }
    return '';
  }
  static String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').replaceAll('&amp;', '&').trim();
  static String _guessType(String title, String text) {
    final all = '$title $text';
    if (all.contains('ویلا')) return 'ویلا';
    if (all.contains('زمین')) return 'زمین';
    if (all.contains('باغ')) return 'باغ';
    if (all.contains('تجاری')) return 'تجاری';
    return 'آپارتمان';
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('داشبورد مدیریت', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    Wrap(spacing: 10, runSpacing: 10, children: [
      _box('فایل ملکی', properties.length, Icons.home_work), _box('مشتری', clients.length, Icons.people),
      _box('جلسه', meetings.length, Icons.event), _box('کمیسیون', null, Icons.calculate),
    ]),
    const SizedBox(height: 20),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('ورود سریع فایل دیوار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('از داخل دیوار روی اشتراک‌گذاری بزنید و «میراث ملک» را انتخاب کنید؛ لینک در برنامه دریافت می‌شود و اطلاعات قابل دسترس برای فرم ثبت فایل پر می‌شود.'),
    ]))),
  ]);
  Widget _box(String title, int? value, IconData icon) => SizedBox(width: 165, height: 110, child: Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 32), Text(title), if (value != null) Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
  ])));
}

class PropertyPage extends StatefulWidget {
  final VoidCallback onChanged;
  final Future<void> Function(String) onImport;
  const PropertyPage({super.key, required this.onChanged, required this.onImport});
  @override State<PropertyPage> createState() => _PropertyPageState();
}
class _PropertyPageState extends State<PropertyPage> {
  final search = TextEditingController();
  final link = TextEditingController();
  String filter = 'همه';
  final types = const ['همه', 'آپارتمان', 'ویلا', 'تجاری', 'اداری', 'زمین', 'باغ', 'مشارکت', 'پیش‌فروش'];
  @override
  Widget build(BuildContext context) {
    final list = properties.where((p) {
      final text = '${p.title} ${p.code} ${p.address} ${p.owner} ${p.phone}'.toLowerCase();
      return (filter == 'همه' || p.type == filter) && text.contains(search.text.toLowerCase());
    }).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'جستجوی فایل', border: OutlineInputBorder()))),
        const SizedBox(width: 8), IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: OutlinedButton.icon(
        onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('ثبت خودکار از لینک دیوار'),
          content: TextField(controller: link, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'لینک آگهی دیوار', hintText: 'https://divar.ir/...', border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            FilledButton(onPressed: () { final u = link.text.trim(); if (u.isNotEmpty) { Navigator.pop(context); widget.onImport(u); link.clear(); } }, child: const Text('دریافت و تکمیل فرم')),
          ],
        )),
        icon: const Icon(Icons.link), label: const Text('دریافت فایل از دیوار'),
      )),
      const SizedBox(height: 8),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: types.map((t) => Padding(padding: const EdgeInsets.only(left: 6), child: ChoiceChip(label: Text(t), selected: filter == t, onSelected: (_) => setState(() => filter = t)))).toList())),
      const SizedBox(height: 8),
      Expanded(child: list.isEmpty ? const Center(child: Text('هنوز فایلی ثبت نشده است')) : ListView.builder(itemCount: list.length, itemBuilder: (_, i) {
        final p = list[i];
        return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(
          title: Text('${p.code} - ${p.title}'), subtitle: Text('${p.type} | ${p.area} متر | ${p.price}\n${p.address}'), isThreeLine: true,
          trailing: PopupMenuButton<String>(itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('ویرایش')), PopupMenuItem(value: 'sms', child: Text('پیامک'))], onSelected: (v) async {
            if (v == 'edit') _edit(p);
            if (v == 'sms' && p.phone.trim().isNotEmpty) { final body = Uri.encodeComponent('سلام، در خصوص فایل ${p.title} از دپارتمان میراث ملک با شما تماس می‌گیریم.'); await launchUrl(Uri.parse('sms:${p.phone}?body=$body')); }
          }),
        ));
      })),
    ]);
  }
  void _add() => showDialog(context: context, builder: (_) => PropertyForm(onSave: (p) { properties.add(p); setState(() {}); widget.onChanged(); }));
  void _edit(Property p) => showDialog(context: context, builder: (_) => PropertyForm(initial: p, onSave: (updated) { final i = properties.indexOf(p); if (i >= 0) properties[i] = updated; setState(() {}); widget.onChanged(); }));
}

class PropertyForm extends StatefulWidget {
  final Property? initial; final void Function(Property) onSave;
  const PropertyForm({super.key, this.initial, required this.onSave});
  @override State<PropertyForm> createState() => _PropertyFormState();
}
class _PropertyFormState extends State<PropertyForm> {
  late final Map<String, TextEditingController> fields; late String type; late Map<String, bool> checked; late Map<String, TextEditingController> notes;
  final fieldNames = const ['کد فایل','عنوان','آدرس','منطقه/محله','نام مالک','تلفن مالک','قیمت کل','قیمت هر متر','متراژ','تعداد اتاق','سال ساخت','طبقه','لینک دیوار','توضیحات کلی'];
  final optionGroups = const {
    'نوع معامله':['فروش','رهن کامل','رهن و اجاره','اجاره','معاوضه','مشارکت در ساخت','پیش‌فروش'],
    'وضعیت آگهی':['شخصی / مالک','مشاور املاک','سازنده','تعاونی'],
    'امکانات آپارتمان':['پارکینگ','انباری','آسانسور','بالکن','لابی','نگهبانی','استخر','سونا','جکوزی','روف‌گاردن','درب ضدسرقت','کولرگازی','پکیج','شوفاژ','گرمایش از کف'],
    'ویژگی واحد':['فول امکانات','مبله','نوساز','بازسازی‌شده','تک‌واحدی','دوکله','نورگیر','جنوبی','شمالی','مستر','کلوزت','پنت‌هاوس','قابلیت تبدیل','سند آماده'],
    'وضعیت سند و ملک':['سند تک‌برگ','سند شش‌دانگ','وکالتی','قولنامه‌ای','سند در رهن','پایان‌کار دارد','عدم خلاف دارد','جواز ساخت دارد','تخلیه فوری','مالک حاضر به معامله'],
    'ویژگی زمین / باغ / ویلا':['بر اصلی','بر دو نبش','دسترسی آسفالت','آب','برق','گاز','چاه آب','استخر','باغ میوه','دیوارکشی','سنددار','داخل بافت','خارج بافت','قابلیت ساخت'],
  };
  @override void initState() {
    super.initState(); final p=widget.initial; type=p?.type??'آپارتمان'; fields={for(final n in fieldNames)n:TextEditingController(text:_value(p,n))}; checked={}; notes={};
    for(final group in optionGroups.values) for(final option in group){checked[option]=p?.options.containsKey(option)??false;notes[option]=TextEditingController(text:p?.options[option]??'');}
  }
  String _value(Property? p,String key){if(p==null)return '';return {'کد فایل':p.code,'عنوان':p.title,'آدرس':p.address,'منطقه/محله':p.options['منطقه/محله']??'','نام مالک':p.owner,'تلفن مالک':p.phone,'قیمت کل':p.price,'قیمت هر متر':p.options['قیمت هر متر']??'','متراژ':p.area,'تعداد اتاق':p.rooms,'سال ساخت':p.year,'طبقه':p.options['طبقه']??'','لینک دیوار':p.link,'توضیحات کلی':p.desc}[key]??'';}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.initial==null?'ثبت فایل جدید':'ویرایش فایل'),content:SizedBox(width:620,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('اطلاعات اصلی',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:8),...fieldNames.map((n)=>_text(n,lines:n=='توضیحات کلی'?3:1)),const SizedBox(height:12),_typeSection(),for(final e in optionGroups.entries)_optionSection(e.key,e.value)
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('انصراف')),FilledButton(onPressed:_save,child:const Text('ذخیره فایل'))]);
  Widget _text(String name,{int lines=1})=>Padding(padding:const EdgeInsets.only(top:8),child:TextField(controller:fields[name],maxLines:lines,keyboardType:['تلفن مالک','قیمت کل','قیمت هر متر','متراژ','تعداد اتاق','سال ساخت','طبقه'].contains(name)?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:name,border:const OutlineInputBorder())));
  Widget _typeSection()=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('نوع ملک',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),...['آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت','پیش‌فروش'].map((v)=>CheckboxListTile(dense:true,contentPadding:EdgeInsets.zero,value:type==v,title:Text(v),onChanged:(on){if(on==true)setState(()=>type=v);})),])));
  Widget _optionSection(String title,List<String> options)=>Card(margin:const EdgeInsets.only(top:10),child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:4),...options.map(_optionTile)])));
  Widget _optionTile(String option)=>Column(children:[CheckboxListTile(dense:true,contentPadding:EdgeInsets.zero,controlAffinity:ListTileControlAffinity.leading,value:checked[option]??false,title:Text(option),onChanged:(v)=>setState(()=>checked[option]=v??false)),if(checked[option]==true)Padding(padding:const EdgeInsets.only(right:42,bottom:6),child:TextField(controller:notes[option],decoration:const InputDecoration(labelText:'توضیح اختیاری',hintText:'در صورت نیاز توضیح را وارد کنید',border:OutlineInputBorder(),isDense:true)))]);
  void _save(){final options=<String,String>{};for(final o in checked.keys)if(checked[o]==true)options[o]=notes[o]!.text.trim();options['منطقه/محله']=fields['منطقه/محله']!.text.trim();options['قیمت هر متر']=fields['قیمت هر متر']!.text.trim();options['طبقه']=fields['طبقه']!.text.trim();widget.onSave(Property(code:fields['کد فایل']!.text.trim(),type:type,title:fields['عنوان']!.text.trim(),address:fields['آدرس']!.text.trim(),owner:fields['نام مالک']!.text.trim(),phone:fields['تلفن مالک']!.text.trim(),price:fields['قیمت کل']!.text.trim(),area:fields['متراژ']!.text.trim(),rooms:fields['تعداد اتاق']!.text.trim(),year:fields['سال ساخت']!.text.trim(),link:fields['لینک دیوار']!.text.trim(),desc:fields['توضیحات کلی']!.text.trim(),options:options));Navigator.pop(context);}
}

class ClientPage extends StatefulWidget { const ClientPage({super.key}); @override State<ClientPage> createState()=>_ClientPageState(); }
class _ClientPageState extends State<ClientPage> { final name=TextEditingController(),phone=TextEditingController(); @override Widget build(BuildContext context)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:name,decoration:const InputDecoration(labelText:'نام مشتری',border:OutlineInputBorder()))),const SizedBox(width:8),Expanded(child:TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره موبایل',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:(){if(phone.text.trim().isNotEmpty)setState(()=>clients.add('${name.text.trim()} - ${phone.text.trim()}'));},icon:const Icon(Icons.add))])),Expanded(child:ListView.builder(itemCount:clients.length,itemBuilder:(_,i)=>ListTile(leading:const Icon(Icons.person),title:Text(clients[i]))))]); }
class CommissionPage extends StatefulWidget { const CommissionPage({super.key}); @override State<CommissionPage> createState()=>_CommissionPageState(); }
class _CommissionPageState extends State<CommissionPage>{ final amount=TextEditingController();String rate='0.5%'; @override Widget build(BuildContext context){final a=double.tryParse(amount.text.replaceAll(',',''))??0,r=double.tryParse(rate.replaceAll('%',''))??0,base=a*r/100,vat=base*.10;return ListView(padding:const EdgeInsets.all(18),children:[const Text('محاسبه کمیسیون',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),TextField(controller:amount,onChanged:(_)=>setState((){}),keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مبلغ معامله',border:OutlineInputBorder())),const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:rate,items:const ['0.5%','1%','25%'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null)setState(()=>rate=v);},decoration:const InputDecoration(labelText:'نرخ کمیسیون',border:OutlineInputBorder())),const SizedBox(height:18),Card(child:Padding(padding:const EdgeInsets.all(16),child:Text('کمیسیون: ${base.toStringAsFixed(0)}\nمالیات ۱۰٪: ${vat.toStringAsFixed(0)}\nجمع: ${(base+vat).toStringAsFixed(0)}')))]);}}
class MeetingPage extends StatefulWidget { const MeetingPage({super.key}); @override State<MeetingPage> createState()=>_MeetingPageState(); }
class _MeetingPageState extends State<MeetingPage>{final title=TextEditingController(),date=TextEditingController();@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('جلسات و قرارها',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان جلسه',border:OutlineInputBorder())),const SizedBox(height:8),TextField(controller:date,decoration:const InputDecoration(labelText:'تاریخ و ساعت',border:OutlineInputBorder())),const SizedBox(height:8),FilledButton(onPressed:(){if(title.text.trim().isNotEmpty)setState(()=>meetings.add('${title.text.trim()} - ${date.text.trim()}'));},child:const Text('ثبت جلسه')),const SizedBox(height:12),...meetings.map((m)=>Card(child:ListTile(leading:const Icon(Icons.event),title:Text(m))))]);}
