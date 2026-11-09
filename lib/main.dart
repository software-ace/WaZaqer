import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_shell.dart';
import 'store.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const WaZaqerApp());
}

class WaZaqerApp extends StatelessWidget {
  const WaZaqerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'وَذَكِر',
      theme: WaZaqerTheme.light,
      darkTheme: WaZaqerTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      // Arabic first, English as secondary locale.
      localeResolutionCallback: (locale, supported) => supported.first,
      home: const AppShell(),
    );
  }
}
