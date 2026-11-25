import 'package:flutter/material.dart';
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
    await tester.pump(); // build
    await tester.pump(const Duration(seconds: 1)); // asset load
    expect(find.text('وَذَكِر'), findsOneWidget);
    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    // category grid loaded from the asset ('all' tile is on-screen)
  });

  testWidgets('app lays out right-to-left for Arabic', (tester) async {
    // Without GlobalWidgetsLocalizations the app silently falls back to LTR.
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    await tester.pumpWidget(const WaZaqerApp());
    await tester.pump();
    final ctx = tester.element(find.text('الأذكار').first);
    expect(Directionality.of(ctx), TextDirection.rtl);
  });
}
