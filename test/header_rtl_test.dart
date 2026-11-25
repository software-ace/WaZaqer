import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wazaqer/header.dart';

void main() {
  testWidgets('back arrow points right under RTL, left under LTR', (
    tester,
  ) async {
    Widget frame(TextDirection dir) => Directionality(
      textDirection: dir,
      child: MaterialApp(
        locale: dir == TextDirection.rtl
            ? const Locale('ar')
            : const Locale('en'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: Scaffold(body: WaZaqerHeader(title: 'x', showBack: true)),
      ),
    );

    // arrow_back glyph points left; Icon mirrors it (x scale -1) under RTL.
    // Check what's drawn, not which IconData was picked: picking
    // arrow_forward under RTL gets mirrored too and points left again.
    bool mirrored() {
      final t = find.descendant(
        of: find.byIcon(Icons.arrow_back),
        matching: find.byType(Transform),
      );
      return t.evaluate().isNotEmpty &&
          tester.widget<Transform>(t).transform.storage[0] == -1;
    }

    await tester.pumpWidget(frame(TextDirection.rtl));
    expect(mirrored(), isTrue, reason: 'points right under RTL');

    await tester.pumpWidget(frame(TextDirection.ltr));
    expect(mirrored(), isFalse, reason: 'points left under LTR');
  });
}
