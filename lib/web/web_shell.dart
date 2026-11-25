import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../adhkar.dart';
import '../desktop/prayer_desktop.dart';
import '../desktop/tasbeeh_desktop.dart';
import '../header.dart' show AppMark;
import '../settings.dart';
import '../store.dart';
import 'web_pages.dart';

/// Below this width the web layout swaps its top links for a bottom bar.
const webWideMinWidth = 760.0;

/// Every web page has its own address, so links, bookmarks, refresh and the
/// browser's back button work: `/`, `/c/<category>`, `/search?q=…`,
/// `/g/<group>?d=<dhikr number>`, `/tasbeeh`, `/prayer`.
GoRouter buildWebRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          WebShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const WebHome()),
        GoRoute(
          path: '/c/:cat',
          builder: (_, s) => WebGroupList(category: s.pathParameters['cat']),
        ),
        GoRoute(
          path: '/search',
          builder: (_, s) =>
              WebGroupList(query: s.uri.queryParameters['q'] ?? ''),
        ),
        GoRoute(
          path: '/g/:id',
          builder: (_, s) => WebReader(
            groupId: s.pathParameters['id']!,
            dhikr: int.tryParse(s.uri.queryParameters['d'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/tasbeeh',
          builder: (_, _) => _live(() => DesktopTasbeeh(active: true)),
        ),
        GoRoute(
          path: '/prayer',
          // a saved location (Store.changed) must swap the prompt for times
          builder: (_, _) => _live(
            () => DesktopPrayer(
              qiblaNote: 'اجعل أعلى الدائرة نحو الشمال، والسهم يشير إلى القبلة. للبوصلة الحية استخدم تطبيق أندرويد.',
            ),
          ),
        ),
      ],
    ),
  ],
);

/// Rebuilds [page] on every settings change (digits, fonts, location),
/// as the mobile and desktop shells do for their tabs. [page] must build a
/// new (non-const) widget: a const one is identical and gets skipped.
Widget _live(Widget Function() page) => ValueListenableBuilder(
  valueListenable: Store.rev,
  builder: (_, _, _) => page(),
);

/// The adhkar data for the web pages, loaded once by [WebShell].
class AdhkarScope extends InheritedWidget {
  const AdhkarScope({super.key, required this.data, required super.child});

  final AdhkarData? data;

  static AdhkarData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdhkarScope>()?.data;

  @override
  bool updateShouldNotify(AdhkarScope old) => old.data != data;
}

/// Web frame around every page: a top bar (name, section links on wide
/// screens, search, settings), a bottom bar on narrow screens, and the
/// settings drawer.
class WebShell extends StatefulWidget {
  const WebShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  AdhkarData? _data;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    AdhkarData.load().then((d) {
      if (mounted) setState(() => _data = d);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // a /search address typed or shared fills the box
    final q = GoRouterState.of(context).uri.queryParameters['q'];
    if (widget.location == '/search' && q != null && q != _search.text) {
      _search.text = q;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// 0 adhkar (home, lists, reader), 1 tasbeeh, 2 prayer.
  int get _section => switch (widget.location) {
    '/tasbeeh' => 1,
    '/prayer' => 2,
    _ => 0,
  };

  static const _paths = ['/', '/tasbeeh', '/prayer'];

  void _onSearch(String v) {
    if (v.trim().isEmpty) return context.go('/');
    final to = Uri(path: '/search', queryParameters: {'q': v}).toString();
    // already searching: replace the address, so Back doesn't step through
    // every letter typed
    if (widget.location == '/search') {
      Router.neglect(context, () => context.go(to));
    } else {
      context.go(to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final theme = base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Tajawal'),
    );
    return Theme(
      data: theme,
      child: AdhkarScope(
        data: _data,
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= webWideMinWidth;
            return Scaffold(
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
              endDrawer: const WebSettingsDrawer(),
              body: Column(
                children: [
                  _topBar(context, theme.colorScheme, wide),
                  Expanded(child: widget.child),
                ],
              ),
              bottomNavigationBar: wide
                  ? null
                  : Builder(
                      builder: (context) => NavigationBar(
                        selectedIndex: _section,
                        onDestinationSelected: (i) => i == 3
                            ? Scaffold.of(context).openEndDrawer()
                            : context.go(_paths[i]),
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.menu_book_outlined),
                            label: 'الأذكار',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.countertops_outlined),
                            label: 'السبحة',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.schedule_outlined),
                            label: 'الصلاة',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.settings_outlined),
                            label: 'الإعدادات',
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, ColorScheme scheme, bool wide) {
    Widget link(int i, String label) => TextButton(
      onPressed: () => context.go(_paths[i]),
      style: TextButton.styleFrom(
        backgroundColor: _section == i ? scheme.primaryContainer : null,
        foregroundColor: _section == i
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant,
        shape: const StadiumBorder(),
      ),
      child: Text(label),
    );
    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 12, vertical: 10),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'وَذَكِر: الصفحة الرئيسية',
              child: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppMark(),
                    if (wide) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'وَذَكِر',
                        style: TextStyle(
                          fontFamily: 'Noto Naskh Arabic',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (wide) ...[
              const SizedBox(width: 16),
              link(0, 'الأذكار'),
              link(1, 'السبحة'),
              link(2, 'الصلاة والقبلة'),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'ابحث في الأذكار',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (wide)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'الإعدادات',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Settings as a drawer: they change how pages look rather than being a
/// place to go. Same tiles as mobile, minus what a browser can't do.
class WebSettingsDrawer extends StatelessWidget {
  const WebSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      width: 380,
      child: ValueListenableBuilder(
        valueListenable: Store.rev,
        builder: (context, _, _) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'الإعدادات',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            for (final s in settingsSections(
              context,
              hideUnsupported: true,
            )) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  s.title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: scheme.primary),
                ),
              ),
              ...s.tiles,
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'الإعدادات والمفضلة والتقدم تُحفظ في هذا المتصفح.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
