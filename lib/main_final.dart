import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

const navy = Color(0xFF071827);
const navy2 = Color(0xFF102B40);
const gold = Color(0xFFD7A84A);
const bg = Color(0xFFF4F6F8);
String hashPass(String s) => sha256.convert(utf8.encode(s)).toString();

class Property {
  Property({required this.code, required this.type, required this.title, required this.area, required this.price, required this.owner, required this.phone, required this.address, required this.agent});
  String code, type, title, area, price, owner, phone, address, agent;
  Map<String, dynamic> toJson() => {'code': code, 'type': type, 'title': title, 'area': area, 'price': price, 'owner': owner, 'phone': phone, 'address': address, 'agent': agent};
  factory Property.fromJson(Map<String, dynamic> j) => Property(code: '${j['code'] ?? ''}', type: '${j['type'] ?? 'آپارتمان'}', title: '${j['title'] ?? ''}', area: '${j['area'] ?? ''}', price: '${j['price'] ?? ''}', owner: '${j['owner'] ?? ''}', phone: '${j['phone'] ?? ''}', address: '${j['address'] ?? ''}', agent: '${j['agent'] ?? ''}');
}

class AppUser {
  AppUser(this.username, this.name, this.role, this.password);
  String username, name, role, password;
  Map<String, dynamic> toJson() => {'u': username, 'n': name, 'r': role, 'p': password};
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser('${j['u']}', '${j['n']}', '${j['r']}', '${j['p']}');
}

final List<Property> properties = [];
final List<String> clients = [];
final List<String> meetings = [];
AppUser? currentUser;

class Store {
  static Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
  static Future<List<AppUser>> users() async {
    final p = await prefs;
    final raw = p.getString('users');
    if (raw == null) {
      final list = [AppUser('admin', 'مهندس مجتبی صفری', 'مدیر', hashPass('1234')), AppUser('sales', 'خانم طهماسبی پور', 'مدیر فروش', hashPass('1234')), AppUser('moshaver1', 'مشاور اول', 'مشاور', hashPass('1234'))];
      await saveUsers(list);
      return list;
    }
    return (jsonDecode(raw) as List).map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))).toList();
  }
  static Future<void> saveUsers(List<AppUser> list) async { await (await prefs).setString('users', jsonEncode(list.map((e) => e.toJson()).toList())); }
  static Future<void> load() async {
    final p = await prefs;
    properties.clear();
    final raw = p.getString('properties');
    if (raw != null) properties.addAll((jsonDecode(raw) as List).map((e) => Property.fromJson(Map<String, dynamic>.from(e))));
    clients..clear()..addAll(p.getStringList('clients') ?? []);
    meetings..clear()..addAll(p.getStringList('meetings') ?? []);
  }
  static Future<void> save() async {
    final p = await prefs;
    await p.setString('properties', jsonEncode(properties.map((e) => e.toJson()).toList()));
    await p.setStringList('clients', clients);
    await p.setStringList('meetings', meetings);
  }
  static Future<bool> dark() async => (await prefs).getBool('dark') ?? false;
  static Future<void> setDark(bool v) async { await (await prefs).setBool('dark', v); }
}

void main() => runApp(const MirathApp());
class MirathApp extends StatefulWidget { const MirathApp({super.key}); @override State<MirathApp> createState() => _MirathAppState(); }
class _MirathAppState extends State<MirathApp> {
  bool dark = false;
  @override void initState() { super.initState(); Store.dark().then((v) { if (mounted) setState(() => dark = v); }); }
  void changeDark(bool v) { setState(() => dark = v); Store.setDark(v); }
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'میراث ملک', locale: const Locale('fa'), supportedLocales: const [Locale('fa')], localizationsDelegates: GlobalMaterialLocalizations.delegates, themeMode: dark ? ThemeMode.dark : ThemeMode.light, theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bg, colorScheme: ColorScheme.fromSeed(seedColor: gold)), darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)), home: Login(onDark: changeDark));
}
Widget logo({double size = 80}) => SvgPicture.asset('logo.svg', height: size, width: size, fit: BoxFit.contain);

