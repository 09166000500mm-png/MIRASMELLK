import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

const navy = Color(0xFF071827);
const navy2 = Color(0xFF102B40);
const gold = Color(0xFFD7A84A);

void main() => runApp(const MirathApp());

class MirathApp extends StatefulWidget {
  const MirathApp({super.key});
  @override State<MirathApp> createState() => _MirathAppState();
}
class _MirathAppState extends State<MirathApp> {
  bool dark = false;
  @override void initState() { super.initState(); SharedPreferences.getInstance().then((p) { if (mounted) setState(() => dark = p.getBool('dark') ?? false); }); }
  void setDark(bool v) { setState(() => dark = v); SharedPreferences.getInstance().then((p) => p.setBool('dark', v)); }
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'میراث ملک', themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold)),
    darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)),
    home: Directionality(textDirection: TextDirection.rtl, child: LoginPage(onDark: setDark)),
  );
}

Widget logo([double size = 70]) => SvgPicture.asset('logo.svg', width: size, height: size, fit: BoxFit.contain);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onDark}); final ValueChanged<bool> onDark;
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController(), pass = TextEditingController(); String error = '';
  void login() {
    if ((user.text.trim() == 'admin' || user.text.trim() == 'mojtaba') && pass.text == '1234') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard(onDark: widget.onDark))); return;
    }
    setState(() => error = 'نام کاربری یا رمز عبور اشتباه است');
  }
  @override Widget build(BuildContext context) => Scaffold(
    body: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [navy, navy2, Color(0xFFF4F6F8)])),
      child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Card(elevation: 16, child: Padding(padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(children: [
        logo(100), const Text('میراث ملک', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const Text('سیستم مدیریت هوشمند دپارتمان املاک'),
        const Text('مدیریت مهندس مجتبی صفری', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), const Text('مدیر فروش خانم طهماسبی پور'), const SizedBox(height: 22),
        TextField(controller: user, decoration: const InputDecoration(labelText: 'نام کاربری', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))), const SizedBox(height: 10),
        TextField(controller: pass, obscureText: true, onSubmitted: (_) => login(), decoration: const InputDecoration(labelText: 'رمز عبور', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
        if (error.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(error, style: const TextStyle(color: Colors.red))), const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: login, child: const Text('ورود به سامانه'))), const SizedBox(height: 8), const Text('ورود اولیه: admin / 1234', style: TextStyle(fontSize: 11))
      ]))))));
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.onDark}); final ValueChanged<bool> onDark;
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final pages = <Widget>[HomePage(onTab: (i) => setState(() => tab = i)), const FilesPage(), const CustomersPage(), const MessagesPage(), const CommissionPage()];
    return Scaffold(
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: Row(children: [logo(38), const SizedBox(width: 8), const Text('میراث ملک', style: TextStyle(fontWeight: FontWeight.w900))]),
      actions: [IconButton(onPressed: () => showDialog(context: context, builder: (_) => SettingsDialog(onDark: widget.onDark)), icon: const Icon(Icons.settings))],
      body: Directionality(textDirection: TextDirection.rtl, child: pages[tab]),
      bottomNavigationBar: NavigationBar(backgroundColor: navy, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.white), selectedIcon: Icon(Icons.home, color: gold), label: 'خانه'),
        NavigationDestination(icon: Icon(Icons.home_work_outlined, color: Colors.white), selectedIcon: Icon(Icons.home_work, color: gold), label: 'فایل‌ها'),
        NavigationDestination(icon: Icon(Icons.people_outline, color: Colors.white), selectedIcon: Icon(Icons.people, color: gold), label: 'مشتریان'),
        NavigationDestination(icon: Icon(Icons.chat_outlined, color: Colors.white), selectedIcon: Icon(Icons.chat, color: gold), label: 'پیام‌ها'),
        NavigationDestination(icon: Icon(Icons.calculate_outlined, color: Colors.white), selectedIcon: Icon(Icons.calculate, color: gold), label: 'کمیسیون'),
      ]),
    );
  }
}

