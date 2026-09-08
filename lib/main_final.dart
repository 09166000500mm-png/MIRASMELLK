import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const navy = Color(0xFF071827);
const navy2 = Color(0xFF102B40);
const gold = Color(0xFFD7A84A);
const page = Color(0xFFF4F6F8);

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
    debugShowCheckedModeBanner: false, title: 'میراث ملک', locale: const Locale('fa'),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: page, colorScheme: ColorScheme.fromSeed(seedColor: gold)),
    darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)),
    home: Directionality(textDirection: TextDirection.rtl, child: LoginPage(onDark: setDark)),
  );
}

Widget logo([double s = 70]) => SvgPicture.asset('logo.svg', width: s, height: s, fit: BoxFit.contain);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onDark}); final ValueChanged<bool> onDark;
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final u = TextEditingController(), p = TextEditingController(); String error = '';
  void login() {
    if ((u.text.trim() == 'admin' && p.text == '1234') || (u.text.trim() == 'mojtaba' && p.text == '1234')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard(onDark: widget.onDark))); return;
    }
    setState(() => error = 'نام کاربری یا رمز عبور اشتباه است');
  }
  @override Widget build(BuildContext context) => Scaffold(body: Container(
    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [navy, navy2, page])),
    child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Card(
      elevation: 18, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(children: [
        logo(105), const Text('میراث ملک', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: navy)),
        const Text('سیستم مدیریت هوشمند دپارتمان املاک'), const SizedBox(height: 6),
        const Text('مدیریت مهندس مجتبی صفری', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        const Text('مدیر فروش خانم طهماسبی پور', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 24),
        TextField(controller: u, decoration: const InputDecoration(labelText: 'نام کاربری', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
        const SizedBox(height: 12), TextField(controller: p, obscureText: true, onSubmitted: (_) => login(), decoration: const InputDecoration(labelText: 'رمز عبور', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
        if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 18), SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: login, style: FilledButton.styleFrom(backgroundColor: navy), child: const Text('ورود به سامانه'))),
        const SizedBox(height: 8), const Text('ورود اولیه: admin / 1234', style: TextStyle(fontSize: 11)),
      ])))))));
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.onDark}); final ValueChanged<bool> onDark;
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  int tab = 0;
  void go(int i) => setState(() => tab = i);
  @override Widget build(BuildContext context) {
    final pages = [Home(onGo: go), FilesPage(), const ClientsPage(), const MeetingsPage(), const CommissionPage()];
    return Scaffold(
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: Row(children: [logo(40), const SizedBox(width: 8), const Text('میراث ملک', style: TextStyle(fontWeight: FontWeight.w900))]),
      actions: [IconButton(onPressed: () => showDialog(context: context, builder: (_) => SettingsDialog(onDark: widget.onDark)), icon: const Icon(Icons.settings_outlined))]),
      body: Directionality(textDirection: TextDirection.rtl, child: pages[tab]),
      bottomNavigationBar: NavigationBar(backgroundColor: navy, selectedIndex: tab, onDestinationSelected: go, destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined, color: Colors.white), selectedIcon: Icon(Icons.dashboard, color: gold), label: 'خانه'),
        NavigationDestination(icon: Icon(Icons.home_work_outlined, color: Colors.white), selectedIcon: Icon(Icons.home_work, color: gold), label: 'فایل‌ها'),
        NavigationDestination(icon: Icon(Icons.people_outline, color: Colors.white), selectedIcon: Icon(Icons.people, color: gold), label: 'مشتریان'),
        NavigationDestination(icon: Icon(Icons.event_outlined, color: Colors.white), selectedIcon: Icon(Icons.event, color: gold), label: 'جلسات'),
        NavigationDestination(icon: Icon(Icons.calculate_outlined, color: Colors.white), selectedIcon: Icon(Icons.calculate, color: gold), label: 'کمیسیون'),
      ]),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key, required this.onGo}); final ValueChanged<int> onGo;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [navy, navy2])), child: Row(children: [CircleAvatar(radius: 30, backgroundColor: gold, child: logo(46)), const SizedBox(width: 12), const Expanded(child: Text('سلام مجتبی\nمدیریت هوشمند دپارتمان املاک', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)))])),
    const SizedBox(height: 16), GridView.count(crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35, children: [
      HomeCard('ثبت فایل جدید', Icons.add_home_work, Colors.green, () => showDialog(context: context, builder: (_) => const AddFileDialog())),
      HomeCard('فایل‌های ثبت شده', Icons.view_list, Colors.blue, () => onGo(1)), HomeCard('مشتریان', Icons.people, Colors.deepPurple, () => onGo(2)),
      HomeCard('جلسات و قرارها', Icons.calendar_month, Colors.orange, () => onGo(3)), HomeCard('مشاوران و کاربران', Icons.groups, Colors.teal, () => showDialog(context: context, builder: (_) => const UsersDialog())),
      HomeCard('تنظیمات', Icons.settings, Colors.blueGrey, () => showDialog(context: context, builder: (_) => SettingsDialog(onDark: (_) {}))),
    ]), const SizedBox(height: 18), const Card(child: Padding(padding: EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مدیریت میراث ملک', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('مدیریت مهندس مجتبی صفری'), Text('مدیر فروش خانم طهماسبی پور'), SizedBox(height: 6), Text('ثبت فایل کامل، کدگذاری خودکار و مدیریت لینک دیوار در همین بخش انجام می‌شود.')])))
  ]);
}
class HomeCard extends StatelessWidget { const HomeCard(this.t, this.i, this.c, this.tap, {super.key}); final String t; final IconData i; final Color c; final VoidCallback tap; @override Widget build(BuildContext x) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(20), child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: Colors.white, size: 34), const SizedBox(height: 8), Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))); }