class Login extends StatefulWidget { const Login({super.key, required this.onDark}); final ValueChanged<bool> onDark; @override State<Login> createState() => _LoginState(); }
class _LoginState extends State<Login> {
  final username = TextEditingController(); final password = TextEditingController(); bool hidden = true; String error = '';
  Future<void> enter() async {
    final list = await Store.users(); AppUser? found;
    for (final u in list) { if (u.username == username.text.trim()) found = u; }
    if (found == null || found!.password != hashPass(password.text)) { setState(() => error = 'نام کاربری یا رمز عبور اشتباه است'); return; }
    currentUser = found; await Store.load(); if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Shell(onDark: widget.onDark)));
  }
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [navy, navy2, bg], stops: [0, .62, 1])), child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Card(elevation: 20, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [logo(size: 110), const Text('میراث ملک', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: navy)), const Text('مدیریت هوشمند املاک', style: TextStyle(color: Colors.grey)), const SizedBox(height: 8), const Text('مدیریت مهندس مجتبی صفری', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), const Text('مدیر فروش خانم طهماسبی پور', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 24), TextField(controller: username, decoration: const InputDecoration(labelText: 'نام کاربری', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())), const SizedBox(height: 12), TextField(controller: password, obscureText: hidden, decoration: InputDecoration(labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility : Icons.visibility_off)), border: const OutlineInputBorder())), if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error, style: const TextStyle(color: Colors.red))), const SizedBox(height: 18), SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: enter, style: FilledButton.styleFrom(backgroundColor: navy), child: const Text('ورود به سامانه'))), const SizedBox(height: 8), const Text('رمز اولیه کاربران: 1234', style: TextStyle(fontSize: 11, color: Colors.grey))]))))))));
}
}

class Shell extends StatefulWidget { const Shell({super.key, required this.onDark}); final ValueChanged<bool> onDark; @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  int index = 0; void refresh() => setState(() {});
  @override Widget build(BuildContext context) {
    final pages = <Widget>[Home(onTab: (i) => setState(() => index = i), refresh: refresh), Files(refresh: refresh), Clients(refresh: refresh), Meetings(refresh: refresh), const Commission()];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: Row(children: [logo(size: 46), const SizedBox(width: 8), const Text('میراث ملک', style: TextStyle(fontWeight: FontWeight.w900))]), actions: [IconButton(onPressed: () => showDialog(context: context, builder: (_) => Settings(onDark: widget.onDark)), icon: const Icon(Icons.settings_outlined))]), body: pages[index], bottomNavigationBar: NavigationBar(backgroundColor: navy, selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_outlined, color: Colors.white), selectedIcon: Icon(Icons.dashboard, color: gold), label: 'خانه'), NavigationDestination(icon: Icon(Icons.apartment_outlined, color: Colors.white), selectedIcon: Icon(Icons.apartment, color: gold), label: 'فایل‌ها'), NavigationDestination(icon: Icon(Icons.people_outline, color: Colors.white), selectedIcon: Icon(Icons.people, color: gold), label: 'مشتریان'), NavigationDestination(icon: Icon(Icons.event_outlined, color: Colors.white), selectedIcon: Icon(Icons.event, color: gold), label: 'جلسات'), NavigationDestination(icon: Icon(Icons.calculate_outlined, color: Colors.white), selectedIcon: Icon(Icons.calculate, color: gold), label: 'کمیسیون')]));
  }
}

class Home extends StatelessWidget {
  const Home({super.key, required this.onTab, required this.refresh}); final ValueChanged<int> onTab; final VoidCallback refresh;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [navy, navy2])), child: Row(children: [CircleAvatar(radius: 31, backgroundColor: gold, child: logo(size: 46)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('سلام ${currentUser?.name ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('اعتماد، تجربه، آینده روشن در دستان شماست', style: TextStyle(color: Colors.white70))]))])), const SizedBox(height: 18), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45, children: [tile('ثبت فایل جدید', Icons.add_home_work, const Color(0xFF27B765), () => showDialog(context: context, builder: (_) => PropertyDialog(onSave: (p) async { properties.add(p); await Store.save(); refresh(); }))), tile('لیست فایل‌ها', Icons.view_list, const Color(0xFF2D98E6), () => onTab(1)), tile('مشتریان', Icons.people, const Color(0xFF7655D8), () => onTab(2)), tile('جلسات و قرارها', Icons.calendar_month, const Color(0xFFF39A2B), () => onTab(3)), tile('مشاوران', Icons.groups, const Color(0xFF23AEBE), () => showDialog(context: context, builder: (_) => const UsersDialog())), tile('تنظیمات', Icons.settings, Colors.blueGrey, () => showDialog(context: context, builder: (_) => Settings(onDark: (_) {}))) ]), const SizedBox(height: 18), Row(children: [stat('فایل‌ها', properties.length), stat('مشتریان', clients.length), stat('جلسات', meetings.length)]), const SizedBox(height: 14), const Card(child: Padding(padding: EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مدیریت میراث ملک', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('مدیریت مهندس مجتبی صفری  •  مدیر فروش خانم طهماسبی پور'), SizedBox(height: 6), Text('مشاوران فایل‌ها را می‌بینند؛ اطلاعات حساس مالک برای فایل دیگران نمایش داده نمی‌شود.')])))]);
  Widget tile(String text, IconData icon, Color color, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(20), child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 34), const SizedBox(height: 8), Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])));
  Widget stat(String title, int value) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]))));
}