class Store {
  static const filesKey = 'mirath_files_v4'; static const customersKey = 'mirath_customers_v2'; static const settingsKey = 'mirath_settings_v2';
  static Future<List<Map<String, dynamic>>> read(String key) async { final p = await SharedPreferences.getInstance(); final s = p.getString(key); if (s == null || s.isEmpty) return []; return (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e)).toList(); }
  static Future<void> write(String key, List<Map<String, dynamic>> value) async { final p = await SharedPreferences.getInstance(); await p.setString(key, jsonEncode(value)); }
  static Future<String> nextCode() async { final a = await read(filesKey); var max = 0; for (final x in a) { final n = int.tryParse((x['code'] ?? '').toString().replaceAll(RegExp(r'\D'), '')) ?? 0; if (n > max) max = n; } return 'MM-${(max + 1).toString().padLeft(6, '0')}'; }
  static Future<void> addFile(Map<String, dynamic> x) async { final a = await read(filesKey); a.add(x); await write(filesKey, a); }
  static Future<void> addCustomer(Map<String, dynamic> x) async { final a = await read(customersKey); a.add(x); await write(customersKey, a); }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onTab}); final ValueChanged<int> onTab;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [navy, navy2])), child: Row(children: [logo(55), const SizedBox(width: 12), const Expanded(child: Text('مدیریت هوشمند دپارتمان املاک\nمدیریت مهندس مجتبی صفری', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)))])),
    const SizedBox(height: 16), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35, children: [
      HomeTile('ثبت فایل جدید', Icons.add_home_work, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFilePage()))),
      HomeTile('فایل‌های ثبت شده', Icons.list_alt, Colors.blue, () => onTab(1)), HomeTile('مشتریان و شماره‌ها', Icons.people, Colors.deepPurple, () => onTab(2)),
      HomeTile('ارسال پیام', Icons.chat, Colors.orange, () => onTab(3)), HomeTile('کمیسیون', Icons.calculate, Colors.teal, () => onTab(4)),
      HomeTile('تنظیمات و API دیوار', Icons.settings, Colors.blueGrey, () => showDialog(context: context, builder: (_) => SettingsDialog(onDark: (_) {}))),
    ]), const SizedBox(height: 18), const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('در ثبت فایل، لینک دیوار را Paste کنید تا در صورت تنظیم API رسمی، اطلاعات عمومی آگهی به‌صورت خودکار وارد شود.')))
  ]);
}
class HomeTile extends StatelessWidget { const HomeTile(this.title, this.icon, this.color, this.onTap, {super.key}); final String title; final IconData icon; final Color color; final VoidCallback onTap; @override Widget build(BuildContext c) => Card(color: color, child: InkWell(onTap: onTap, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 34), const SizedBox(height: 7), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))); }

class FilesPage extends StatefulWidget { const FilesPage({super.key}); @override State<FilesPage> createState() => _FilesPageState(); }
class _FilesPageState extends State<FilesPage> {
  List<Map<String, dynamic>> files = []; @override void initState() { super.initState(); load(); } Future<void> load() async { final x = await Store.read(Store.filesKey); if (mounted) setState(() => files = x); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: [const Expanded(child: Text('فایل‌های املاک', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFilePage())); await load(); }, icon: const Icon(Icons.add), label: const Text('ثبت فایل'))]),
    const SizedBox(height: 10), if (files.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('هنوز فایلی ثبت نشده است')))),
    ...files.reversed.map((x) => Card(child: ListTile(isThreeLine: true, leading: const CircleAvatar(backgroundColor: gold, child: Icon(Icons.home, color: navy)), title: Text('${x['code']} • ${x['title'] ?? 'ملک'}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${x['type'] ?? ''} • ${x['area'] ?? '-'} متر\nمالک: ${x['owner'] ?? '-'}\n${x['address'] ?? ''}'), onTap: () => showDialog(context: context, builder: (_) => PropertyDetails(file: x)))))
  ]);
}
class PropertyDetails extends StatelessWidget { const PropertyDetails({super.key, required this.file}); final Map<String, dynamic> file; @override Widget build(BuildContext context) => AlertDialog(title: Text('${file['code']} • ${file['title'] ?? 'ملک'}'), content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('نوع: ${file['type'] ?? ''}'), Text('معامله: ${file['deal'] ?? ''}'), Text('متراژ: ${file['area'] ?? ''}'), Text('خواب: ${file['rooms'] ?? ''}'), Text('سال ساخت: ${file['year'] ?? ''}'), Text('طبقه: ${file['floor'] ?? ''}'), Text('قیمت: ${file['price'] ?? ''}'), Text('مالک: ${file['owner'] ?? ''}'), Text('شماره مالک: ${file['phone'] ?? ''}'), Text('آدرس: ${file['address'] ?? ''}'), Text('لینک دیوار: ${file['divar'] ?? ''}') ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))]); }

