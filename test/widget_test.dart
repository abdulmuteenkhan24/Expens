import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expens/main.dart';
import 'package:expens/services/sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('App loads home with What You Have', (tester) async {
    await tester.pumpWidget(const ExpensApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('What You Have'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Money'), findsWidgets);
  });

  test('SMS parser detects ATM cash withdrawal card SMS', () {
    const raw =
        'Your Neo Islamic MasterCard Debit Card ending with 2968 was used for a cash withdrawal of PKR 500.00 at MAIN BAZAR HARIPUR GRG, HARIPUR,  on 02-AUG-2026 07:25 PM.';
    final p = SmsParser.parse(raw);
    expect(p, isNotNull);
    expect(p!.amount, 500);
    expect(p.categoryId, 'atm');
  });
}
