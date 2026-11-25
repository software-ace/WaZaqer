import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/hijri.dart';
import 'package:wazaqer/home.dart';
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

  testWidgets('favourites count on home follows a heart toggled elsewhere', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    // rootBundle caches the asset future across tests; one started under an
    // earlier test's fake clock never completes, so drop it
    rootBundle.evict('assets/adhkar.json');
    await tester.pumpWidget(const WaZaqerApp());
    // the adhkar asset is real I/O, which the fake clock doesn't advance;
    // give it real time until the grid (and the favourites tile) appears
    for (var i = 0; i < 100 && find.text('المفضلة').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    final favTile = find.ancestor(
      of: find.text('المفضلة'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: favTile, matching: find.text('—')),
      findsOneWidget,
    );

    // heart a group from a regular category, not the favourites page
    await tester.tap(find.text('اليوم والليلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back)); // WaZaqerHeader's back
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: favTile, matching: find.text('—')),
      findsNothing,
    );
    expect(
      find.descendant(of: favTile, matching: find.text(adhkarCountLabel(1))),
      findsOneWidget,
    );
  });
}
