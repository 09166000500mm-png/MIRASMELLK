import 'package:flutter_test/flutter_test.dart';
import 'package:mirasmellk/main.dart';

void main() {
  testWidgets('Mirath Melk login page loads', (tester) async {
    await tester.pumpWidget(const MirathMelkApp());
    expect(find.text('میراث ملک'), findsOneWidget);
    expect(find.text('ورود به سامانه'), findsOneWidget);
  });
}
