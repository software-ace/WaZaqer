import 'package:flutter/material.dart';
import 'Settings.dart';
import 'azqar.dart';
import 'package:stacked_themes/stacked_themes.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

Future main() async {
  final appDocDirectory =
      await path_provider.getApplicationDocumentsDirectory();

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
      title: 'WaZaqer',
      debugShowCheckedModeBanner: false,
    ),
  ));
}
