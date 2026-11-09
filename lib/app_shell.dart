import 'package:flutter/material.dart';

import 'header.dart';
import 'hijri.dart';
import 'store.dart';

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
    final arabic = Store.b('arabicDigits', def: true);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _TabPage(
            title: 'وَذَكِر',
            subtitle: formatHijri(DateTime.now(), arabicDigits: arabic),
          ),
          for (final tab in _tabs.skip(1)) _TabPage(title: tab.$2),
        ],
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
  const _TabPage({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WaZaqerHeader(title: title, subtitle: subtitle),
        Expanded(
          child: Center(
            child: Text(
              'قريبًا',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}
