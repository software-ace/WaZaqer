import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/main.dart';
import 'package:wazaqer/settings.dart';
import 'package:wazaqer/store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
  });

  test('About version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: ([^+\s]+)', multiLine: true).firstMatch(pubspec)![1],
        appVersion);
  });

  Future<void> openSettings(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WaZaqerApp());
    await tester.pump();
    await tester.tap(find.text('الإعدادات').last);
    await tester.pump();
  }

  testWidgets('theme mode and digits apply app-wide', (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('داكن'));
    await tester.pump();
    expect(Store.i('themeMode'), 2);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);

    await tester.tap(find.text('أرقام عربية'));
    await tester.pump();
    expect(Store.b('arabicDigits', def: true), isFalse);
    expect(find.text('100٪'), findsOneWidget); // font size shows Latin digits now
  });

  testWidgets('font size steps by 10%', (tester) async {
    await openSettings(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    expect(Store.i('fontScale'), 110);
    expect(find.text('١١٠٪'), findsOneWidget);
  });

  testWidgets('reset clears settings but keeps favourites', (tester) async {
    await Store.setB('tashkeel', false);
    await Store.setList('favourites', ['g1']);
    await openSettings(tester);
    // the home tab's loading spinner never settles, so pump fixed frames
    await tester.tap(find.byTooltip('إعادة ضبط الإعدادات'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('إعادة الضبط'));
    await tester.pump(const Duration(seconds: 1));
    expect(Store.b('tashkeel', def: true), isTrue);
    expect(Store.list('favourites'), ['g1']);
  });
}
