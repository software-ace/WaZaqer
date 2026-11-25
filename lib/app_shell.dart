import 'dart:io' show Platform;

import 'package:material_ui/material_ui.dart';

import 'desktop/desktop_shell.dart';

import 'home.dart';
import 'prayer_page.dart';
import 'qibla.dart';
import 'settings.dart';
import 'store.dart';
import 'tasbeeh.dart';

/// Picks the layout: a wide desktop window gets the desktop shell, a narrow
/// one the mobile shell. Phones and tablets always get mobile, even wide in
/// landscape: they have the compass and haptics the desktop layout leaves
/// out. The web build has its own layout (lib/web/) and never comes here.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) =>
        !(Platform.isAndroid || Platform.isIOS) &&
            box.maxWidth >= desktopMinWidth
        ? const DesktopShell()
        : const _MobileShell(),
  );
}

/// Bottom-nav shell with the five tabs. Active item gets the M3 pill.
class _MobileShell extends StatefulWidget {
  const _MobileShell();

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  int _index = 0;

  static const _tabs = [
    (Icons.menu_book, 'الأذكار'),
    (Icons.countertops, 'السبحة'),
    (Icons.explore, 'القبلة'),
    (Icons.schedule, 'الصلاة'),
    (Icons.settings, 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tabs are rebuilt (not const) on every settings change so they pick
      // up digits, location and method; their State survives.
      body: ValueListenableBuilder(
        valueListenable: Store.rev,
        builder: (context, _, _) => IndexedStack(
          index: _index,
          children: [
            HomePage(),
            TasbeehPage(),
            // built only while shown, so the compass sensor stops
            _index == 2 ? QiblaPage() : const SizedBox.shrink(),
            PrayerTimesPage(),
            SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.$1),
              selectedIcon: Icon(tab.$1),
              label: tab.$2,
            ),
        ],
      ),
    );
  }
}
