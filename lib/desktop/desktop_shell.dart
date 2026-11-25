import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../adhkar.dart';
import '../digits.dart';
import '../header.dart' show AppMark;
import '../hijri.dart';
import '../location.dart';
import '../prayer.dart';
import '../prayer_page.dart';
import '../store.dart';
import 'adhkar_panes.dart';
import 'prayer_desktop.dart';
import 'settings_desktop.dart';
import 'tasbeeh_desktop.dart';

/// Windows at least this wide get the desktop layout; narrower ones keep
/// the mobile shell, so a small desktop window still works. Below 1200 the
/// two lists leave the reader too narrow for its header and controls.
const desktopMinWidth = 1200.0;

/// Desktop layout: a top bar (name, Hijri date, search, next prayer), a
/// navigation rail on the start side and one section beside it. Lists and
/// the reader sit side by side instead of being pushed as pages.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _section = 0;
  AdhkarData? _data;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  late final Timer _clock;

  static const _sections = [
    (Icons.menu_book_outlined, Icons.menu_book, 'الأذكار'),
    (Icons.countertops_outlined, Icons.countertops, 'السبحة'),
    (Icons.schedule_outlined, Icons.schedule, 'الصلاة والقبلة'),
    (Icons.settings_outlined, Icons.settings, 'الإعدادات'),
  ];

  @override
  void initState() {
    super.initState();
    AdhkarData.load().then((d) {
      if (mounted) setState(() => _data = d);
    });
    // the next-prayer pill moves on as the day passes
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _go(int i) => setState(() => _section = i);

  void _focusSearch() {
    _go(0);
    _searchFocus.requestFocus();
    _search.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _search.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    // interface text in Tajawal (bundled); adhkar keep the reading font
    final theme = base.copyWith(
      // glyphs Tajawal lacks (ﷺ) come from the bundled Naskh, not from the
      // system or, on web, a font fetched from Google's servers
      textTheme: base.textTheme.apply(
        fontFamily: 'Tajawal',
        fontFamilyFallback: const ['Noto Naskh Arabic'],
      ),
    );
    final scheme = theme.colorScheme;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                _focusSearch,
            const SingleActivator(
              LogicalKeyboardKey.comma,
              control: true,
            ): () =>
                _go(3),
            for (final (i, key) in const [
              LogicalKeyboardKey.digit1,
              LogicalKeyboardKey.digit2,
              LogicalKeyboardKey.digit3,
              LogicalKeyboardKey.digit4,
            ].indexed)
              SingleActivator(key, control: true): () => _go(i),
          },
          child: Focus(
            autofocus: true,
            // Tabs rebuild on every settings change (digits, fonts,
            // location), as on mobile; their State survives.
            child: ValueListenableBuilder(
              valueListenable: Store.rev,
              builder: (context, _, _) => Column(
                children: [
                  _topBar(context, scheme),
                  Expanded(
                    child: Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _section,
                          onDestinationSelected: _go,
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: scheme.surface,
                          destinations: [
                            for (final s in _sections)
                              NavigationRailDestination(
                                icon: Icon(s.$1),
                                selectedIcon: Icon(s.$2),
                                label: Text(s.$3),
                              ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: IndexedStack(
                            index: _section,
                            children: [
                              _data == null
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : AdhkarPanes(
                                      data: _data!,
                                      query: _search.text,
                                      active: _section == 0,
                                      onClearSearch: () =>
                                          setState(_search.clear),
                                    ),
                              DesktopTasbeeh(active: _section == 1),
                              // not const: a const tab is identical on
                              // rebuild and would miss settings changes
                              DesktopPrayer(),
                              DesktopSettings(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, ColorScheme scheme) {
    final arabic = Store.b('arabicDigits', def: true);
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            const AppMark(),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'وَذَكِر',
                  style: TextStyle(
                    fontFamily: 'Noto Naskh Arabic',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                Text(
                  formatHijri(DateTime.now(), arabicDigits: arabic),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    onChanged: (_) => setState(() => _section = 0),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'ابحث في الأذكار',
                      suffixIcon: _search.text.isEmpty
                          ? const _Kbd('Ctrl K')
                          : IconButton(
                              tooltip: 'مسح البحث',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _search.clear()),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            _nextPrayer(context, scheme, arabic),
          ],
        ),
      ),
    );
  }

  Widget _nextPrayer(BuildContext context, ColorScheme scheme, bool arabic) {
    final loc = savedLocation();
    if (loc == null) {
      return TextButton.icon(
        onPressed: () => _go(2),
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('حدّد موقعك لمواقيت الصلاة'),
      );
    }
    final (times, next) = upcomingPrayers(loc, DateTime.now());
    final t = times.all[next];
    return ActionChip(
      onPressed: () => _go(2),
      avatar: Icon(Icons.schedule, size: 18, color: scheme.onPrimaryContainer),
      backgroundColor: scheme.primaryContainer,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      label: Text(
        'القادمة: ${prayerNames[next]} ${clock(t.hour, t.minute, arabic: arabic)}',
        style: TextStyle(color: scheme.onPrimaryContainer),
      ),
    );
  }
}

/// A keyboard-key hint, e.g. «Ctrl K».
class _Kbd extends StatelessWidget {
  const _Kbd(this.keys);

  final String keys;

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: KeyHint(keys),
    ),
  );
}

/// Small bordered label showing a key or chord, e.g. «Ctrl K». Arrow keys
/// draw as icons that never mirror: the ← key points left in any layout.
class KeyHint extends StatelessWidget {
  const KeyHint(this.keys, {super.key});

  final String keys;

  static const _arrows = {'←': Icons.west, '→': Icons.east};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arrow = _arrows[keys];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: arrow != null
          ? Icon(arrow, size: 14, color: scheme.onSurfaceVariant)
          : Text(
              keys,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
    );
  }
}
