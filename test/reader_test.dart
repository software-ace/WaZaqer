import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/adhkar.dart';
import 'package:wazaqer/reader.dart';
import 'package:wazaqer/store.dart';

final group = const DhikrGroup(
  id: 'g1',
  title: 'أذكار الصباح',
  category: 'morning',
  items: [
    DhikrItem(text: 'أصبحنا وأصبح الملكُ لله', count: 3, source: 'مسلم'),
    DhikrItem(text: 'اللهم بك أصبحنا', count: 1),
  ],
);

Widget _page() => MaterialApp(home: ReaderPage(group: group));

// reader pushed over a launcher, so there is a route to pop back to
Widget _launcher() => MaterialApp(
  home: Builder(
    builder: (context) => TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReaderPage(group: group)),
      ),
      child: const Text('open'),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(_launcher());
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
  });

  testWidgets('renders first dhikr, repeat label and position', (tester) async {
    await tester.pumpWidget(_page());
    expect(find.text('أصبحنا وأصبح الملكُ لله'), findsOneWidget);
    expect(find.text('٣ مرات'), findsOneWidget);
    expect(find.text('١ / ٢'), findsOneWidget);
  });

  testWidgets('title sits above the card, not in the app bar', (tester) async {
    await tester.pumpWidget(_page());
    final title = find.text('أذكار الصباح');
    expect(title, findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: title),
      findsNothing,
    );
    expect(
      tester.getBottomLeft(title).dy,
      lessThan(tester.getTopLeft(find.byType(Card).first).dy),
    );
  });

  testWidgets('tap increments counter and persists progress', (tester) async {
    await tester.pumpWidget(_page());
    await tester.tap(find.text('أصبحنا وأصبح الملكُ لله'));
    await tester.pump();
    expect(find.text('١'), findsOneWidget);
    final saved = Store.s('prog:g1')!;
    expect(saved, contains('"c":[1,0]'));
  });

  testWidgets('completing the repeat auto-advances; last one shows done', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    // first dhikr: repeat 3 times
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('أصبحنا وأصبح الملكُ لله'));
      await tester.pumpAndSettle();
    }
    // auto-advanced to second dhikr
    expect(find.text('اللهم بك أصبحنا'), findsOneWidget);
    // complete it: last item goes to the completion state
    await tester.tap(find.text('اللهم بك أصبحنا'));
    await tester.pumpAndSettle();
    expect(find.text('أتممت الذكر'), findsOneWidget);
    expect(Store.s('prog:g1'), contains('"c":[3,1]'));
  });

  testWidgets('reset from done page zeroes progress', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.prog:g1': '{"i":0,"c":[3,1]}',
    });
    await Store.init();
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();
    expect(find.text('أتممت الذكر'), findsOneWidget);
    await tester.tap(find.text('إعادة'));
    await tester.pumpAndSettle();
    expect(find.text('أصبحنا وأصبح الملكُ لله'), findsOneWidget);
    expect(Store.s('prog:g1'), contains('"c":[0,0]'));
  });

  testWidgets('copy on the done page copies the whole group', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.prog:g1': '{"i":2,"c":[3,1]}',
    });
    await Store.init();
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.pumpWidget(_page());
    expect(find.text('أتممت الذكر'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(copied, contains('أصبحنا وأصبح الملكُ لله'));
    expect(copied, contains('مسلم'));
    expect(copied, contains('اللهم بك أصبحنا'));
    expect(find.text('تم النسخ'), findsOneWidget);
  });

  testWidgets('a reminder restarts a finished group', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.prog:g1': '{"i":2,"c":[3,1]}',
    });
    await Store.init();
    await tester.pumpWidget(
      MaterialApp(home: ReaderPage(group: group, restartIfDone: true)),
    );
    expect(find.text('أتممت الذكر'), findsNothing);
    expect(find.text('أصبحنا وأصبح الملكُ لله'), findsOneWidget);
    expect(find.text('١ / ٢'), findsOneWidget);
    await tester.tap(find.text('أصبحنا وأصبح الملكُ لله'));
    await tester.pump();
    expect(Store.s('prog:g1'), contains('"c":[1,0]'));
  });

  testWidgets('a reminder resumes a group left part-way', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.prog:g1': '{"i":1,"c":[3,0]}',
    });
    await Store.init();
    await tester.pumpWidget(
      MaterialApp(home: ReaderPage(group: group, restartIfDone: true)),
    );
    expect(find.text('اللهم بك أصبحنا'), findsOneWidget);
    expect(find.text('٢ / ٢'), findsOneWidget);
  });

  testWidgets('tapping a finished card moves to the next one', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.prog:g1': '{"i":0,"c":[3,0]}',
    });
    await Store.init();
    await tester.pumpWidget(_page());
    await tester.tap(find.text('أصبحنا وأصبح الملكُ لله'));
    await tester.pumpAndSettle();
    expect(find.text('اللهم بك أصبحنا'), findsOneWidget);
    expect(Store.s('prog:g1'), contains('"c":[3,0]')); // count untouched
  });

  testWidgets('asks before leaving; stay keeps the reader open', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.text('أصبحنا وأصبح الملكُ لله'));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('الخروج من الأذكار؟'), findsOneWidget);
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('no prompt before the first tap', (tester) async {
    await _open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('الخروج من الأذكار؟'), findsNothing);
    expect(find.byType(ReaderPage), findsNothing);
  });
  testWidgets('tashkeel setting off strips diacritics', (tester) async {
    await Store.setB('tashkeel', false);
    await tester.pumpWidget(_page());
    expect(find.text('أصبحنا وأصبح الملك لله'), findsOneWidget);
  });

  testWidgets('every dhikr started but not finished reopens where it was', (
    tester,
  ) async {
    // the first needs 3 and has 1: the group is not finished
    SharedPreferences.setMockInitialValues({
      'flutter.prog:g1': '{"i":1,"c":[1,1]}',
    });
    await Store.init();
    await tester.pumpWidget(_page());
    expect(find.text('أتممت الذكر'), findsNothing);
    expect(find.text('اللهم بك أصبحنا'), findsOneWidget);
  });

  testWidgets('saved progress shorter than the group still opens', (
    tester,
  ) async {
    // saved before the group had its second dhikr
    SharedPreferences.setMockInitialValues({
      'flutter.prog:g1': '{"i":0,"c":[2]}',
    });
    await Store.init();
    await tester.pumpWidget(_page());
    expect(tester.takeException(), isNull);
    expect(find.text('٢'), findsOneWidget);
    await tester.tap(find.text('أصبحنا وأصبح الملكُ لله'));
    await tester.pumpAndSettle();
    expect(Store.s('prog:g1'), contains('"c":[3,0]'));
  });
}
