import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wazaqer/adhkar.dart';
import 'package:wazaqer/category.dart';
import 'package:wazaqer/store.dart';

const _json = '''
{
  "groups": [
    {"id": "g1", "title": "أذكار الصباح", "category": "morning",
     "items": [{"text": "أصبحنا وأصبح الملك لله", "count": 1}]},
    {"id": "g2", "title": "أذكار المساء", "category": "evening",
     "items": [{"text": "أمسينا وأمسى الملك لله", "count": 1}]}
  ],
  "categories": [
    {"id": "morning", "title": "أذكار الصباح", "en": "Morning", "icon": "wb_sunny", "all": false},
    {"id": "all", "title": "جميع الأذكار", "en": "All", "icon": "apps", "all": true}
  ]
}
''';

Widget _page(AdhkarData data, {AdhkarCategory? category}) =>
    MaterialApp(home: CategoryPage(data: data, category: category));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
  });

  testWidgets('empty favourites shows empty state', (tester) async {
    final data = AdhkarData.fromJson(_json);
    await tester.pumpWidget(_page(data));
    expect(find.text('المفضلة'), findsOneWidget);
    expect(find.text('لا توجد مفضلات بعد'), findsOneWidget);
  });

  testWidgets('heart toggle persists and favourites screen lists it',
      (tester) async {
    final data = AdhkarData.fromJson(_json);
    await tester.pumpWidget(_page(data, category: data.categories[0]));
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(Store.list('favourites'), ['g1']);

    await tester.pumpWidget(_page(data));
    expect(find.text('أذكار الصباح'), findsOneWidget);
  });

  testWidgets('search filters groups tashkeel-insensitively',
      (tester) async {
    final data = AdhkarData.fromJson(_json);
    await tester.pumpWidget(_page(data, category: data.categories[1]));
    await tester.enterText(find.byType(TextField), 'الملك');
    await tester.pump();
    // both groups match on dhikr text
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار المساء'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'أصبحنا');
    await tester.pump();
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار المساء'), findsNothing);
  });
}
