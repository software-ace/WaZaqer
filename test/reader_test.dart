import 'package:flutter/material.dart';
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

  testWidgets('tap increments counter and persists progress', (tester) async {
    await tester.pumpWidget(_page());
    await tester.tap(find.text('أصبحنا وأصبح الملكُ لله'));
    await tester.pump();
    expect(find.text('١'), findsOneWidget);
    final saved = Store.s('prog:g1')!;
    expect(saved, contains('"c":[1,0]'));
  });

  testWidgets('completing the repeat auto-advances; last one shows done',
      (tester) async {
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
    SharedPreferences.setMockInitialValues(
        {'flutter.prog:g1': '{"i":0,"c":[3,1]}'});
    await Store.init();
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();
    expect(find.text('أتممت الذكر'), findsOneWidget);
    await tester.tap(find.text('إعادة'));
    await tester.pumpAndSettle();
    expect(find.text('أصبحنا وأصبح الملكُ لله'), findsOneWidget);
    expect(Store.s('prog:g1'), contains('"c":[0,0]'));
  });

  testWidgets('tashkeel setting off strips diacritics', (tester) async {
    await Store.setB('tashkeel', false);
    await tester.pumpWidget(_page());
    expect(find.text('أصبحنا وأصبح الملك لله'), findsOneWidget);
  });
}
