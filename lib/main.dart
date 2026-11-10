import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'adhkar.dart';
import 'app_shell.dart';
import 'reader.dart';
import 'reminders.dart';
import 'store.dart';
import 'theme.dart';

final _navigator = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const WaZaqerApp());
  // after runApp: scheduling must not hold up the first frame
  Reminders.init(_openGroup);
}

/// A tapped reminder opens its group's reader.
Future<void> _openGroup(String id) async {
  final data = await AdhkarData.load();
  final group = data.groups.where((g) => g.id == id).firstOrNull;
  if (group == null) return;
  await WidgetsBinding.instance.endOfFrame;
  _navigator.currentState?.push(
    MaterialPageRoute(builder: (_) => ReaderPage(group: group)),
  );
}

class WaZaqerApp extends StatelessWidget {
  const WaZaqerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Store.rev,
      builder: (context, _, _) {
        final seed =
            Color(Store.i('accent', def: WaZaqerTheme.seed.toARGB32()));
        return MaterialApp(
          navigatorKey: _navigator,
          title: 'وَذَكِر',
          theme: WaZaqerTheme.of(seed, Brightness.light),
          darkTheme: WaZaqerTheme.of(seed, Brightness.dark),
          // stored 0/1/2 = ThemeMode.system/light/dark
          themeMode: ThemeMode.values[Store.i('themeMode')],
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
      },
    );
  }
}