class Files extends StatefulWidget { const Files({super.key, required this.refresh}); final VoidCallback refresh; @override State<Files> createState() => _FilesState(); }
class _FilesState extends State<Files> {
  String q = '';
  @override Widget build(BuildContext context) { final list = properties.where((p) => '${p.code} ${p.title} ${p.area} ${p.price}'.contains(q)).toList(); return Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(labelText: 'جستجوی فایل', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()))), const SizedBox(width: 8), FilledButton(onPressed: () => showDialog(context: context, builder: (_) => PropertyDialog(onSave: (p) async { properties.add(p); await Store.save(); widget.refresh(); })), child: const Text('فایل جدید'))])), Expanded(child: list.isEmpty ? const Center(child: Text('هنوز فایلی ثبت نشده است')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: list.length, itemBuilder: (_, i) { final p = list[i]; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: gold, child: const Icon(Icons.home, color: navy)), title: Text('${p.code} • ${p.title}'), subtitle: Text('${p.type}  |  ${p.area} متر  |  ${p.price}'), trailing: const Icon(Icons.chevron_left), onTap: () => showDialog(context: context, builder: (_) => PropertyView(p: p)))); }))]); }
}

class PropertyDialog extends StatefulWidget { const PropertyDialog({super.key, required this.onSave}); final Future<void> Function(Property) onSave; @override State<PropertyDialog> createState() => _PropertyDialogState(); }
class _PropertyDialogState extends State<PropertyDialog> {
  final code = TextEditingController(), title = TextEditingController(), area = TextEditingController(), price = TextEditingController(), owner = TextEditingController(), phone = TextEditingController(), address = TextEditingController(); String type = 'آپارتمان';
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('ثبت فایل جدید'), content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(children: [field(code, 'کد فایل'), field(title, 'عنوان'), DropdownButtonFormField<String>(initialValue: type, items: const ['آپارتمان','ویلا','تجاری','اداری','زمین','باغ','مشارکت','پیش‌فروش'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => type = v ?? type), decoration: const InputDecoration(labelText: 'نوع ملک', border: OutlineInputBorder())), field(area, 'متراژ'), field(price, 'قیمت'), field(owner, 'نام مالک'), field(phone, 'شماره مالک'), field(address, 'آدرس')])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')), FilledButton(onPressed: () async { final p = Property(code: code.text, type: type, title: title.text, area: area.text, price: price.text, owner: owner.text, phone: phone.text, address: address.text, agent: currentUser?.name ?? ''); await widget.onSave(p); if (context.mounted) Navigator.pop(context); }, child: const Text('ثبت و ذخیره'))]);
  Widget field(TextEditingController c, String label) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
}

class PropertyView extends StatelessWidget { const PropertyView({super.key, required this.p}); final Property p; @override Widget build(BuildContext context) { final own = p.agent == currentUser?.name; final manager = currentUser?.role == 'مدیر' || currentUser?.role == 'مدیر فروش'; return AlertDialog(title: Text(p.title.isEmpty ? 'جزئیات فایل' : p.title), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('کد: ${p.code}'), Text('نوع: ${p.type}'), Text('متراژ: ${p.area}'), Text('قیمت: ${p.price}'), Text('مشاور: ${p.agent}'), if (manager || own) Text('مالک: ${p.owner}\nتلفن: ${p.phone}\nآدرس: ${p.address}') else const Text('اطلاعات حساس مالک برای شما مخفی است.')]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))]); } }