class AddFilePage extends StatefulWidget { const AddFilePage({super.key}); @override State<AddFilePage> createState() => _AddFilePageState(); }
class _AddFilePageState extends State<AddFilePage> {
  final c = <String, TextEditingController>{}; final checks = <String, bool>{}; String type = 'آپارتمان', deal = 'فروش'; bool busy = false, importing = false;
  final checkItems = const ['سند مالکیت دیده شد','هویت مالک احراز شد','شماره مالک تأیید شد','آدرس بررسی شد','قیمت قطعی شد','پارکینگ','انباری','آسانسور','بالکن','بازسازی','نورگیر','سند تک‌برگ','پایان‌کار','عدم خلاف','فوری','قابل تخفیف','معاوضه','سرمایه‌گذاری','فایل اختصاصی دفتر'];
  @override void initState() { super.initState(); for (final k in ['title','area','rooms','year','floor','unit','price','deposit','rent','owner','phone','national','address','postal','document','permit','consultant','divar','description']) { c[k] = TextEditingController(); } for (final q in checkItems) checks[q] = false; }
  @override void dispose() { for (final x in c.values) x.dispose(); super.dispose(); }
  Widget field(String key, String label) => Padding(padding: const EdgeInsets.only(bottom: 9), child: TextField(controller: c[key], decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  String? tokenFrom(String url) { final m = RegExp(r'divar\.ir/(?:v/|s/)?[^/?#]*/([A-Za-z0-9_-]{5,})').firstMatch(url); if (m != null) return m.group(1); final parts = Uri.tryParse(url)?.pathSegments ?? []; return parts.isNotEmpty ? parts.last : null; }
  Future<void> importDivar() async {
    final link = c['divar']!.text.trim(); if (link.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا لینک دیوار را وارد کنید'))); return; }
    final p = await SharedPreferences.getInstance(); final key = p.getString('divar_api_key') ?? ''; if (key.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key دیوار را از تنظیمات وارد کنید'))); return; }
    final token = tokenFrom(link); if (token == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('توکن آگهی از لینک پیدا نشد'))); return; }
    setState(() => importing = true);
    try {
      final r = await http.get(Uri.parse('https://open-api.divar.ir/v1/open-platform/finder/post/$token'), headers: {'x-api-key': key, 'Accept': 'application/json'});
      if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('HTTP ${r.statusCode}');
      final data = jsonDecode(r.body); _fillFromDivar(data); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اطلاعات عمومی آگهی دیوار وارد شد')));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ورود اطلاعات دیوار انجام نشد: $e'))); }
    if (mounted) setState(() => importing = false);
  }
  String findValue(dynamic root, List<String> names) { String result = ''; void walk(dynamic v) { if (result.isNotEmpty) return; if (v is Map) { for (final e in v.entries) { final k = e.key.toString().toLowerCase(); if (names.contains(k) && e.value is String || names.contains(k) && e.value is num) { result = e.value.toString(); return; } walk(e.value); } } else if (v is List) { for (final e in v) walk(e); } } walk(root); return result; }
  void _fillFromDivar(dynamic data) {
    final map = <String, List<String>>{'title':['title','subject'], 'description':['description','desc'], 'area':['size','area','metrage'], 'rooms':['rooms','room_count'], 'year':['production_year','year'], 'floor':['floor','floor_number'], 'price':['price','amount'], 'address':['address','district','location'], 'owner':['owner_name','seller_name'], 'phone':['phone','phone_number','mobile'],};
    for (final e in map.entries) { final v = findValue(data, e.value); if (v.isNotEmpty) c[e.key]?.text = v; }
    c['divar']!.text = c['divar']!.text.trim();
  }
  Future<void> save() async { setState(() => busy = true); final code = await Store.nextCode(); final item = <String, dynamic>{'code': code, 'type': type, 'deal': deal, 'checks': checks, 'savedAt': DateTime.now().toIso8601String()}; for (final e in c.entries) item[e.key] = e.value.text.trim(); await Store.addFile(item); if (item['phone'].toString().isNotEmpty) await Store.addCustomer({'name': item['owner'], 'phone': item['phone'], 'source': 'فایل $code'}); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فایل $code ذخیره شد'))); } }
  @override Widget build(BuildContext context) { final fields = <Widget>[const Text('کد فایل هنگام ذخیره خودکار ساخته می‌شود', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 10), DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'نوع ملک', border: OutlineInputBorder()), items: const ['آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت ساخت','پیش‌فروش'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => type = v); }), const SizedBox(height: 8), DropdownButtonFormField<String>(initialValue: deal, decoration: const InputDecoration(labelText: 'نوع معامله', border: OutlineInputBorder()), items: const ['فروش','رهن و اجاره','اجاره','پیش‌فروش','مشارکت'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => deal = v); }), const SizedBox(height: 8), field('title','عنوان فایل'), field('area','متراژ'), field('rooms','تعداد خواب'), field('year','سال ساخت'), field('floor','طبقه'), field('unit','واحد'), field('price','قیمت فروش'), field('deposit','رهن'), field('rent','اجاره'), field('owner','نام مالک'), field('phone','شماره مالک'), field('national','کد ملی مالک'), field('address','آدرس کامل'), field('postal','کد پستی'), field('document','شماره سند'), field('permit','جواز/پایان‌کار'), field('consultant','مشاور مسئول'), Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [TextField(controller: c['divar'], decoration: InputDecoration(labelText: 'لینک آگهی دیوار', border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: importing ? null : importDivar, icon: importing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download)))), Row(children: [TextButton.icon(onPressed: () async { final d = await Clipboard.getData(Clipboard.kTextPlain); if (d?.text != null) { c['divar']!.text = d!.text!; setState(() {}); } }, icon: const Icon(Icons.content_paste), label: const Text('Paste')), TextButton.icon(onPressed: importDivar, icon: const Icon(Icons.auto_awesome), label: const Text('ورود خودکار مشخصات')), TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: c['divar']!.text)), icon: const Icon(Icons.copy), label: const Text('کپی'))])])), field('description','توضیحات'), const SizedBox(height: 8), const Text('چک‌لیست فایل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), ...checkItems.map((q) => CheckboxListTile(value: checks[q], onChanged: (v) => setState(() => checks[q] = v ?? false), title: Text(q), dense: true)), const SizedBox(height: 10), SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.save), label: const Text('ثبت و ذخیره فایل')))]; return Scaffold(appBar: AppBar(title: const Text('ثبت فایل کامل ملک'), backgroundColor: navy, foregroundColor: Colors.white), body: Directionality(textDirection: TextDirection.rtl, child: ListView(padding: const EdgeInsets.all(16), children: fields))); }
}

