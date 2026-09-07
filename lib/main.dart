import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MirathMelkApp());

class MirathMelkApp extends StatelessWidget {
  const MirathMelkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'میراث ملک',
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff123b72))),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.apartment, size: 80),
              const SizedBox(height: 12),
              const Text('میراث ملک', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('سیستم مدیریت هوشمند دپارتمان املاک'),
              const SizedBox(height: 32),
              TextField(controller: user, decoration: const InputDecoration(labelText: 'نام کاربری', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                controller: pass,
                obscureText: hidden,
                decoration: InputDecoration(
                  labelText: 'رمز عبور',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility : Icons.visibility_off)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard())), child: const Text('ورود به سامانه'))),
            ]),
          ),
        ),
      ),
    );
  }
}

class Property {
  String code, type, title, address, owner, phone, price, area, rooms, year, link, desc;
  Map<String, String> options;

  Property({
    required this.code,
    required this.type,
    required this.title,
    required this.address,
    required this.owner,
    required this.phone,
    required this.price,
    required this.area,
    required this.rooms,
    required this.year,
    required this.link,
    required this.desc,
    required this.options,
  });
}

final List<Property> properties = [];
final List<String> clients = [];
final List<String> meetings = [];

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      PropertyPage(onChanged: () => setState(() {})),
      const ClientPage(),
      const CommissionPage(),
      const MeetingPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('میراث ملک'), centerTitle: true),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.home_work), label: 'ثبت فایل'),
          NavigationDestination(icon: Icon(Icons.people), label: 'مشتریان'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'کمیسیون'),
          NavigationDestination(icon: Icon(Icons.event), label: 'جلسات'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('داشبورد مدیریت', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _box('فایل ملکی', properties.length, Icons.home_work),
        _box('مشتری', clients.length, Icons.people),
        _box('جلسه', meetings.length, Icons.event),
        _box('کمیسیون', null, Icons.calculate),
      ]),
      const SizedBox(height: 20),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('ثبت فایل جدید', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('اطلاعات اصلی را وارد کنید و امکانات و ویژگی‌های ملک را فقط با تیک انتخاب کنید. برای هر گزینه انتخاب‌شده، توضیح اختیاری کنار آن قرار دارد.'),
      ]))),
    ]);
  }

  Widget _box(String title, int? value, IconData icon) => SizedBox(width: 165, height: 110, child: Card(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 32), Text(title), if (value != null) Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])));
}

class PropertyPage extends StatefulWidget {
  final VoidCallback onChanged;
  const PropertyPage({super.key, required this.onChanged});
  @override
  State<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  final search = TextEditingController();
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
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
      ])),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: types.map((t) => Padding(padding: const EdgeInsets.only(left: 6), child: ChoiceChip(label: Text(t), selected: filter == t, onSelected: (_) => setState(() => filter = t)))).toList())),
      const SizedBox(height: 8),
      Expanded(child: list.isEmpty ? const Center(child: Text('هنوز فایلی ثبت نشده است')) : ListView.builder(itemCount: list.length, itemBuilder: (_, i) {
        final p = list[i];
        return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(
          title: Text('${p.code} - ${p.title}'),
          subtitle: Text('${p.type} | ${p.area} متر | ${p.price}\n${p.address}'),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('ویرایش')), PopupMenuItem(value: 'sms', child: Text('پیامک'))], onSelected: (v) async {
            if (v == 'edit') _edit(p);
            if (v == 'sms' && p.phone.trim().isNotEmpty) {
              final body = Uri.encodeComponent('سلام، در خصوص فایل ${p.title} از دپارتمان میراث ملک با شما تماس می‌گیریم.');
              await launchUrl(Uri.parse('sms:${p.phone}?body=$body'));
            }
          }),
        ));
      })),
    ]);
  }

  void _add() => showDialog(context: context, builder: (_) => PropertyForm(onSave: (p) { properties.add(p); setState(() {}); widget.onChanged(); }));
  void _edit(Property p) => showDialog(context: context, builder: (_) => PropertyForm(initial: p, onSave: (updated) { final i = properties.indexOf(p); if (i >= 0) properties[i] = updated; setState(() {}); widget.onChanged(); }));
}

