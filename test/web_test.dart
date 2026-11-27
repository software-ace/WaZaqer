import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wazaqer/location.dart';
import 'package:wazaqer/main.dart';
import 'package:wazaqer/store.dart';
import 'package:wazaqer/web/web_shell.dart';

/// Opens the web layout at [at] in a window of [size], waiting for the
/// adhkar asset (real I/O the fake clock doesn't advance) until [ready].
Future<void> _web(
  WidgetTester tester, {
  String at = '/',
  Size size = const Size(1280, 900),
  String ready = 'الفئات',
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
  await tester.pumpWidget(
    WaZaqerApp(webRouter: buildWebRouter(initialLocation: at)),
  );
  for (var i = 0; i < 100 && find.text(ready).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home → category → group, with breadcrumbs back up', (
    tester,
  ) async {
    await _web(tester);
    expect(find.text('ابدأ من هنا'), findsOneWidget);
    await tester.tap(find.text('اليوم والليلة'));
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsOneWidget); // breadcrumb link
    await tester.tap(find.text('أذكار المساء'));
    await tester.pumpAndSettle();
    expect(find.text('أذكار المساء'), findsNWidgets(2)); // crumb and title
    await tester.tap(find.text('اليوم والليلة'));
    await tester.pumpAndSettle();
    expect(find.text('أذكار الصباح'), findsOneWidget);
  });

  testWidgets('reader: each dhikr counts on its own button and saves', (
    tester,
  ) async {
    await _web(tester, at: '/g/g1', ready: 'تم ٠ من ٣١');
    // the first dhikr is said once: one press finishes it
    final once = find.text('اضغط للعدّ · ٠ من ١').first;
    await tester.ensureVisible(once);
    await tester.pumpAndSettle();
    await tester.tap(once);
    await tester.pumpAndSettle();
    expect(find.text('تم ١ من ٣١'), findsOneWidget);
    expect(Store.s('prog:g1'), startsWith('{"i":1,"c":[1,0,'));
    // the next one (three times) is now current
    final thrice = find.text('اضغط للعدّ · ٠ من ٣').first;
    await tester.ensureVisible(thrice);
    await tester.pumpAndSettle();
    await tester.tap(thrice);
    await tester.pumpAndSettle();
    expect(find.text('اضغط للعدّ · ١ من ٣'), findsOneWidget);
  });

  testWidgets('a /g/<id>?d=<n> link opens at that dhikr', (tester) async {
    await _web(tester, at: '/g/g1?d=3', ready: 'تم ٠ من ٣١');
    expect(Store.s('prog:g1'), startsWith('{"i":2,'));
  });

  testWidgets('search address shows results; the box reflects it', (
    tester,
  ) async {
    await _web(tester, at: '/search?q=الصباح', ready: 'البحث');
    expect(find.text('نتائج البحث عن «الصباح»'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'الصباح',
    );
  });

  testWidgets('wide: links in the top bar; narrow: a bottom bar', (
    tester,
  ) async {
    await _web(tester);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.widgetWithText(TextButton, 'السبحة'), findsOneWidget);

    tester.view.physicalSize = const Size(400, 860);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('السبحة'));
    await tester.pumpAndSettle();
    expect(find.text('انقر أو اضغط Space'), findsOneWidget);
  });

  testWidgets('settings drawer: no haptics, reminders marked Android-only', (
    tester,
  ) async {
    await _web(tester);
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('التنقل التلقائي'), findsOneWidget);
    expect(find.text('الاهتزاز بعد الذكر'), findsNothing);
    // the drawer list builds lazily: scroll down to the prayer section
    await tester.drag(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    // adhan alert and salawat reminder
    expect(find.text('متاح على أندرويد فقط'), findsNWidgets(2));
  });

  testWidgets('a heart on a group list adds it to favourites on home', (
    tester,
  ) async {
    await _web(tester, at: '/c/day-night', ready: 'أذكار الصباح');
    await tester.tap(find.byTooltip('إضافة إلى المفضلة').first);
    await tester.pumpAndSettle();
    expect(Store.list('favourites'), ['g1']);
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('المفضلة'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'أذكار الصباح'), findsOneWidget);
  });

  testWidgets('prayer page swaps the location prompt for times once saved', (
    tester,
  ) async {
    await _web(tester, at: '/prayer', ready: 'استخدم موقعي الحالي');
    expect(find.text('مواقيت الصلاة'), findsNothing);
    // what the browser-location button ends with
    await saveLocation(24.7136, 46.6753, 'الرياض');
    await tester.pumpAndSettle();
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('استخدم موقعي الحالي'), findsNothing);
  });

  testWidgets(
    'typing more of a search replaces the address, no new Back step',
    (tester) async {
      final reports = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        (call) async {
          if (call.method == 'routeInformationUpdated') {
            reports.add((call.arguments as Map)['replace'] as bool);
          }
          return null;
        },
      );
      await _web(tester);
      reports.clear();
      await tester.enterText(find.byType(TextField), 'ال');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'الص');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'الصب');
      await tester.pumpAndSettle();
      // first letter: a new entry; the rest replace it
      expect(reports, [false, true, true]);
    },
  );

  testWidgets('the search box keeps focus while typing navigates', (
    tester,
  ) async {
    await _web(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    // the first letter moves from home to the search page; check focus
    // before typing again (enterText itself would re-focus the box)
    await tester.enterText(find.byType(TextField), 'ا');
    await tester.pumpAndSettle();
    final box = tester.state<EditableTextState>(find.byType(EditableText));
    expect(find.text('نتائج البحث عن «ا»'), findsOneWidget);
    expect(box.widget.focusNode.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), 'ال');
    await tester.pumpAndSettle();
    expect(box.widget.controller.text, 'ال');
    expect(box.widget.controller.selection.baseOffset, 2); // cursor at the end
  });

  testWidgets('opening a search result clears the box', (tester) async {
    await _web(tester, at: '/search?q=الصباح', ready: 'البحث');
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    expect(find.text('تم ٠ من ٣١'), findsOneWidget); // on the reader
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
