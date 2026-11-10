import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/adhkar.dart';
import 'package:wazaqer/search.dart';
import 'package:wazaqer/store.dart';

const _json = '''
{
  "groups": [
    {"id": "g1", "title": "أذكار الصباح", "category": "morning",
     "items": [{"text": "أصبحنا وأصبح الملك لله", "count": 1}]},
    {"id": "g2", "title": "أذكار المساء", "category": "evening",
     "items": [{"text": "أسأل الله العظيم", "count": 1}]}
  ],
  "categories": [
    {"id": "morning", "title": "أذكار الصباح", "en": "Morning", "icon": "wb_sunny", "all": false},
    {"id": "all", "title": "جميع الأذكار", "en": "All", "icon": "apps", "all": true}
  ]
}
''';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
  });

  test('searchKey ignores tashkeel, hamza variants, taa marbuta and alif maqsura',
      () {
    // tashkeel
    expect(searchKey('أَصْبَحْنَا'), searchKey('اصبحنا'));
    // hamza/alef variants unify
    expect(searchKey('أصبحنا'), searchKey('إصبحنا'));
    expect(searchKey('الآخِرة'), searchKey('الاخره'));
    // taa marbuta and alif maqsura
    expect(searchKey('قاضى'), searchKey('قاضي'));
  });

  testWidgets('title match comes first and is tagged في العنوان; text match في النص',
      (tester) async {
    final data = AdhkarData.fromJson(_json);
    await tester.pumpWidget(
      MaterialApp(home: SearchPage(data: data)),
    );
    await tester.enterText(find.byType(TextField), 'صباح');
    await tester.pump();

    // Only the morning group matches, by title
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('في العنوان'), findsOneWidget);
    expect(find.text('في النص'), findsNothing);
  });

  testWidgets('text-only match is tagged في النص and tashkeel-insensitive',
      (tester) async {
    final data = AdhkarData.fromJson(_json);
    await tester.pumpWidget(
      MaterialApp(home: SearchPage(data: data)),
    );
    await tester.enterText(find.byType(TextField), 'الله العظيم');
    await tester.pump();

    expect(find.text('أذكار المساء'), findsOneWidget);
    expect(find.text('في النص'), findsOneWidget);
    expect(find.text('في العنوان'), findsNothing);
  });

  testWidgets('no query shows hint, empty result shows لا نتائج',
      (tester) async {
    final data = AdhkarData.fromJson(_json);
    await tester.pumpWidget(
      MaterialApp(home: SearchPage(data: data)),
    );
    expect(find.text('اكتب للبحث في جميع الأذكار'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'غير موجود أبدا');
    await tester.pump();
    expect(find.text('لا نتائج'), findsOneWidget);
  });
}
