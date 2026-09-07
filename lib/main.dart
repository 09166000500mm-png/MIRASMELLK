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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff123b72)),
      ),
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
  final username = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.apartment, size: 82, color: Color(0xff123b72)),
                const SizedBox(height: 12),
                const Text('میراث ملک', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('سیستم مدیریت هوشمند دپارتمان املاک'),
                const SizedBox(height: 35),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(
                    labelText: 'نام کاربری',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                      icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Dashboard()),
                      );
                    },
                    child: const Text('ورود به سامانه', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Property {
  String code;
  String type;
  String title;
  String address;
  String owner;
  String phone;
  String price;
  String area;
  String rooms;
  String year;
  String link;
  String desc;

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
  });
}

final List<Property> properties = [];
final List<String> clients = [];

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
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.home_work), label: 'فایل‌ها'),
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
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('داشبورد مدیریت', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _card('فایل ملکی', '${properties.length}', Icons.home_work),
            _card('مشتری', '${clients.length}', Icons.people),
            _card('جلسات', 'تقویم', Icons.event),
            _card('کمیسیون', 'محاسبه', Icons.calculate),
          ],
        ),
        const SizedBox(height: 20),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('امکانات سامانه', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('ثبت و ویرایش فایل، جستجوی مشتری، محاسبه کمیسیون، ثبت جلسات و آماده‌سازی پیام برای مشتری.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return SizedBox(
      width: 170,
      height: 115,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34),
            Text(title),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
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

  final types = const ['همه', 'آپارتمان', 'ویلا', 'تجاری', 'زمین', 'باغ', 'مشارکت', 'پیش‌فروش'];

  @override
  Widget build(BuildContext context) {
    final list = properties.where((property) {
      final text = '${property.title} ${property.code} ${property.address} ${property.owner}'.toLowerCase();
      return (filter == 'همه' || property.type == filter) && text.contains(search.text.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'جستجو',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PropertyForm(
                      onSave: (property) {
                        properties.add(property);
                        setState(() {});
                        widget.onChanged();
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle, size: 34),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: types.map((type) {
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(type),
                  selected: filter == type,
                  onSelected: (_) => setState(() => filter = type),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('هنوز فایلی ثبت نشده است'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, index) {
                    final property = list[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: ListTile(
                        title: Text('${property.code} - ${property.title}'),
                        subtitle: Text('${property.type} | ${property.area} متر | ${property.price}\n${property.address}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                            PopupMenuItem(value: 'sms', child: Text('پیامک')),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              showDialog(
                                context: context,
                                builder: (_) => PropertyForm(
                                  initial: property,
                                  onSave: (updated) {
                                    final position = properties.indexOf(property);
                                    if (position >= 0) properties[position] = updated;
                                    setState(() {});
                                    widget.onChanged();
                                  },
                                ),
                              );
                            }
                            if (value == 'sms' && property.phone.isNotEmpty) {
                              final body = Uri.encodeComponent(
                                'سلام، در خصوص فایل ${property.title} از دپارتمان میراث ملک با شما تماس می‌گیریم.',
                              );
                              await launchUrl(Uri.parse('sms:${property.phone}?body=$body'));
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
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

  final fieldNames = const [
    'کد فایل',
    'عنوان',
    'آدرس',
    'نام مالک',
    'تلفن مالک',
    'قیمت',
    'متراژ',
    'تعداد اتاق',
    'سال ساخت',
    'لینک دیوار',
    'توضیحات',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    type = p?.type ?? 'آپارتمان';
    fields = {
      for (final name in fieldNames)
        name: TextEditingController(text: _value(p, name)),
    };
  }

  String _value(Property? p, String key) {
    if (p == null) return '';
    return {
          'کد فایل': p.code,
          'عنوان': p.title,
          'آدرس': p.address,
          'نام مالک': p.owner,
          'تلفن مالک': p.phone,
          'قیمت': p.price,
          'متراژ': p.area,
          'تعداد اتاق': p.rooms,
          'سال ساخت': p.year,
          'لینک دیوار': p.link,
          'توضیحات': p.desc,
        }[key] ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'ثبت فایل جدید' : 'ویرایش فایل'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const ['آپارتمان', 'ویلا', 'تجاری', 'زمین', 'باغ', 'مشارکت', 'پیش‌فروش']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => type = value);
                },
                decoration: const InputDecoration(labelText: 'نوع ملک'),
              ),
              ...fields.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: entry.value,
                    maxLines: entry.key == 'توضیحات' ? 3 : 1,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        FilledButton(
          onPressed: () {
            final property = Property(
              code: fields['کد فایل']!.text,
              type: type,
              title: fields['عنوان']!.text,
              address: fields['آدرس']!.text,
              owner: fields['نام مالک']!.text,
              phone: fields['تلفن مالک']!.text,
              price: fields['قیمت']!.text,
              area: fields['متراژ']!.text,
              rooms: fields['تعداد اتاق']!.text,
              year: fields['سال ساخت']!.text,
              link: fields['لینک دیوار']!.text,
              desc: fields['توضیحات']!.text,
            );
            widget.onSave(property);
            Navigator.pop(context);
          },
          child: const Text('ذخیره'),
        ),
      ],
    );
  }
}

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'شماره / نام مشتری',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                clients.add(controller.text.trim());
                controller.clear();
                setState(() {});
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('ثبت مشتری'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: clients.length,
              itemBuilder: (_, index) => Card(
                child: ListTile(
                  title: Text(clients[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.sms),
                    onPressed: () => launchUrl(Uri.parse('sms:${clients[index]}')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommissionPage extends StatefulWidget {
  const CommissionPage({super.key});

  @override
  State<CommissionPage> createState() => _CommissionPageState();
}

class _CommissionPageState extends State<CommissionPage> {
  final price = TextEditingController();
  double rate = .005;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(price.text.replaceAll(',', '')) ?? 0;
    final base = amount * rate;
    final vat = base * .1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: price,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ معامله (تومان)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<double>(
            initialValue: rate,
            items: const [
              DropdownMenuItem(value: .005, child: Text('۰.۵٪')),
              DropdownMenuItem(value: .25, child: Text('۲۵٪')),
              DropdownMenuItem(value: .01, child: Text('۱٪')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => rate = value);
            },
            decoration: const InputDecoration(labelText: 'درصد کمیسیون'),
          ),
          const SizedBox(height: 25),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('کمیسیون: ${base.toStringAsFixed(0)} تومان'),
                  Text('مالیات ۱۰٪: ${vat.toStringAsFixed(0)} تومان'),
                  Text(
                    'جمع: ${(base + vat).toStringAsFixed(0)} تومان',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
  final items = <String>[];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'عنوان جلسه', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: date,
            decoration: const InputDecoration(labelText: 'تاریخ و ساعت', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isNotEmpty) {
                setState(() {
                  items.add('${title.text.trim()} - ${date.text.trim()}');
                  title.clear();
                  date.clear();
                });
              }
            },
            child: const Text('ثبت جلسه'),
          ),
          Expanded(
            child: ListView(
              children: items
                  .map((item) => Card(child: ListTile(leading: const Icon(Icons.event), title: Text(item))))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