class PropertyStore {
  static const key = 'mirath_properties_v3';
  static Future<List<Map<String, dynamic>>> all() async { final p = await SharedPreferences.getInstance(); final raw = p.getString(key); if (raw == null || raw.isEmpty) return []; return List<Map<String, dynamic>>.from(jsonDecode(raw).map((e) => Map<String, dynamic>.from(e))); }
  static Future<void> save(List<Map<String, dynamic>> data) async { final p = await SharedPreferences.getInstance(); await p.setString(key, jsonEncode(data)); }
  static Future<String> nextCode() async { final a = await all(); var max = 0; for (final x in a) { final n = int.tryParse((x['code'] ?? '').toString().replaceAll(RegExp(r'\D'), '')) ?? 0; if (n > max) max = n; } return 'MM-${(max + 1).toString().padLeft(6, '0')}'; }
  static Future<void> add(Map<String, dynamic> item) async { final a = await all(); a.add(item); await save(a); }
}

class FilesPage extends StatefulWidget { FilesPage({super.key}); @override State<FilesPage> createState() => _FilesPageState(); }
class _FilesPageState extends State<FilesPage> {
  List<Map<String, dynamic>> data = []; bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { data = await PropertyStore.all(); if (mounted) setState(() => loading = false); }
  @override Widget build(BuildContext context) => RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(18), children: [
    Row(children: [const Expanded(child: Text('فایل‌های املاک', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: () async { await showDialog(context: context, builder: (_) => const AddFileDialog()); load(); }, icon: const Icon(Icons.add), label: const Text('ثبت فایل'))]),
    const SizedBox(height: 10), if (loading) const Center(child: CircularProgressIndicator()), if (!loading && data.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(25), child: Center(child: Text('هنوز فایلی ثبت نشده است')))),
    ...data.reversed.map((x) => Card(child: ListTile(isThreeLine: true, leading: const CircleAvatar(backgroundColor: gold, child: Icon(Icons.home, color: navy)), title: Text('${x['code']}  •  ${x['title'] ?? x['type'] ?? 'ملک'}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${x['type'] ?? ''} • ${x['area'] ?? '-'} متر\n${x['address'] ?? ''}\nمالک: ${x['ownerName'] ?? '-'}'), trailing: PopupMenuButton<String>(onSelected: (v) async { if (v == 'copy') { await Clipboard.setData(ClipboardData(text: (x['divarLink'] ?? '').toString())); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لینک دیوار کپی شد'))); } else if (v == 'open' && (x['divarLink'] ?? '').toString().isNotEmpty) { await launchUrl(Uri.parse(x['divarLink'].toString()), mode: LaunchMode.externalApplication); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'copy', child: Text('کپی لینک دیوار')), PopupMenuItem(value: 'open', child: Text('باز کردن لینک دیوار'))])))),
  ]));
}

class AddFileDialog extends StatefulWidget { const AddFileDialog({super.key}); @override State<AddFileDialog> createState() => _AddFileDialogState(); }
class _AddFileDialogState extends State<AddFileDialog> {
  final form = GlobalKey<FormState>(); final Map<String, TextEditingController> c = {}; String type = 'آپارتمان'; String deal = 'فروش'; bool loading = false;
  final checks = <String, bool>{};
  final checkGroups = <String, List<String>>{
    'اطلاعات اصلی': ['سند مالکیت دیده شد','هویت مالک احراز شد','شماره مالک تأیید شد','آدرس و موقعیت بررسی شد','قیمت با مالک قطعی شد'],
    'مشخصات ملک': ['پارکینگ','انباری','آسانسور','بالکن','بازسازی شده','نورگیر','سند تک‌برگ','پایان‌کار','عدم خلاف'],
    'وضعیت معامله': ['فوری','قابل معاوضه','قابل تخفیف','مناسب سرمایه‌گذاری','فایل اختصاصی دفتر'],
  };
  @override void initState() { super.initState(); for (final k in ['title','area','rooms','year','floor','unit','price','deposit','rent','ownerName','ownerPhone','address','postalCode','lat','lng','divarLink','description','documentNo','permitNo','parkingNo','storageNo','consultant','ownerNationalId']) { c[k] = TextEditingController(); } for (final g in checkGroups.values) for (final q in g) checks[q] = false; }
  @override void dispose() { for (final x in c.values) x.dispose(); super.dispose(); }
  Future<void> save() async {
    if (!form.currentState!.validate()) return; setState(() => loading = true); final code = await PropertyStore.nextCode();
    final item = <String, dynamic>{'code': code, 'type': type, 'deal': deal, 'savedAt': DateTime.now().toIso8601String(), 'checks': checks, for (final e in c.entries) e.key: e.value.text.trim()};
    await PropertyStore.add(item); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فایل $code با موفقیت ذخیره شد'))); }
  }
  Widget tf(String k, String label, {bool required = false, TextInputType? keyboard}) => TextFormField(controller: c[k], keyboardType: keyboard, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.edit_outlined)), validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'این مورد الزامی است' : null : null);
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('ثبت فایل جدید'), content: SizedBox(width: 720, child: Form(key: form, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    FutureBuilder<String>(future: PropertyStore.nextCode(), builder: (_, s) => Card(color: navy, child: Padding(padding: const EdgeInsets.all(12), child: Text('کد خودکار فایل: ${s.data ?? 'در حال تولید...'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
    const SizedBox(height: 10), Row(children: [Expanded(child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع ملک', border: OutlineInputBorder()), items: const ['آپارتمان','ویلا','خانه','زمین','باغ','تجاری','اداری','مغازه','مشارکت در ساخت','پیش‌فروش','کلنگی'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => type = v!))), const SizedBox(width: 10), Expanded(child: DropdownButtonFormField<String>(value: deal, decoration: const InputDecoration(labelText: 'نوع معامله', border: OutlineInputBorder()), items: const ['فروش','رهن و اجاره','اجاره','پیش‌فروش','مشارکت'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => deal = v!))) ]),
    const SizedBox(height: 10), tf('title','عنوان فایل',required:true), const SizedBox(height: 10), Row(children: [Expanded(child: tf('area','متراژ',required:true,keyboard: TextInputType.number)), const SizedBox(width: 8), Expanded(child: tf('rooms','تعداد خواب',keyboard: TextInputType.number)), const SizedBox(width: 8), Expanded(child: tf('year','سال ساخت',keyboard: TextInputType.number))]),
    const SizedBox(height: 10), Row(children: [Expanded(child: tf('floor','طبقه',keyboard: TextInputType.number)), const SizedBox(width: 8), Expanded(child: tf('unit','شماره واحد',keyboard: TextInputType.number)), const SizedBox(width: 8), Expanded(child: tf('price','قیمت',keyboard: TextInputType.number))]),
    const SizedBox(height: 10), Row(children: [Expanded(child: tf('deposit','ودیعه',keyboard: TextInputType.number)), const SizedBox(width: 8), Expanded(child: tf('rent','اجاره ماهانه',keyboard: TextInputType.number)), const SizedBox(width: 8), Expanded(child: tf('postalCode','کد پستی',keyboard: TextInputType.number))]),
    const SizedBox(height: 10), tf('ownerName','نام مالک',required:true), const SizedBox(height: 10), Row(children: [Expanded(child: tf('ownerPhone','شماره مالک',required:true,keyboard: TextInputType.phone)), const SizedBox(width: 8), Expanded(child: tf('ownerNationalId','کد ملی مالک',keyboard: TextInputType.number))]),
    const SizedBox(height: 10), tf('address','آدرس کامل',required:true), const SizedBox(height: 10), Row(children: [Expanded(child: tf('lat','عرض جغرافیایی')), const SizedBox(width: 8), Expanded(child: tf('lng','طول جغرافیایی'))]),
    const SizedBox(height: 10), TextFormField(controller: c['divarLink'], decoration: const InputDecoration(labelText: 'لینک آگهی دیوار را اینجا Paste کن', hintText: 'https://divar.ir/v/...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)), keyboardType: TextInputType.url),
    const SizedBox(height: 6), OutlinedButton.icon(onPressed: () async { final v = c['divarLink']!.text.trim(); if (v.isEmpty) { final clip = await Clipboard.getData(Clipboard.kTextPlain); if (clip?.text != null) c['divarLink']!.text = clip!.text!.trim(); } setState(() {}); }, icon: const Icon(Icons.content_paste), label: const Text('چسباندن لینک کپی‌شده دیوار')),
    const Divider(height: 28), const Text('چک‌لیست ثبت فایل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const Text('موارد انجام‌شده را تیک بزنید؛ همه موارد همراه فایل ذخیره می‌شوند.'),
    for (final entry in checkGroups.entries) Card(child: ExpansionTile(initiallyExpanded: true, title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)), children: [for (final q in entry.value) CheckboxListTile(value: checks[q], onChanged: (v) => setState(() => checks[q] = v ?? false), title: Text(q), controlAffinity: ListTileControlAffinity.leading)])),
    const SizedBox(height: 8), tf('documentNo','شماره سند'), const SizedBox(height: 10), tf('permitNo','شماره جواز / پایان‌کار'), const SizedBox(height: 10), tf('parkingNo','تعداد پارکینگ'), const SizedBox(height: 10), tf('storageNo','تعداد انباری'), const SizedBox(height: 10), tf('consultant','مشاور مسئول فایل'), const SizedBox(height: 10), TextFormField(controller: c['description'], maxLines: 4, decoration: const InputDecoration(labelText: 'توضیحات کامل فایل', border: OutlineInputBorder())),
  ]))), actions: [TextButton(onPressed: loading ? null : () => Navigator.pop(context), child: const Text('انصراف')), FilledButton.icon(onPressed: loading ? null : save, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save), label: const Text('ثبت و ذخیره فایل'))]);
}

class ClientsPage extends StatelessWidget { const ClientsPage({super.key}); @override Widget build(BuildContext c) => const Center(child: Text('مدیریت مشتریان در حال تکمیل است')); }
class MeetingsPage extends StatelessWidget { const MeetingsPage({super.key}); @override Widget build(BuildContext c) => const Center(child: Text('جلسات و قرارها در حال تکمیل است')); }
class CommissionPage extends StatelessWidget { const CommissionPage({super.key}); @override Widget build(BuildContext c) => const Center(child: Text('محاسبه کمیسیون در حال تکمیل است')); }
class UsersDialog extends StatelessWidget { const UsersDialog({super.key}); @override Widget build(BuildContext c) => AlertDialog(title: const Text('کاربران و نقش‌ها'), content: const Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: Icon(Icons.admin_panel_settings), title: Text('مدیر سیستم'), subtitle: Text('دسترسی کامل')), ListTile(leading: Icon(Icons.person), title: Text('مشاور املاک'), subtitle: Text('دسترسی به فایل‌های کاری'))]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]); }
class SettingsDialog extends StatelessWidget { const SettingsDialog({super.key, required this.onDark}); final ValueChanged<bool> onDark; @override Widget build(BuildContext c) => AlertDialog(title: const Text('تنظیمات'), content: SwitchListTile(title: const Text('حالت تاریک'), value: Theme.of(c).brightness == Brightness.dark, onChanged: onDark), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('بستن'))]); }
