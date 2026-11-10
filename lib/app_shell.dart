import 'package:flutter/material.dart';

import 'header.dart';
import 'home.dart';
import 'prayer_page.dart';
import 'qibla.dart';
import 'settings.dart';
import 'store.dart';
import 'tasbeeh.dart';

/// Bottom-nav shell with the five tabs. Active item gets the M3 pill.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
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
      body: MihrabPage(
        // Tabs are rebuilt (not const) on every settings change so they pick
        // up digits, location and method; their State survives.
        child: ValueListenableBuilder(
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
