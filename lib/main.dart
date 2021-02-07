import 'package:azqar/Constants.dart';
import 'package:flutter/material.dart';
import 'Settings.dart';
import 'azqar.dart';
import 'package:stacked_themes/stacked_themes.dart';

Future main() async {
  await ThemeManager.initialise();
  runApp(ThemeBuilder(
    themes: getThemes(),
    builder: (context, regularTheme, darkTheme, thememode) => MaterialApp(
      theme: regularTheme,
      initialRoute: Azqar.id,
      routes: {
        Azqar.id: (context) => Azqar(),
        Settings.id: (context) => Settings()
      },
      title: 'Azqar',
      debugShowCheckedModeBanner: false,
    ),
  ));
}
