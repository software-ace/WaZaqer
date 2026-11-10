import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wazaqer/adhkar.dart';
import 'package:wazaqer/category.dart';
import 'package:wazaqer/store.dart';
import 'package:wazaqer/theme.dart';

void main() {
  testWidgets('category page under Arabic RTL renders like the app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    const json = '''
    {"categories":[{"id":"all","title":"جميع الأذكار","en":"All","icon":"menu_book","all":true}],
     "groups":[{"id":"g1","title":"أذكار الصباح","category":"all","items":[{"text":"_text_","count":1}]},
               {"id":"g2","title":"دعاء لبس الثوب","category":"all","items":[{"text":"_text_","count":1}]}]}
    ''';
    final data = AdhkarData.fromJson(json);
    await tester.binding.setSurfaceSize(const Size(851, 603));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        localeResolutionCallback: (locale, supported) => supported.first,
        theme: WaZaqerTheme.dark,
        home: CategoryPage(
          data: data,
          category: data.categories.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(CategoryPage), matchesGoldenFile('gold/category_rtl.png'));
  });
}
