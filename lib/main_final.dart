import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const navy = Color(0xFF071827);
const navy2 = Color(0xFF102B40);
const gold = Color(0xFFD7A84A);

void main() => runApp(const MirathApp());

class MirathApp extends StatefulWidget {
  const MirathApp({super.key});
  @override
  State<MirathApp> createState() => _MirathAppState();
}

class _MirathAppState extends State<MirathApp> {
  bool dark = true;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => dark = p.getBool('dark') ?? true);
    });
  }
  void setDark(bool value) {
    setState(() => dark = value);
    SharedPreferences.getInstance().then((p) => p.setBool('dark', value));
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'میراث ملک',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold)),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)),
      home: LoginPage(onDark: setDark),
    );
  }
}

Widget appLogo([double size = 70]) => SvgPicture.asset('logo.svg', width: size, height: size, fit: BoxFit.contain);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onDark});
  final ValueChanged<bool> onDark;
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  String error = '';
  void login() {
    if ((user.text.trim() == 'admin' || user.text.trim() == 'mojtaba') && pass.text == '1234') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard(onDark: widget.onDark)));
    } else {
      setState(() => error = 'نام کاربری یا رمز عبور اشتباه است');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [navy, navy2, Color(0xFF182838)])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(children: [
                    appLogo(100),
                    const Text('میراث ملک', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    const Text('سیستم مدیریت هوشمند دپارتمان املاک'),
                    const SizedBox(height: 5),
                    const Text('مدیریت مهندس مجتبی صفری', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                    const Text('مدیر فروش خانم طهماسبی پور'),
                    const SizedBox(height: 22),
                    TextField(controller: user, decoration: const InputDecoration(labelText: 'نام کاربری', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 10),
                    TextField(controller: pass, obscureText: true, onSubmitted: (_) => login(), decoration: const InputDecoration(labelText: 'رمز عبور', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                    if (error.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(error, style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: login, child: const Text('ورود به سامانه'))),
                    const SizedBox(height: 8),
                    const Text('ورود اولیه: admin / 1234', style: TextStyle(fontSize: 11)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Store {
  static const filesKey = 'mirath_files_v5';
  static const customersKey = 'mirath_customers_v3';
  static Future<List<Map<String, dynamic>>> read(String key) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final data = jsonDecode(raw) as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  static Future<void> write(String key, List<Map<String, dynamic>> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(data));
  }
  static Future<String> nextCode() async {
    final data = await read(filesKey);
    var max = 0;
    for (final item in data) {
      final n = int.tryParse((item['code'] ?? '').toString().replaceAll(RegExp(r'\D'), '')) ?? 0;
      if (n > max) max = n;
    }
    return 'MM-${(max + 1).toString().padLeft(6, '0')}';
  }
  static Future<void> addFile(Map<String, dynamic> item) async {
    final data = await read(filesKey);
    data.add(item);
    await write(filesKey, data);
  }
  static Future<void> addCustomer(Map<String, dynamic> item) async {
    final data = await read(customersKey);
    data.add(item);
    await write(customersKey, data);
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.onDark});
  final ValueChanged<bool> onDark;
  @override
  State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onTab: (i) => setState(() => tab = i)),
      const FilesPage(),
      const CustomersPage(),
      const MessagesPage(),
      const CommissionPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Row(children: [appLogo(38), const SizedBox(width: 8), const Text('میراث ملک', style: TextStyle(fontWeight: FontWeight.w900))]),
        actions: [IconButton(onPressed: () => showDialog(context: context, builder: (_) => SettingsDialog(onDark: widget.onDark)), icon: const Icon(Icons.settings))],
      ),
      body: Directionality(textDirection: TextDirection.rtl, child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: navy,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.white), selectedIcon: Icon(Icons.home, color: gold), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.home_work_outlined, color: Colors.white), selectedIcon: Icon(Icons.home_work, color: gold), label: 'فایل‌ها'),
          NavigationDestination(icon: Icon(Icons.people_outline, color: Colors.white), selectedIcon: Icon(Icons.people, color: gold), label: 'مشتریان'),
          NavigationDestination(icon: Icon(Icons.chat_outlined, color: Colors.white), selectedIcon: Icon(Icons.chat, color: gold), label: 'پیام‌ها'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined, color: Colors.white), selectedIcon: Icon(Icons.calculate, color: gold), label: 'کمیسیون'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onTab});
  final ValueChanged<int> onTab;
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [navy, navy2])),
        child: Row(children: [appLogo(58), const SizedBox(width: 12), const Expanded(child: Text('مدیریت هوشمند دپارتمان املاک\nمدیریت مهندس مجتبی صفری', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)))]),
      ),
      const SizedBox(height: 15),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
        children: [
          HomeTile('ثبت فایل جدید', Icons.add_home_work, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFilePage()))),
          HomeTile('فایل‌های ثبت شده', Icons.list_alt, Colors.blue, () => onTab(1)),
          HomeTile('مشتریان و شماره‌ها', Icons.people, Colors.deepPurple, () => onTab(2)),
          HomeTile('ارسال پیام', Icons.chat, Colors.orange, () => onTab(3)),
          HomeTile('کمیسیون', Icons.calculate, Colors.teal, () => onTab(4)),
          HomeTile('تنظیمات', Icons.settings, Colors.blueGrey, () => showDialog(context: context, builder: (_) => const SettingsDialog())),
        ],
      ),
    ]);
  }
}
class HomeTile extends StatelessWidget {
  const HomeTile(this.title, this.icon, this.color, this.onTap, {super.key});
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(color: color, child: InkWell(onTap: onTap, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 34), const SizedBox(height: 7), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))));
}

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});
  @override State<FilesPage> createState() => _FilesPageState();
}
class _FilesPageState extends State<FilesPage> {
  List<Map<String, dynamic>> files = [];
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final x = await Store.read(Store.filesKey); if (mounted) setState(() => files = x); }
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [const Expanded(child: Text('فایل‌های املاک', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFilePage())); await load(); }, icon: const Icon(Icons.add), label: const Text('ثبت فایل'))]),
      const SizedBox(height: 10),
      if (files.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('هنوز فایلی ثبت نشده است')))),
      ...files.reversed.map((x) => Card(child: ListTile(isThreeLine: true, leading: const CircleAvatar(backgroundColor: gold, child: Icon(Icons.home, color: navy)), title: Text('${x['code']} • ${x['title'] ?? 'ملک'}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${x['type'] ?? ''} • ${x['area'] ?? '-'} متر\nمالک: ${x['owner'] ?? '-'}\n${x['address'] ?? ''}'), onTap: () => showDialog(context: context, builder: (_) => PropertyDetails(file: x)))))
    ]);
  }
}
class PropertyDetails extends StatelessWidget {
  const PropertyDetails({super.key, required this.file});
  final Map<String, dynamic> file;
  @override
  Widget build(BuildContext context) {
    final rows = <String, String>{'نوع': '${file['type'] ?? ''}', 'معامله': '${file['deal'] ?? ''}', 'متراژ': '${file['area'] ?? ''}', 'خواب': '${file['rooms'] ?? ''}', 'سال ساخت': '${file['year'] ?? ''}', 'طبقه': '${file['floor'] ?? ''}', 'قیمت': '${file['price'] ?? ''}', 'مالک': '${file['owner'] ?? ''}', 'شماره مالک': '${file['phone'] ?? ''}', 'آدرس': '${file['address'] ?? ''}', 'لینک دیوار': '${file['divar'] ?? ''}'};
    return AlertDialog(title: Text('${file['code']} • ${file['title'] ?? 'ملک'}'), content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${e.key}: ${e.value}'))).toList())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))]);
  }
}

class AddFilePage extends StatefulWidget {
  const AddFilePage({super.key});
  @override State<AddFilePage> createState() => _AddFilePageState();
}
class _AddFilePageState extends State<AddFilePage> {
  final c = <String, TextEditingController>{};
  String type = 'آپارتمان';
  String deal = 'فروش';
  bool busy = false;
  bool importing = false;
  final types = const ['آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت ساخت','پیش‌فروش'];
  final deals = const ['فروش','رهن و اجاره','اجاره','پیش‌فروش','مشارکت'];
  @override
  void initState() {
    super.initState();
    for (final k in ['title','area','rooms','year','floor','unit','price','deposit','rent','owner','phone','national','address','postal','document','permit','consultant','divar','description']) c[k] = TextEditingController();
  }
  @override void dispose() { for (final x in c.values) x.dispose(); super.dispose(); }
  Widget field(String key, String label) => Padding(padding: const EdgeInsets.only(bottom: 9), child: TextField(controller: c[key], decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  String? tokenFrom(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    final parts = uri.pathSegments.where((x) => x.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.last;
  }
  String pickText(dynamic value) => value == null ? '' : value.toString();
  void setIfEmpty(String key, String value) { if (value.isNotEmpty && c[key]!.text.isEmpty) c[key]!.text = value; }
  Future<void> importDivar() async {
    final link = c['divar']!.text.trim();
    if (link.isEmpty) { snack('ابتدا لینک دیوار را وارد کنید'); return; }
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('divar_api_key') ?? '';
    if (apiKey.isEmpty) { snack('API Key رسمی دیوار را از تنظیمات وارد کنید'); return; }
    final token = tokenFrom(link);
    if (token == null) { snack('توکن آگهی از لینک پیدا نشد'); return; }
    setState(() => importing = true);
    try {
      final response = await http.get(Uri.parse('https://open-api.divar.ir/v1/open-platform/finder/post/$token'), headers: {'x-api-key': apiKey, 'Accept': 'application/json'});
      if (response.statusCode < 200 || response.statusCode >= 300) { snack('دریافت اطلاعات دیوار ناموفق بود: ${response.statusCode}'); return; }
      final data = jsonDecode(response.body);
      final root = data is Map ? data : <String, dynamic>{};
      final post = root['post'] is Map ? Map<String, dynamic>.from(root['post']) : root;
      setIfEmpty('title', pickText(post['title'] ?? root['title']));
      setIfEmpty('description', pickText(post['description'] ?? root['description']));
      setIfEmpty('area', pickText(post['area'] ?? root['area']));
      setIfEmpty('rooms', pickText(post['rooms'] ?? root['rooms']));
      setIfEmpty('year', pickText(post['year'] ?? root['year']));
      setIfEmpty('floor', pickText(post['floor'] ?? root['floor']));
      setIfEmpty('price', pickText(post['price'] ?? root['price']));
      setIfEmpty('address', pickText(post['location'] ?? post['address'] ?? root['location'] ?? root['address']));
      setState(() {});
      snack('اطلاعات عمومی آگهی وارد شد');
    } catch (e) {
      snack('خطا در ارتباط با دیوار');
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }
  void snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> save() async {
    if (c['title']!.text.trim().isEmpty) { snack('عنوان فایل را وارد کنید'); return; }
    setState(() => busy = true);
    final code = await Store.nextCode();
    final item = <String, dynamic>{'code': code, 'type': type, 'deal': deal, 'savedAt': DateTime.now().toIso8601String()};
    for (final e in c.entries) item[e.key] = e.value.text.trim();
    await Store.addFile(item);
    final phone = c['phone']!.text.trim();
    if (phone.isNotEmpty) await Store.addCustomer({'name': c['owner']!.text.trim(), 'phone': phone, 'source': code});
    if (mounted) { setState(() => busy = false); snack('فایل $code با موفقیت ثبت شد'); Navigator.pop(context); }
  }
  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      Text('کد فایل هنگام ذخیره خودکار ساخته می‌شود', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع ملک', border: OutlineInputBorder()), items: types.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => type = v); }),
      const SizedBox(height: 9),
      DropdownButtonFormField<String>(value: deal, decoration: const InputDecoration(labelText: 'نوع معامله', border: OutlineInputBorder()), items: deals.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => deal = v); }),
      const SizedBox(height: 9),
      field('title','عنوان فایل'), field('area','متراژ'), field('rooms','تعداد خواب'), field('year','سال ساخت'), field('floor','طبقه'), field('unit','واحد'), field('price','قیمت فروش'), field('deposit','رهن'), field('rent','اجاره'), field('owner','نام مالک'), field('phone','شماره مالک'), field('national','کد ملی مالک'), field('address','آدرس کامل'), field('postal','کد پستی'), field('document','شماره سند'), field('permit','جواز / پایان‌کار'), field('consultant','مشاور مسئول'),
      Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        TextField(controller: c['divar'], decoration: const InputDecoration(labelText: 'لینک آگهی دیوار', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          TextButton.icon(onPressed: () async { final data = await Clipboard.getData(Clipboard.kTextPlain); if (data?.text != null) c['divar']!.text = data!.text!; setState(() {}); }, icon: const Icon(Icons.content_paste), label: const Text('Paste')),
          TextButton.icon(onPressed: importing ? null : importDivar, icon: importing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: const Text('ورود خودکار مشخصات')),
          TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: c['divar']!.text)), icon: const Icon(Icons.copy), label: const Text('کپی')),
        ])
      ]))),
      field('description','توضیحات'),
      const SizedBox(height: 10),
      SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.save), label: Text(busy ? 'در حال ذخیره...' : 'ثبت و ذخیره فایل'))),
    ];
    return Scaffold(appBar: AppBar(title: const Text('ثبت فایل کامل ملک'), backgroundColor: navy, foregroundColor: Colors.white), body: Directionality(textDirection: TextDirection.rtl, child: ListView(padding: const EdgeInsets.all(16), children: fields)));
  }
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override State<CustomersPage> createState() => _CustomersPageState();
}
class _CustomersPageState extends State<CustomersPage> {
  List<Map<String, dynamic>> customers = [];
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final x = await Store.read(Store.customersKey); if (mounted) setState(() => customers = x); }
  Future<void> addCustomer() async {
    final name = TextEditingController(); final phone = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('ثبت مشتری'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'نام')), const SizedBox(height: 8), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت'))]));
    if (ok == true && phone.text.trim().isNotEmpty) { await Store.addCustomer({'name': name.text.trim(), 'phone': phone.text.trim(), 'source': 'دستی'}); await load(); }
    name.dispose(); phone.dispose();
  }
  Future<void> sms(String phone) async { final uri = Uri.parse('sms:$phone'); if (await canLaunchUrl(uri)) await launchUrl(uri); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [Row(children: [const Expanded(child: Text('مشتریان و شماره‌ها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: addCustomer, icon: const Icon(Icons.person_add), label: const Text('مشتری جدید'))]), const SizedBox(height: 10), if (customers.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(25), child: Text('شماره مشتری ثبت نشده است'))), ...customers.reversed.map((x) => Card(child: ListTile(leading: const Icon(Icons.person), title: Text(x['name']?.toString().isEmpty == true ? 'بدون نام' : '${x['name']}'), subtitle: Text('${x['phone']} • ${x['source']}'), trailing: IconButton(onPressed: () => sms('${x['phone']}'), icon: const Icon(Icons.sms)))))]);
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  Future<void> openSms(BuildContext context) async { final uri = Uri.parse('sms:?body=${Uri.encodeComponent('سلام، از دپارتمان املاک میراث ملک با شما در ارتباط هستیم.')}'); if (await canLaunchUrl(uri)) await launchUrl(uri); }
  Future<void> openWhatsApp(BuildContext context) async { final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('سلام، از دپارتمان املاک میراث ملک با شما در ارتباط هستیم.')}'); if (await canLaunchUrl(uri)) await launchUrl(uri); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [const Text('مرکز پیام', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 12), Card(child: ListTile(leading: const Icon(Icons.sms, color: gold), title: const Text('ارسال پیامک به مشتری'), subtitle: const Text('پیام آماده کمیسیون و پیگیری فایل'), trailing: FilledButton(onPressed: () => openSms(context), child: const Text('پیامک')))), Card(child: ListTile(leading: const Icon(Icons.chat, color: Colors.green), title: const Text('واتساپ'), subtitle: const Text('ارسال متن آماده به واتساپ'), trailing: FilledButton(onPressed: () => openWhatsApp(context), child: const Text('باز کردن')))), const SizedBox(height: 15), const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('برای گفت‌وگوی آنلاین داخلی با مشاوران، اتصال مشترک Supabase و حساب کاربری هر مشاور باید فعال شود.')))]);
}

class CommissionPage extends StatefulWidget {
  const CommissionPage({super.key});
  @override State<CommissionPage> createState() => _CommissionPageState();
}
class _CommissionPageState extends State<CommissionPage> {
  final price = TextEditingController();
  final percent = TextEditingController(text: '0.5');
  final vat = TextEditingController(text: '10');
  String result = '';
  void calc() {
    final p = double.tryParse(price.text.replaceAll(',', '').trim()) ?? 0;
    final r = double.tryParse(percent.text.replaceAll(',', '').trim()) ?? 0;
    final v = double.tryParse(vat.text.replaceAll(',', '').trim()) ?? 0;
    final commission = p * r / 100;
    final tax = commission * v / 100;
    final total = commission + tax;
    setState(() => result = 'کمیسیون: ${commission.toStringAsFixed(0)}\nمالیات ارزش افزوده: ${tax.toStringAsFixed(0)}\nمبلغ نهایی: ${total.toStringAsFixed(0)}');
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [const Text('محاسبه کمیسیون', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 12), TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ معامله', border: OutlineInputBorder())), const SizedBox(height: 9), TextField(controller: percent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'درصد کمیسیون', border: OutlineInputBorder())), const SizedBox(height: 9), TextField(controller: vat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'درصد ارزش افزوده', border: OutlineInputBorder())), const SizedBox(height: 12), FilledButton.icon(onPressed: calc, icon: const Icon(Icons.calculate), label: const Text('محاسبه')), if (result.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))]);
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, this.onDark});
  final ValueChanged<bool>? onDark;
  @override State<SettingsDialog> createState() => _SettingsDialogState();
}
class _SettingsDialogState extends State<SettingsDialog> {
  final api = TextEditingController();
  bool dark = true;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) { if (mounted) setState(() { api.text = p.getString('divar_api_key') ?? ''; dark = p.getBool('dark') ?? true; }); });
  }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); await p.setString('divar_api_key', api.text.trim()); await p.setBool('dark', dark); widget.onDark?.call(dark); if (mounted) Navigator.pop(context); }
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('تنظیمات میراث ملک'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [SwitchListTile(value: dark, onChanged: (v) => setState(() => dark = v), title: const Text('حالت تیره')), TextField(controller: api, obscureText: true, decoration: const InputDecoration(labelText: 'Divar API Key رسمی', border: OutlineInputBorder())), const SizedBox(height: 8), const Text('کلید API را فقط از حساب مجاز دیوار وارد کنید. اطلاعات خصوصی آگهی از API عمومی دریافت نمی‌شود.', style: TextStyle(fontSize: 12))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')), FilledButton(onPressed: save, child: const Text('ذخیره'))]);
}