class PropertyForm extends StatefulWidget {
  final Property? initial;
  final void Function(Property) onSave;
  const PropertyForm({super.key, this.initial, required this.onSave});
  @override
  State<PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends State<PropertyForm> {
  late final Map<String, TextEditingController> fields;
  late String type;
  late Map<String, bool> checked;
  late Map<String, TextEditingController> notes;

  final fieldNames = const ['کد فایل', 'عنوان', 'آدرس', 'منطقه/محله', 'نام مالک', 'تلفن مالک', 'قیمت کل', 'قیمت هر متر', 'متراژ', 'تعداد اتاق', 'سال ساخت', 'طبقه', 'لینک دیوار', 'توضیحات کلی'];
  final optionGroups = const {
    'نوع معامله': ['فروش', 'رهن کامل', 'رهن و اجاره', 'اجاره', 'معاوضه', 'مشارکت در ساخت', 'پیش‌فروش'],
    'وضعیت آگهی': ['شخصی / مالک', 'مشاور املاک', 'سازنده', 'تعاونی'],
    'امکانات آپارتمان': ['پارکینگ', 'انباری', 'آسانسور', 'بالکن', 'لابی', 'نگهبانی', 'استخر', 'سونا', 'جکوزی', 'روف‌گاردن', 'درب ضدسرقت', 'کولرگازی', 'پکیج', 'شوفاژ', 'گرمایش از کف'],
    'ویژگی واحد': ['فول امکانات', 'مبله', 'نوساز', 'بازسازی‌شده', 'تک‌واحدی', 'دوکله', 'نورگیر', 'جنوبی', 'شمالی', 'مستر', 'کلوزت', 'پنت‌هاوس', 'قابلیت تبدیل', 'سند آماده'],
    'وضعیت سند و ملک': ['سند تک‌برگ', 'سند شش‌دانگ', 'وکالتی', 'قولنامه‌ای', 'سند در رهن', 'پایان‌کار دارد', 'عدم خلاف دارد', 'جواز ساخت دارد', 'تخلیه فوری', 'مالک حاضر به معامله'],
    'ویژگی زمین / باغ / ویلا': ['بر اصلی', 'بر دو نبش', 'دسترسی آسفالت', 'آب', 'برق', 'گاز', 'چاه آب', 'استخر', 'باغ میوه', 'دیوارکشی', 'سنددار', 'داخل بافت', 'خارج بافت', 'قابلیت ساخت'],
  };

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    type = p?.type ?? 'آپارتمان';
    fields = {for (final n in fieldNames) n: TextEditingController(text: _value(p, n))};
    checked = {};
    notes = {};
    for (final group in optionGroups.values) {
      for (final option in group) {
        checked[option] = p?.options.containsKey(option) ?? false;
        notes[option] = TextEditingController(text: p?.options[option] ?? '');
      }
    }
  }

  String _value(Property? p, String key) {
    if (p == null) return '';
    return {'کد فایل': p.code, 'عنوان': p.title, 'آدرس': p.address, 'منطقه/محله': _areaText(p), 'نام مالک': p.owner, 'تلفن مالک': p.phone, 'قیمت کل': p.price, 'قیمت هر متر': _perMeter(p), 'متراژ': p.area, 'تعداد اتاق': p.rooms, 'سال ساخت': p.year, 'طبقه': _floorText(p), 'لینک دیوار': p.link, 'توضیحات کلی': p.desc}[key] ?? '';
  }

