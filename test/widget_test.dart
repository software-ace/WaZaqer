import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/hijri.dart';
import 'package:wazaqer/main.dart';
import 'package:wazaqer/store.dart';

void main() {
  test('Hijri conversion matches a known date', () {
    // 9 Ramadan 1447 AH = 26 Feb 2026.
    expect(gregorianToHijri(DateTime(2026, 2, 26)), [1447, 9, 9]);
  });

  testWidgets('app shell opens on the adhkar tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    await tester.pumpWidget(const WaZaqerApp());
    await tester.pumpAndSettle();
    expect(find.text('وَذَكِر'), findsOneWidget);
    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
