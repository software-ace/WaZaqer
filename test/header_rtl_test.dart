import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wazaqer/header.dart';

void main() {
  testWidgets('back arrow points right under RTL, left under LTR', (tester) async {
    Widget frame(TextDirection dir) => Directionality(
          textDirection: dir,
          child: MaterialApp(
            locale: dir == TextDirection.rtl ? const Locale('ar') : const Locale('en'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar'), Locale('en')],
            home: Scaffold(body: WaZaqerHeader(title: 'x', showBack: true)),
          ),
        );

    await tester.pumpWidget(frame(TextDirection.rtl));
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    await tester.pumpWidget(frame(TextDirection.ltr));
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