  String _areaText(Property p) => p.options['منطقه/محله'] ?? '';
  String _floorText(Property p) => p.options['طبقه'] ?? '';
  String _perMeter(Property p) => p.options['قیمت هر متر'] ?? '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'ثبت فایل جدید' : 'ویرایش فایل'),
      content: SizedBox(width: 620, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('اطلاعات اصلی', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _text('کد فایل'), _text('عنوان'), _text('آدرس'), _text('منطقه/محله'), _text('نام مالک'), _text('تلفن مالک'), _text('قیمت کل'), _text('قیمت هر متر'), _text('متراژ'), _text('تعداد اتاق'), _text('سال ساخت'), _text('طبقه'), _text('لینک دیوار'), _text('توضیحات کلی', lines: 3),
        const SizedBox(height: 12),
        _typeSection(),
        for (final entry in optionGroups.entries) _optionSection(entry.key, entry.value),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        FilledButton(onPressed: _save, child: const Text('ذخیره فایل')),
      ],
    );
  }

  Widget _text(String name, {int lines = 1}) => Padding(padding: const EdgeInsets.only(top: 8), child: TextField(controller: fields[name], maxLines: lines, keyboardType: ['تلفن مالک', 'قیمت کل', 'قیمت هر متر', 'متراژ', 'تعداد اتاق', 'سال ساخت', 'طبقه'].contains(name) ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: name, border: const OutlineInputBorder())));

  Widget _typeSection() => Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('نوع ملک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    ...['آپارتمان', 'ویلا', 'تجاری', 'اداری', 'زمین', 'باغ', 'مشارکت', 'پیش‌فروش'].map((v) => CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero, value: type == v, title: Text(v), onChanged: (on) { if (on == true) setState(() => type = v); })),
  ])));

  Widget _optionSection(String title, List<String> options) => Card(margin: const EdgeInsets.only(top: 10), child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    const SizedBox(height: 4),
    ...options.map((option) => _optionTile(option)),
  ])));

  Widget _optionTile(String option) => Column(children: [
    CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: checked[option] ?? false,
      title: Text(option),
      onChanged: (v) => setState(() => checked[option] = v ?? false),
    ),
    if (checked[option] == true) Padding(padding: const EdgeInsets.only(right: 42, bottom: 6), child: TextField(controller: notes[option], maxLines: 1, decoration: const InputDecoration(labelText: 'توضیح اختیاری', hintText: 'در صورت نیاز توضیح را وارد کنید', border: OutlineInputBorder(), isDense: true))),
  ]);

  void _save() {
    final options = <String, String>{};
    for (final option in checked.keys) {
      if (checked[option] == true) options[option] = notes[option]!.text.trim();
    }
    options['منطقه/محله'] = fields['منطقه/محله']!.text.trim();
    options['قیمت هر متر'] = fields['قیمت هر متر']!.text.trim();
    options['طبقه'] = fields['طبقه']!.text.trim();
    final p = Property(
      code: fields['کد فایل']!.text.trim(), title: fields['عنوان']!.text.trim(), address: fields['آدرس']!.text.trim(), owner: fields['نام مالک']!.text.trim(), phone: fields['تلفن مالک']!.text.trim(), price: fields['قیمت کل']!.text.trim(), area: fields['متراژ']!.text.trim(), rooms: fields['تعداد اتاق']!.text.trim(), year: fields['سال ساخت']!.text.trim(), link: fields['لینک دیوار']!.text.trim(), desc: fields['توضیحات کلی']!.text.trim(), type: type, options: options,
    );
    widget.onSave(p);
    Navigator.pop(context);
  }
}

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});
  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'نام مشتری', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل', border: OutlineInputBorder()))), const SizedBox(width: 8), IconButton.filled(onPressed: () { if (phone.text.trim().isNotEmpty) setState(() => clients.add('${name.text.trim()} - ${phone.text.trim()}')); }, icon: const Icon(Icons.add))])),
      Expanded(child: ListView.builder(itemCount: clients.length, itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.person), title: Text(clients[i])))),
    ]);
  }
}

class CommissionPage extends StatefulWidget {
  const CommissionPage({super.key});
  @override
  State<CommissionPage> createState() => _CommissionPageState();
}

class _CommissionPageState extends State<CommissionPage> {
  final amount = TextEditingController();
  String rate = '0.5%';
  @override
  Widget build(BuildContext context) {
    final a = double.tryParse(amount.text.replaceAll(',', '')) ?? 0;
    final r = double.tryParse(rate.replaceAll('%', '')) ?? 0;
    final base = a * r / 100;
    final vat = base * .10;
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('محاسبه کمیسیون', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      TextField(controller: amount, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ معامله', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: rate, items: const ['0.5%', '1%', '25%'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => rate = v); }, decoration: const InputDecoration(labelText: 'نرخ کمیسیون', border: OutlineInputBorder())),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('کمیسیون: ${base.toStringAsFixed(0)}\nمالیات ۱۰٪: ${vat.toStringAsFixed(0)}\nجمع: ${(base + vat).toStringAsFixed(0)}'))),
    ]);
  }
}

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});
  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  final title = TextEditingController();
  final date = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('جلسات و قرارها', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان جلسه', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: date, decoration: const InputDecoration(labelText: 'تاریخ و ساعت', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      FilledButton(onPressed: () { if (title.text.trim().isNotEmpty) setState(() => meetings.add('${title.text.trim()} - ${date.text.trim()}')); }, child: const Text('ثبت جلسه')),
      const SizedBox(height: 12),
      ...meetings.map((m) => Card(child: ListTile(leading: const Icon(Icons.event), title: Text(m)))),
    ]);
  }
}