class CustomersPage extends StatefulWidget { const CustomersPage({super.key}); @override State<CustomersPage> createState() => _CustomersPageState(); }
class _CustomersPageState extends State<CustomersPage> { List<Map<String, dynamic>> customers = []; final name = TextEditingController(), phone = TextEditingController(); @override void initState() { super.initState(); load(); } Future<void> load() async { final x = await Store.read(Store.customersKey); if (mounted) setState(() => customers = x); } Future<void> add() async { name.clear(); phone.clear(); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('ثبت مشتری'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'نام')), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), FilledButton(onPressed: () async { if (phone.text.trim().isNotEmpty) { await Store.addCustomer({'name': name.text.trim(), 'phone': phone.text.trim(), 'source': 'دستی'}); } if (context.mounted) Navigator.pop(context); }, child: const Text('ذخیره'))])); await load(); }
  Future<void> sms(String number) async { final uri = Uri.parse('sms:${Uri.encodeComponent(number)}?body=${Uri.encodeComponent('سلام، از دپارتمان املاک میراث ملک با شما تماس می‌گیریم.')}'); await launchUrl(uri); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [Row(children: [const Expanded(child: Text('مشتریان و شماره‌ها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: add, icon: const Icon(Icons.person_add), label: const Text('مشتری جدید'))]), const SizedBox(height: 10), if (customers.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(25), child: Center(child: Text('شماره مشتری ثبت نشده است')))), ...customers.reversed.map((x) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(x['name']?.toString().isEmpty == false ? x['name'].toString() : 'بدون نام'), subtitle: Text('${x['phone'] ?? ''}\n${x['source'] ?? ''}'), trailing: IconButton(onPressed: () => sms(x['phone'].toString()), icon: const Icon(Icons.sms, color: gold))))) ]); }

class MessagesPage extends StatefulWidget { const MessagesPage({super.key}); @override State<MessagesPage> createState() => _MessagesPageState(); }
class _MessagesPageState extends State<MessagesPage> { final msg = TextEditingController(text: 'سلام، فایل جدیدی در دپارتمان میراث ملک ثبت شده است. برای اطلاعات بیشتر در خدمت شما هستیم.'); final to = TextEditingController(); Future<void> sendSms() async { if (to.text.trim().isEmpty) return; await launchUrl(Uri.parse('sms:${Uri.encodeComponent(to.text.trim())}?body=${Uri.encodeComponent(msg.text)}')); } Future<void> sendWhatsApp() async { if (to.text.trim().isEmpty) return; final n = to.text.replaceAll(RegExp(r'\D'), ''); await launchUrl(Uri.parse('https://wa.me/$n?text=${Uri.encodeComponent(msg.text)}'), mode: LaunchMode.externalApplication); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [const Text('ارسال پیام', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 12), const Card(child: ListTile(leading: Icon(Icons.groups, color: gold), title: Text('مشاورین آنلاین'), subtitle: Text('پیام آماده برای مشاوران و همکاران')),), const SizedBox(height: 10), TextField(controller: to, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره گیرنده', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))), const SizedBox(height: 10), TextField(controller: msg, maxLines: 6, decoration: const InputDecoration(labelText: 'متن پیام', border: OutlineInputBorder())), const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: [FilledButton.icon(onPressed: sendSms, icon: const Icon(Icons.sms), label: const Text('ارسال SMS')), FilledButton.icon(onPressed: sendWhatsApp, icon: const Icon(Icons.chat), label: const Text('ارسال واتساپ')), OutlinedButton(onPressed: () => Clipboard.setData(ClipboardData(text: msg.text)), child: const Text('کپی متن'))]), const SizedBox(height: 18), const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('برای پیام‌رسانی داخلی واقعی بین حساب‌های مشاوران، باید حساب‌های کاربران و یک سرور مشترک مانند Supabase فعال شود؛ این صفحه فعلاً ارسال SMS/واتساپ و متن آماده را انجام می‌دهد.'))) ]); }

class CommissionPage extends StatefulWidget { const CommissionPage({super.key}); @override State<CommissionPage> createState() => _CommissionPageState(); }
class _CommissionPageState extends State<CommissionPage> { final price = TextEditingController(); final rate = TextEditingController(text: '0.5'); final vat = TextEditingController(text: '10'); double commission = 0, tax = 0, total = 0; void calc() { final p = double.tryParse(price.text.replaceAll(',', '')) ?? 0; final r = double.tryParse(rate.text) ?? 0; final v = double.tryParse(vat.text) ?? 0; setState(() { commission = p * r / 100; tax = commission * v / 100; total = commission + tax; }); }
  String money(double x) => x.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ','); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [const Text('محاسبه کمیسیون', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 12), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ معامله (تومان)', border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'درصد کمیسیون', border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: vat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'درصد مالیات/ارزش افزوده', border: OutlineInputBorder())), const SizedBox(height: 12), FilledButton.icon(onPressed: calc, icon: const Icon(Icons.calculate), label: const Text('محاسبه')), const SizedBox(height: 15), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Text('کمیسیون: ${money(commission)} تومان', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), Text('مالیات: ${money(tax)} تومان'), Text('مبلغ نهایی: ${money(total)} تومان', style: const TextStyle(fontSize: 19, color: gold, fontWeight: FontWeight.bold))]))), const SizedBox(height: 10), FilledButton.icon(onPressed: total <= 0 ? null : () => Clipboard.setData(ClipboardData(text: 'کمیسیون: ${money(commission)} تومان\nمالیات: ${money(tax)} تومان\nمبلغ نهایی: ${money(total)} تومان')), icon: const Icon(Icons.copy), label: const Text('کپی متن کمیسیون برای پیام')) ]); }

class SettingsDialog extends StatefulWidget { const SettingsDialog({super.key, required this.onDark}); final ValueChanged<bool> onDark; @override State<SettingsDialog> createState() => _SettingsDialogState(); }
class _SettingsDialogState extends State<SettingsDialog> { final api = TextEditingController(); bool dark = false; @override void initState() { super.initState(); SharedPreferences.getInstance().then((p) { if (mounted) setState(() { api.text = p.getString('divar_api_key') ?? ''; dark = p.getBool('dark') ?? false; }); }); } Future<void> save() async { final p = await SharedPreferences.getInstance(); await p.setString('divar_api_key', api.text.trim()); widget.onDark(dark); if (mounted) Navigator.pop(context); } @override Widget build(BuildContext context) => AlertDialog(title: const Text('تنظیمات میراث ملک'), content: SingleChildScrollView(child: Column(children: [SwitchListTile(value: dark, onChanged: (v) => setState(() => dark = v), title: const Text('حالت تاریک')), TextField(controller: api, obscureText: true, decoration: const InputDecoration(labelText: 'Divar API Key', border: OutlineInputBorder())), const SizedBox(height: 8), const Text('API Key رسمی کنار دیوار را اینجا وارد کنید. اطلاعات عمومی آگهی با API رسمی قابل دریافت است؛ فیلدهای خصوصی مثل شماره تماس فقط در صورت مجوز رسمی مربوطه قابل دریافت هستند.')])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), FilledButton(onPressed: save, child: const Text('ذخیره تنظیمات'))]); }
