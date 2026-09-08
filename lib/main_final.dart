import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color navy = Color(0xFF071827);
const Color navy2 = Color(0xFF102B40);
const Color gold = Color(0xFFD7A84A);
const Color page = Color(0xFFF4F6F8);

void main() {
  runApp(const MirathApp());
}

class MirathApp extends StatefulWidget {
  const MirathApp({super.key});
  @override
  State<MirathApp> createState() => _MirathAppState();
}

class _MirathAppState extends State<MirathApp> {
  bool dark = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => dark = p.getBool('dark') ?? false);
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
      locale: const Locale('fa'),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: page,
        colorScheme: ColorScheme.fromSeed(seedColor: gold),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
      ),
      home: LoginPage(onDark: setDark),
    );
  }
}

Widget brandLogo(double size) {
  return SvgPicture.asset(
    'logo.svg',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onDark});
  final ValueChanged<bool> onDark;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  String error = '';

  void login() {
    if (username.text.trim() == 'admin' && password.text == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(onDark: widget.onDark),
        ),
      );
      return;
    }
    setState(() => error = 'نام کاربری یا رمز عبور اشتباه است');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [navy, navy2, page],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        brandLogo(110),
                        const Text(
                          'میراث ملک',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: navy,
                          ),
                        ),
                        const Text('مدیریت هوشمند املاک'),
                        const SizedBox(height: 8),
                        const Text(
                          'مدیریت مهندس مجتبی صفری',
                          style: TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'مدیر فروش خانم طهماسبی پور',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: username,
                          decoration: const InputDecoration(
                            labelText: 'نام کاربری',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'رمز عبور',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: login,
                            style: FilledButton.styleFrom(
                              backgroundColor: navy,
                            ),
                            child: const Text('ورود به سامانه'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ورود اولیه: admin / 1234',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onDark});
  final ValueChanged<bool> onDark;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onSelect: (i) => setState(() => selected = i)),
      const FilesPage(),
      const ClientsPage(),
      const MeetingsPage(),
      const CommissionPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              brandLogo(42),
              const SizedBox(width: 8),
              const Text(
                'میراث ملک',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => SettingsDialog(onDark: widget.onDark),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: pages[selected],
        bottomNavigationBar: NavigationBar(
          backgroundColor: navy,
          selectedIndex: selected,
          onDestinationSelected: (i) => setState(() => selected = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.dashboard, color: gold),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_work_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.home_work, color: gold),
              label: 'فایل‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: Colors.white),
              selectedIcon: Icon(Icons.people, color: gold),
              label: 'مشتریان',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.event, color: gold),
              label: 'جلسات',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined, color: Colors.white),
              selectedIcon: Icon(Icons.calculate, color: gold),
              label: 'کمیسیون',
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onSelect});
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [navy, navy2]),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: gold,
                child: brandLogo(46),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'سلام مجتبی\nمدیریت هوشمند دپارتمان املاک',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            HomeCard(
              title: 'ثبت فایل جدید',
              icon: Icons.add_home_work,
              color: Colors.green,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const AddFileDialog(),
              ),
            ),
            HomeCard(
              title: 'لیست فایل‌ها',
              icon: Icons.view_list,
              color: Colors.blue,
              onTap: () => onSelect(1),
            ),
            HomeCard(
              title: 'مشتریان',
              icon: Icons.people,
              color: Colors.deepPurple,
              onTap: () => onSelect(2),
            ),
            HomeCard(
              title: 'جلسات و قرارها',
              icon: Icons.calendar_month,
              color: Colors.orange,
              onTap: () => onSelect(3),
            ),
            HomeCard(
              title: 'مشاوران',
              icon: Icons.groups,
              color: Colors.teal,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const UsersDialog(),
              ),
            ),
            HomeCard(
              title: 'تنظیمات',
              icon: Icons.settings,
              color: Colors.blueGrey,
              onTap: () => showDialog(
                context: context,
                builder: (_) => SettingsDialog(onDark: (_) {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مدیریت میراث ملک',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('مدیریت مهندس مجتبی صفری'),
                Text('مدیر فروش خانم طهماسبی پور'),
                SizedBox(height: 6),
                Text(
                  'مشاوران فایل‌های یکدیگر را می‌بینند؛ اطلاعات حساس مالک دیگران مخفی است.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 34),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'فایل‌های املاک',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddFileDialog(),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('ثبت فایل جدید'),
        ),
        const SizedBox(height: 12),
        for (int i = 1; i <= 3; i++)
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: gold,
                child: Icon(Icons.home, color: navy),
              ),
              title: Text('فایل نمونه $i'),
              subtitle: const Text('آپارتمان • ۱۲۰ متر • قیمت توافقی'),
              trailing: const Icon(Icons.chevron_left),
            ),
          ),
      ],
    );
  }
}

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'مشتریان',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (int i = 1; i <= 3; i++)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: gold),
              title: Text('مشتری نمونه $i'),
              subtitle: const Text('شماره تماس ثبت شده'),
            ),
          ),
      ],
    );
  }
}

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'جلسات و قرارها',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (int i = 1; i <= 3; i++)
          Card(
            child: ListTile(
              leading: const Icon(Icons.event, color: gold),
              title: Text('جلسه نمونه $i'),
              subtitle: const Text('امروز - ساعت ۱۸:۰۰'),
            ),
          ),
      ],
    );
  }
}

class CommissionPage extends StatelessWidget {
  const CommissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'محاسبه کمیسیون',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        const TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'مبلغ معامله',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('نرخ پایه: ۰٫۵٪ + ۱۰٪ مالیات'),
          ),
        ),
      ],
    );
  }
}

class AddFileDialog extends StatelessWidget {
  const AddFileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ثبت فایل جدید'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'عنوان ملک',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'متراژ',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'قیمت',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'نام مالک',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'شماره مالک',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: null,
          child: Text('انصراف'),
        ),
        FilledButton(
          onPressed: null,
          child: Text('ثبت و ذخیره'),
        ),
      ],
    );
  }
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, required this.onDark});
  final ValueChanged<bool> onDark;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تنظیمات'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('مدیریت مهندس مجتبی صفری')),
          const ListTile(title: Text('مدیر فروش خانم طهماسبی پور')),
          SwitchListTile(
            value: dark,
            onChanged: (value) {
              setState(() => dark = value);
              widget.onDark(value);
            },
            title: const Text('حالت تاریک'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('بستن'),
        ),
      ],
    );
  }
}

class UsersDialog extends StatelessWidget {
  const UsersDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('کاربران و مشاوران'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.admin_panel_settings, color: gold),
            title: Text('مهندس مجتبی صفری'),
            subtitle: Text('مدیر'),
          ),
          ListTile(
            leading: Icon(Icons.admin_panel_settings, color: gold),
            title: Text('خانم طهماسبی پور'),
            subtitle: Text('مدیر فروش'),
          ),
          ListTile(
            leading: Icon(Icons.person, color: gold),
            title: Text('مشاور اول'),
            subtitle: Text('مشاور'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('بستن'),
        ),
      ],
    );
  }
}
