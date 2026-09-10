import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const ManeshiApp());

class ManeshiApp extends StatelessWidget {
  const ManeshiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'منشی تلفنی میراث ملک',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final phone = TextEditingController();
  String status = 'آماده تماس با مشتری';
  bool calling = false;

  final questions = const [
    'نوع ملک چیست؟',
    'آدرس کامل ملک را لطفاً بفرمایید.',
    'متراژ ملک چند متر است؟',
    'سال ساخت ملک چه سالی است؟',
    'ملک در چه طبقه‌ای قرار دارد؟',
    'ساختمان چند واحد دارد؟',
    'قیمت موردنظر شما چقدر است؟',
    'توضیحات یا شرایط خاصی دارید؟',
  ];

  Future<void> callCustomer() async {
    final number = phone.text.trim();
    if (number.isEmpty) {
      setState(() => status = 'لطفاً شماره مشتری را وارد کنید.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      setState(() {
        calling = true;
        status = 'در حال برقراری تماس با $number';
      });
      await launchUrl(uri);
    } else {
      setState(() => status = 'امکان برقراری تماس از این دستگاه وجود ندارد.');
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('منشی تلفنی میراث ملک')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.support_agent, size: 72),
              const SizedBox(height: 8),
              const Text('منشی تلفنی املاک', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('شماره مشتری را وارد کنید تا تماس از گوشی شما برقرار شود.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'شماره موبایل مشتری',
                  hintText: '0912xxxxxxxx',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: calling ? null : callCustomer,
                icon: const Icon(Icons.call),
                label: Text(calling ? 'تماس برقرار شد' : 'تماس با مشتری'),
              ),
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(status))),
              const SizedBox(height: 24),
              const Text('سؤالات منشی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...questions.asMap().entries.map((e) => ListTile(
                    leading: CircleAvatar(child: Text('${e.key + 1}')),
                    title: Text(e.value),
                  )),
            ],
          ),
        ),
      );
}
