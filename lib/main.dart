import 'package:flutter/material.dart';
import 'Constants.dart';
import 'package:stacked_themes/stacked_themes.dart';

import 'Settings.dart';
import 'azqar.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialise();
  runApp(
    ThemeBuilder(
      themes: getThemes(),
      builder: (context, regularTheme, darkTheme, thememode) => MaterialApp(
        theme: regularTheme,
        initialRoute: Azqar.id,
        routes: {
          Azqar.id: (context) => Azqar(),
          Settings.id: (context) => Settings()
        },
        title: 'WaZaqer',
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
