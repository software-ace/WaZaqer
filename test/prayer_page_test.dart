import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/main.dart';
import 'package:wazaqer/prayer_page.dart';
import 'package:wazaqer/store.dart';

Widget _page() => const MaterialApp(home: Scaffold(body: PrayerTimesPage()));

void main() {
  testWidgets('without a location: empty state; picking a city shows times',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    // the real app, so the shell's rebuild-on-settings wiring is covered;
    // the home tab's spinner never settles, so pump fixed frames
    Future<void> frames() async {
      await tester.pump(); // starts any route animation
      await tester.pump(const Duration(seconds: 1)); // and finishes it
    }
    await tester.pumpWidget(const WaZaqerApp());
    await tester.tap(find.text('الصلاة'));
    await frames();
    expect(find.text('حدّد موقعك لعرض مواقيت الصلاة'), findsOneWidget);
    expect(find.text('استخدم موقعي الحالي'), findsOneWidget);

    await tester.tap(find.text('اختر مدينة'));
    await frames();
    await tester.tap(find.text('الرياض'));
    await frames();
    expect(Store.s('city'), 'الرياض');
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.textContaining('أم القرى'), findsOneWidget); // auto method
  });

  testWidgets('with a location: six rows, one next prayer, auto method',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'lat': 30.0444, 'lng': 31.2357, 'city': 'القاهرة'});
    await Store.init();
    await tester.pumpWidget(_page());
    for (final name in ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.textContaining('الهيئة المصرية'), findsOneWidget);
  });
}