class Clients extends StatefulWidget { const Clients({super.key, required this.refresh}); final VoidCallback refresh; @override State<Clients> createState() => _ClientsState(); }
class _ClientsState extends State<Clients> { final c = TextEditingController(); @override Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(controller: c, decoration: const InputDecoration(labelText: 'نام یا شماره مشتری', border: OutlineInputBorder()))), const SizedBox(width: 8), FilledButton(onPressed: () async { if (c.text.trim().isEmpty) return; clients.add(c.text.trim()); await Store.save(); c.clear(); setState(() {}); }, child: const Text('ثبت'))])), Expanded(child: ListView(children: clients.map((x) => ListTile(leading: const Icon(Icons.person, color: gold), title: Text(x))).toList()))]); }

class Meetings extends StatefulWidget { const Meetings({super.key, required this.refresh}); final VoidCallback refresh; @override State<Meetings> createState() => _MeetingsState(); }
class _MeetingsState extends State<Meetings> { final c = TextEditingController(); @override Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(controller: c, decoration: const InputDecoration(labelText: 'قرار یا جلسه جدید', border: OutlineInputBorder()))), const SizedBox(width: 8), FilledButton(onPressed: () async { if (c.text.trim().isEmpty) return; meetings.add(c.text.trim()); await Store.save(); c.clear(); setState(() {}); }, child: const Text('ثبت'))])), Expanded(child: ListView(children: meetings.map((x) => ListTile(leading: const Icon(Icons.event, color: gold), title: Text(x))).toList()))]); }

class Commission extends StatefulWidget { const Commission({super.key}); @override State<Commission> createState() => _CommissionState(); }
class _CommissionState extends State<Commission> { final price = TextEditingController(); double rate = .005; @override Widget build(BuildContext context) { final n = double.tryParse(price.text.replaceAll(',', '')) ?? 0; final result = n * rate * 1.10; return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('محاسبه کمیسیون', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 18), TextField(controller: price, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'مبلغ معامله', border: OutlineInputBorder())), const SizedBox(height: 14), DropdownButtonFormField<double>(initialValue: rate, items: const [DropdownMenuItem(value: .005, child: Text('۰٫۵٪')), DropdownMenuItem(value: .01, child: Text('۱٪')), DropdownMenuItem(value: .25, child: Text('۲۵٪'))], onChanged: (v) => setState(() => rate = v ?? .005), decoration: const InputDecoration(labelText: 'نرخ کمیسیون', border: OutlineInputBorder())), const SizedBox(height: 22), Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('کمیسیون با ۱۰٪ مالیات: ${result.toStringAsFixed(0)}')))]); } }

class Settings extends StatefulWidget { const Settings({super.key, required this.onDark}); final ValueChanged<bool> onDark; @override State<Settings> createState() => _SettingsState(); }
class _SettingsState extends State<Settings> { bool dark = false; final oldP = TextEditingController(), newP = TextEditingController(); @override void initState() { super.initState(); Store.dark().then((v) { if (mounted) setState(() => dark = v); }); } @override Widget build(BuildContext context) => AlertDialog(title: const Text('تنظیمات'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [SwitchListTile(title: const Text('حالت تاریک'), value: dark, onChanged: (v) { setState(() => dark = v); widget.onDark(v); Store.setDark(v); }), const Divider(), TextField(controller: oldP, obscureText: true, decoration: const InputDecoration(labelText: 'رمز فعلی')), const SizedBox(height: 8), TextField(controller: newP, obscureText: true, decoration: const InputDecoration(labelText: 'رمز جدید')), const SizedBox(height: 8), FilledButton(onPressed: () async { if (currentUser == null || currentUser!.password != hashPass(oldP.text) || newP.text.length < 4) return; final list = await Store.users(); for (final u in list) { if (u.username == currentUser!.username) u.password = hashPass(newP.text); } await Store.saveUsers(list); currentUser!.password = hashPass(newP.text); if (context.mounted) Navigator.pop(context); }, child: const Text('تغییر رمز عبور'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))]); }

class UsersDialog extends StatelessWidget { const UsersDialog({super.key}); @override Widget build(BuildContext context) => AlertDialog(title: const Text('کاربران و مشاوران'), content: FutureBuilder<List<AppUser>>(future: Store.users(), builder: (_, s) { final list = s.data ?? []; return SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: list.map((u) => ListTile(leading: Icon(u.role == 'مشاور' ? Icons.person : Icons.admin_panel_settings, color: gold), title: Text(u.name), subtitle: Text('${u.username} • ${u.role}'))).toList())); }), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))]); }
