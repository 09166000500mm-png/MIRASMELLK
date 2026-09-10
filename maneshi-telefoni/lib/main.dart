import 'package:flutter/material.dart';

void main() => runApp(const ManeshiApp());

class ManeshiApp extends StatelessWidget {
  const ManeshiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'منشی تلفنی میراث ملک',
    theme: ThemeData(useMaterial3: true, fontFamily: 'sans'),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final phone = TextEditingController();
  bool loading = false;
  String status = 'آماده دریافت شماره مشتری';

  void startCall() {
    if (phone.text.trim().isEmpty) {
      setState(() => status = 'لطفاً شماره مشتری را وارد کنید');
      return;
    }
    setState(() { loading = true; status = 'درخواست تماس ثبت شد؛ اتصال سرویس تلفنی لازم است.'; });
    Future.delayed(const Duration(seconds: 1), () => setState(() => loading = false));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('منشی تلفنی میراث ملک')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('تماس خودکار با مشتری', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('منشی تلفنی برای جمع‌آوری مشخصات ملک.'),
        const SizedBox(height: 24),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل مشتری', hintText: 'مثلاً 0912... ', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: loading ? null : startCall, icon: const Icon(Icons.call), label: Text(loading ? 'در حال ثبت...' : 'شروع تماس واقعی')),
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(status))),
        const SizedBox(height: 20),
        const Text('سؤالات منشی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('نوع ملک • آدرس کامل • متراژ • سال ساخت • طبقه • تعداد واحد • قیمت • توضیحات و شرایط'),
      ]),
    ),
  );
}
