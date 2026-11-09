import 'package:flutter/material.dart';

import 'header.dart';
import 'home.dart';

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
        child: IndexedStack(
          index: _index,
          children: [
            const HomePage(),
            for (final tab in _tabs.skip(1)) _TabPage(title: tab.$2),
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

class _TabPage extends StatelessWidget {
  const _TabPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WaZaqerHeader(title: title),
        Expanded(
          child: Center(
            child: Text('قريبًا', style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
