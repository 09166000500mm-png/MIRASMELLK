import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
    debugShowCheckedModeBanner: false,
    title: 'میراث ملک',
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold)),
    darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)),
    home: LoginPage(onDark: setDark),
  );
}

Widget logo([double size = 70]) => SvgPicture.asset('logo.svg', width: size, height: size);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onDark});
  final ValueChanged<bool> onDark;
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  String error = '';
  void login() {
    final ok = (user.text.trim() == 'admin' || user.text.trim() == 'mojtaba') && pass.text == '1234';
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Shell(onDark: widget.onDark)));
    } else {
      setState(() => error = 'نام کاربری یا رمز عبور اشتباه است');
    }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [navy, navy2, Color(0xfff4f6f8)])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Card(
              elevation: 18,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      logo(95),
                      const Text('میراث ملک', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                      const Text('سیستم مدیریت هوشمند دپارتمان املاک'),
                      const Text('مدیریت مهندس مجتبی صفری', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                      const Text('مدیر فروش خانم طهماسبی پور'),
                      const SizedBox(height: 20),
                      TextField(controller: user, decoration: const InputDecoration(labelText: 'نام کاربری', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: pass, obscureText: true, onSubmitted: (_) => login(), decoration: const InputDecoration(labelText: 'رمز عبور', border: OutlineInputBorder())),
                      if (error.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(error, style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: login, child: const Text('ورود به سامانه'))),
                      const SizedBox(height: 6),
                      const Text('ورود اولیه: admin / 1234', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.onDark});
  final ValueChanged<bool> onDark;
  @override State<Shell> createState() => _MainState();
}
class _MainState extends State<Shell> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final pages = <Widget>[
      Home(onTab: (i) => setState(() => tab = i)),
      const FilesPage(),
      const InfoPage(title: 'مشتریان', icon: Icons.people),
      const InfoPage(title: 'جلسات و قرارها', icon: Icons.event),
      const InfoPage(title: 'کمیسیون', icon: Icons.calculate),
    ];
    return Scaffold(
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: Row(children: [logo(38), const SizedBox(width: 8), const Text('میراث ملک')]), actions: [IconButton(onPressed: () => showDialog(context: context, builder: (_) => SettingsDialog(onDark: widget.onDark)), icon: const Icon(Icons.settings))]),
      body: Directionality(textDirection: TextDirection.rtl, child: pages[tab]),
      bottomNavigationBar: NavigationBar(backgroundColor: navy, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home, color: Colors.white), label: 'خانه'),
        NavigationDestination(icon: Icon(Icons.home_work, color: Colors.white), label: 'فایل‌ها'),
        NavigationDestination(icon: Icon(Icons.people, color: Colors.white), label: 'مشتریان'),
        NavigationDestination(icon: Icon(Icons.event, color: Colors.white), label: 'جلسات'),
        NavigationDestination(icon: Icon(Icons.calculate, color: Colors.white), label: 'کمیسیون'),
      ]),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key, required this.onTab});
  final ValueChanged<int> onTab;
  @override Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [navy, navy2])), child: const Text('مدیریت هوشمند دپارتمان املاک\nمدیریت مهندس مجتبی صفری', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
      const SizedBox(height: 15),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
        ActionTile('ثبت فایل جدید', Icons.add_home_work, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFilePage())).then((_) {})),
        ActionTile('فایل‌ها', Icons.list, Colors.blue, () => onTab(1)),
        ActionTile('مشتریان', Icons.people, Colors.deepPurple, () => onTab(2)),
        ActionTile('جلسات', Icons.event, Colors.orange, () => onTab(3)),
        ActionTile('کمیسیون', Icons.calculate, Colors.teal, () => onTab(4)),
        ActionTile('کاربران', Icons.groups, Colors.blueGrey, () => showDialog(context: context, builder: (_) => const UsersDialog())),
      ]),
    ],
  );
}
class ActionTile extends StatelessWidget {
  const ActionTile(this.title, this.icon, this.color, this.onTap, {super.key});
  final String title; final IconData icon; final Color color; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(color: color, child: InkWell(onTap: onTap, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 35), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))));
}

class PropertyStore {
  static const key = 'mirath_properties_v5';
  static Future<List<Map<String, dynamic>>> all() async { final p = await SharedPreferences.getInstance(); final s = p.getString(key); if (s == null) return []; return (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e)).toList(); }
  static Future<void> save(List<Map<String, dynamic>> a) async { final p = await SharedPreferences.getInstance(); await p.setString(key, jsonEncode(a)); }
  static Future<String> nextCode() async { final a = await all(); return 'MM-${(a.length + 1).toString().padLeft(6, '0')}'; }
  static Future<void> add(Map<String, dynamic> item) async { final a = await all(); a.add(item); await save(a); }
}

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});
  @override State<FilesPage> createState() => _FilesPageState();
}
class _FilesPageState extends State<FilesPage> {
  List<Map<String, dynamic>> files = [];
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final x = await PropertyStore.all(); if (mounted) setState(() => files = x); }
  Future<void> newFile() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFilePage())); await load(); }
  @override Widget build(BuildContext context) => RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: [const Expanded(child: Text('فایل‌های املاک', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: newFile, icon: const Icon(Icons.add), label: const Text('ثبت فایل'))]),
    const SizedBox(height: 10),
    if (files.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(25), child: Center(child: Text('هنوز فایلی ثبت نشده است')))),
    ...files.reversed.map((x) => Card(child: ListTile(isThreeLine: true, title: Text('${x['code']} • ${x['title']}'), subtitle: Text('${x['type']} • ${x['area']} متر\nمالک: ${x['owner']}\n${x['address']}'), trailing: PopupMenuButton<String>(onSelected: (v) async { final link = (x['divar'] ?? '').toString(); if (v == 'copy') await Clipboard.setData(ClipboardData(text: link)); if (v == 'open' && link.isNotEmpty) await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication); }, itemBuilder: (_) => const [PopupMenuItem(value: 'copy', child: Text('کپی لینک دیوار')), PopupMenuItem(value: 'open', child: Text('باز کردن لینک دیوار'))]))),
  ]));
}

