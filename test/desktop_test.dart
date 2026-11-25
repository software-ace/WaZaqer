import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wazaqer/location.dart';
import 'package:wazaqer/main.dart';
import 'package:wazaqer/store.dart';

/// Pumps the app in a window of [size] and waits for the adhkar asset,
/// which is real I/O the fake clock doesn't advance.
Future<void> _app(
  WidgetTester tester, {
  Size size = const Size(1280, 800),
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await Store.init();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // rootBundle caches the asset future across tests; one started under an
  // earlier test's fake clock never completes, so drop it
  rootBundle.evict('assets/adhkar.json');
  await tester.pumpWidget(const WaZaqerApp());
  for (var i = 0; i < 100 && find.text('الفئات').evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _openMorning(WidgetTester tester) async {
  await tester.tap(find.text('اليوم والليلة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('أذكار الصباح'));
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a wide window gets the desktop layout, a narrow one mobile', (
    tester,
  ) async {
    await _app(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('reader: Space counts and saves, arrows move, F hides lists', (
    tester,
  ) async {
    await _app(tester);
    await _openMorning(tester);
    expect(find.text('١ من ٣١'), findsOneWidget);

    // the first dhikr is said once: Space finishes it and moves on
    await _key(tester, LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('٢ من ٣١'), findsOneWidget);
    expect(Store.s('prog:g1'), startsWith('{"i":1,"c":[1,0,'));

    // reading runs right to left: ← is next, → is previous
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text('٣ من ٣١'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('٢ من ٣١'), findsOneWidget);

    expect(find.text('الفئات'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.keyF);
    expect(find.text('الفئات'), findsNothing);
    await _key(tester, LogicalKeyboardKey.keyF);
    expect(find.text('الفئات'), findsOneWidget);
  });

  testWidgets('the opened group comes back on the next launch', (tester) async {
    await _app(
      tester,
      prefs: {
        'flutter.deskCat': 'day-night',
        'flutter.deskGroup': 'g2',
        // morning: first two adhkar finished (said once, then three times)
        'flutter.prog:g1': '{"i":2,"c":[1,3,1]}',
      },
    );
    // title in the group list and in the reader header
    expect(find.text('أذكار المساء'), findsNWidgets(2));
    // another group's progress is read from storage for its list entry
    expect(find.text('٣١ ذكرًا · تم ٢ من ٣١'), findsOneWidget);
  });

  testWidgets('a heart in the group list updates the favourites count', (
    tester,
  ) async {
    await _app(tester);
    await tester.tap(find.text('اليوم والليلة'));
    await tester.pumpAndSettle();
    final favRow = find.ancestor(
      of: find.text('المفضلة'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: favRow, matching: find.text('—')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('إضافة إلى المفضلة').first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: favRow, matching: find.text('١')),
      findsOneWidget,
    );
    expect(Store.list('favourites'), ['g1']);
  });

  testWidgets('top-bar search replaces the group list with results', (
    tester,
  ) async {
    await _app(tester);
    await tester.enterText(find.byType(TextField), 'الصباح');
    await tester.pumpAndSettle();
    expect(find.text('نتائج البحث'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
  });

  testWidgets('السبحة counts with Space and Ctrl+2 reaches it', (tester) async {
    await _app(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('انقر أو اضغط Space'), findsOneWidget);

    await _key(tester, LogicalKeyboardKey.space);
    await _key(tester, LogicalKeyboardKey.space);
    expect(Store.i('tasbeehCount'), 2);
  });

  testWidgets('settings: no haptics, reminders marked Android-only', (
    tester,
  ) async {
    await _app(tester);
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تصفح الأذكار'));
    await tester.pumpAndSettle();
    expect(find.text('التنقل التلقائي'), findsOneWidget);
    expect(find.text('الاهتزاز بعد الذكر'), findsNothing);

    // tests run on the host (not Android), where reminders can't fire
    await tester.tap(find.text('مواقيت الصلاة'));
    await tester.pumpAndSettle();
    expect(find.text('متاح على أندرويد فقط'), findsOneWidget);
  });

  testWidgets('settings changes reach the tabs (location, switches)', (
    tester,
  ) async {
    await _app(tester);
    await tester.tap(find.text('الصلاة والقبلة'));
    await tester.pumpAndSettle();
    expect(find.text('استخدم موقعي الحالي'), findsOneWidget);
    await saveLocation(24.7136, 46.6753, 'الرياض');
    await tester.pumpAndSettle();
    expect(find.text('مواقيت الصلاة'), findsOneWidget);

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تصفح الأذكار'));
    await tester.pumpAndSettle();
    final auto = find.widgetWithText(SwitchListTile, 'التنقل التلقائي');
    expect(tester.widget<SwitchListTile>(auto).value, isTrue);
    await tester.tap(auto);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(auto).value, isFalse);
  });

  testWidgets('picking a category ends an active search', (tester) async {
    await _app(tester);
    await tester.enterText(find.byType(TextField), 'الصباح');
    await tester.pumpAndSettle();
    expect(find.text('نتائج البحث'), findsOneWidget);
    await tester.tap(find.text('الوضوء والصلاة'));
    await tester.pumpAndSettle();
    expect(find.text('نتائج البحث'), findsNothing);
    expect(find.text('الذكر قبل الوضوء'), findsOneWidget);
  });

  testWidgets('a remembered category that no longer exists falls back', (
    tester,
  ) async {
    await _app(tester, prefs: {'flutter.deskCat': 'removed-in-an-update'});
    expect(tester.takeException(), isNull);
    // the first category: its row in the list and the group-pane title
    expect(find.text('جميع الأذكار'), findsNWidgets(2));
  });
}
