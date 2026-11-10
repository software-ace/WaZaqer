import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/adhkar.dart';
import 'package:wazaqer/reminders.dart';
import 'package:wazaqer/store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
  });

  test('salawat summary reflects the stored schedule', () async {
    expect(salawatSummary(), 'التذكير متوقف');
    await Store.setB('salawatOn', true);
    expect(salawatSummary(), 'كل ساعة • ٠٨:٠٠ ص - ١٠:٠٠ م');
    await Store.setI('salawatEvery', 120);
    await Store.setI('salawatFrom', 9 * 60 + 30);
    expect(salawatSummary(arabic: false), 'كل ساعتين • 09:30 ص - 10:00 م');
  });

  test('minutes label plurals', () {
    expect(minutesLabel(5), '٥ دقائق');
    expect(minutesLabel(10), '١٠ دقائق');
    expect(minutesLabel(30), '٣٠ دقيقة');
  });

  test('home card defaults enable morning and evening reminders', () async {
    await Reminders.enableDefaults();
    expect(Store.list('remGroups'), [morningId, eveningId]);
    expect(GroupReminder.of(morningId, '').on, isTrue);
    expect(GroupReminder.of(eveningId, '').title, 'أذكار المساء');
  });

  testWidgets('reader bell sheet: enable and step the sunrise offset',
      (tester) async {
    // permission_handler's channel: notification (17) → granted (1)
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => call.method == 'requestPermissions' ? {17: 1} : 1,
    );
    const morning = DhikrGroup(
        id: morningId, title: 'أذكار الصباح', category: 'day-night', items: []);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showReminderSheet(context, morning),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('إعدادات التذكير'), findsOneWidget);
    expect(find.text('قبل الشروق بـ ٣٠ دقيقة'), findsOneWidget);

    await tester.tap(find.text('تفعيل التذكير'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('قبل الشروق بـ ٣٥ دقيقة'), findsOneWidget);

    final saved = jsonDecode(Store.s('rem:$morningId')!) as Map<String, dynamic>;
    expect(saved['on'], isTrue);
    expect(saved['m'], 35);
  });
}