class AddFilePage extends StatefulWidget {
  const AddFilePage({super.key});
  @override State<AddFilePage> createState() => _AddFilePageState();
}
class _AddFilePageState extends State<AddFilePage> {
  final form = GlobalKey<FormState>();
  final c = <String, TextEditingController>{};
  String type = 'آپارتمان'; String deal = 'فروش'; bool busy = false;
  final checks = <String, bool>{};
  final checkItems = const ['سند مالکیت دیده شد','هویت مالک احراز شد','شماره مالک تأیید شد','آدرس بررسی شد','قیمت قطعی شد','پارکینگ','انباری','آسانسور','بالکن','بازسازی','نورگیر','سند تک‌برگ','پایان‌کار','عدم خلاف','فوری','قابل تخفیف','معاوضه','سرمایه‌گذاری','فایل اختصاصی دفتر'];
  @override void initState() { super.initState(); for (final k in ['title','area','rooms','year','floor','unit','price','deposit','rent','owner','phone','national','address','postal','document','permit','consultant','divar','description']) { c[k] = TextEditingController(); } for (final q in checkItems) { checks[q] = false; } }
  @override void dispose() { for (final v in c.values) { v.dispose(); } super.dispose(); }
  Widget field(String key, String label, {bool required = false}) => Padding(padding: const EdgeInsets.only(bottom: 9), child: TextFormField(controller: c[key], decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), validator: required ? (v) => v == null || v.trim().isEmpty ? 'این مورد الزامی است' : null : null);
  Future<void> pasteDivar() async { final d = await Clipboard.getData(Clipboard.kTextPlain); if (d?.text != null) setState(() => c['divar']!.text = d!.text!); }
  Future<void> save() async { if (!form.currentState!.validate()) return; setState(() => busy = true); final code = await PropertyStore.nextCode(); final item = <String, dynamic>{'code': code, 'type': type, 'deal': deal, 'savedAt': DateTime.now().toIso8601String(), 'checks': checks}; for (final e in c.entries) { item[e.key] = e.value.text.trim(); } await PropertyStore.add(item); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فایل $code با موفقیت ذخیره شد'))); } }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ثبت فایل کامل ملک'), backgroundColor: navy, foregroundColor: Colors.white),
    body: Directionality(textDirection: TextDirection.rtl, child: Form(key: form, child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('کد فایل به صورت خودکار ساخته می‌شود', style: const TextStyle(color: gold, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'نوع ملک', border: OutlineInputBorder()), items: const ['آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت ساخت','پیش‌فروش'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => type = v); }),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: deal, decoration: const InputDecoration(labelText: 'نوع معامله', border: OutlineInputBorder()), items: const ['فروش','رهن و اجاره','اجاره','پیش‌فروش','مشارکت'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => deal = v); }),
      const SizedBox(height: 10),
      field('title','عنوان فایل',required:true), field('area','متراژ'), field('rooms','تعداد خواب'), field('year','سال ساخت'), field('floor','طبقه'), field('unit','واحد'), field('price','قیمت فروش'), field('deposit','رهن'), field('rent','اجاره'), field('owner','نام مالک',required:true), field('phone','شماره مالک',required:true), field('national','کد ملی مالک'), field('address','آدرس کامل',required:true), field('postal','کد پستی'), field('document','شماره سند'), field('permit','جواز/پایان‌کار'), field('consultant','مشاور مسئول'),
      Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [TextField(controller: c['divar'], decoration: InputDecoration(labelText: 'لینک آگهی دیوار', border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: pasteDivar, icon: const Icon(Icons.content_paste)))), Row(children: [TextButton.icon(onPressed: pasteDivar, icon: const Icon(Icons.content_paste), label: const Text('Paste')), TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: c['divar']!.text)), icon: const Icon(Icons.copy), label: const Text('کپی'))])])),
      field('description','توضیحات و شرایط'),
      const SizedBox(height: 8),
      const Text('چک‌لیست فایل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...checkItems.map((q) => CheckboxListTile(value: checks[q], onChanged: (v) => setState(() => checks[q] = v ?? false), title: Text(q), dense: true)),
      const SizedBox(height: 10),
      SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.save), label: const Text('ثبت و ذخیره فایل'))),
    ])),
  );
}

class InfoPage extends StatelessWidget { const InfoPage({super.key, required this.title, required this.icon}); final String title; final IconData icon; @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 65, color: gold), Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold))])); }
class SettingsDialog extends StatelessWidget { const SettingsDialog({super.key, required this.onDark}); final ValueChanged<bool> onDark; @override Widget build(BuildContext context) => AlertDialog(title: const Text('تنظیمات'), content: SwitchListTile(title: const Text('حالت تاریک'), value: Theme.of(context).brightness == Brightness.dark, onChanged: (v) { onDark(v); Navigator.pop(context); })); }
class UsersDialog extends StatelessWidget { const UsersDialog({super.key}); @override Widget build(BuildContext context) => AlertDialog(title: const Text('کاربران'), content: const Column(mainAxisSize: MainAxisSize.min, children: [ListTile(title: Text('مدیر سیستم'), subtitle: Text('دسترسی کامل')), ListTile(title: Text('مشاور املاک'), subtitle: Text('مدیریت فایل‌ها')), ListTile(title: Text('ثبت فایل'), subtitle: Text('ثبت و ویرایش فایل'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))]); }
