import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'adhkar.dart';
import 'app_shell.dart';
import 'reader.dart';
import 'reminders.dart';
import 'store.dart';
import 'theme.dart';
import 'web/web_shell.dart';

final _navigator = GlobalKey<NavigatorState>();

/// Web pages have addresses; one router for the app's lifetime.
final GoRouter _webRouter = buildWebRouter();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const WaZaqerApp());
  // after runApp: scheduling must not hold up the first frame
  Reminders.init(_openGroup);
}

/// A tapped reminder opens its group's reader, restarting it if finished.
Future<void> _openGroup(String id) async {
  final data = await AdhkarData.load();
  final group = data.groups.where((g) => g.id == id).firstOrNull;
  if (group == null) return;
  await WidgetsBinding.instance.endOfFrame;
  _navigator.currentState?.push(
    MaterialPageRoute(
      builder: (_) => ReaderPage(group: group, restartIfDone: true),
    ),
  );
}

class WaZaqerApp extends StatelessWidget {
  const WaZaqerApp({super.key, this.webRouter});

  /// Web layout with its own addresses; given by tests. On the web build
  /// it is always on. Elsewhere the app picks mobile or desktop by width.
  final GoRouter? webRouter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Store.rev,
      builder: (context, _, _) {
        final seed = Color(
          Store.i('accent', def: WaZaqerTheme.seed.toARGB32()),
        );
        final theme = WaZaqerTheme.of(seed, Brightness.light);
        final darkTheme = WaZaqerTheme.of(seed, Brightness.dark);
        // stored 0/1/2 = ThemeMode.system/light/dark
        final themeMode = ThemeMode.values[Store.i('themeMode')];
        // .delegates (plural) includes GlobalWidgetsLocalizations, which
        // supplies the RTL text direction for Arabic; .delegate alone is LTR
        const delegates = GlobalMaterialLocalizations.delegates;
        const locales = [Locale('ar'), Locale('en')];
        // Arabic first, English as secondary locale.
        Locale arabicFirst(Locale? _, Iterable<Locale> supported) =>
            supported.first;
        final router = webRouter ?? (kIsWeb ? _webRouter : null);
        if (router != null) {
          return MaterialApp.router(
            routerConfig: router,
            title: 'وَذَكِر',
            theme: theme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            localizationsDelegates: delegates,
            supportedLocales: locales,
            localeResolutionCallback: arabicFirst,
          );
        }
        return MaterialApp(
          navigatorKey: _navigator,
          title: 'وَذَكِر',
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          localizationsDelegates: delegates,
          supportedLocales: locales,
          localeResolutionCallback: arabicFirst,
          home: const AppShell(),
        );
      },
    );
  }
}
