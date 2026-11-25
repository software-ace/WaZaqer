import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../adhkar.dart';
import '../digits.dart';
import '../hijri.dart';
import '../home.dart' show adhkarCountLabel, categoryIcon;
import '../location.dart';
import '../prayer.dart';
import '../prayer_page.dart';
import '../reader_controller.dart';
import '../search.dart';
import '../settings.dart' show fontFamilies, sourceUrl, sponsorUrl;
import '../store.dart';
import 'browser.dart';
import 'web_shell.dart';

/// Page body: centred, at most 1120 px wide, rebuilt on settings changes.
class _Page extends StatelessWidget {
  const _Page({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Store.rev,
    builder: (context, _, _) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: builder(context),
      ),
    ),
  );
}

/// «الرئيسية › …» links back up the hierarchy; the last item is the page.
class _Crumbs extends StatelessWidget {
  const _Crumbs(this.items);

  final List<(String, String?)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        for (final (i, (label, path)) in items.indexed) ...[
          if (path != null)
            TextButton(
              onPressed: () => context.go(path),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text(label),
            )
          else
            Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (i < items.length - 1)
            Text('‹', style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

Widget _loading() => const Center(child: CircularProgressIndicator());

/// Cards in as many equal columns as fit (each at least [minWidth]); every
/// card takes the height its content needs, so long titles just wrap.
class _Columns extends StatelessWidget {
  const _Columns({required this.minWidth, required this.children});

  final double minWidth;
  final List<Widget> children;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = ((box.maxWidth + _gap) / (minWidth + _gap)).floor().clamp(
        1,
        99,
      );
      final w = (box.maxWidth - _gap * (n - 1)) / n;
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

String _progress(DhikrGroup g, bool arabic) {
  final p = ReaderController.savedProgress(g);
  return [
    adhkarCountLabel(g.items.length, arabicDigits: arabic),
    if (p != null && p.$1 > 0)
      'تم ${digits(p.$1, arabic: arabic)} من ${digits(p.$2, arabic: arabic)}',
  ].join(' · ');
}

/// Home: start with the daily adhkar, then favourites, then categories.
class WebHome extends StatelessWidget {
  const WebHome({super.key});

  static const _quick = ['g1', 'g2', 'g28']; // morning, evening, sleep

  @override
  Widget build(BuildContext context) {
    final data = AdhkarScope.of(context);
    if (data == null) return _loading();
    return _Page(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        final arabic = Store.b('arabicDigits', def: true);
        final byId = {for (final g in data.groups) g.id: g};
        final loc = savedLocation();
        final next = loc == null ? null : upcomingPrayers(loc, DateTime.now());
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              children: [
                Text('ابدأ من هنا', style: text.headlineSmall),
                Text(
                  [
                    formatHijri(DateTime.now(), arabicDigits: arabic),
                    if (next != null)
                      'القادمة: ${prayerNames[next.$2]} ${clock(next.$1.all[next.$2].hour, next.$1.all[next.$2].minute, arabic: arabic)}',
                  ].join(' · '),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Columns(
              minWidth: 320,
              children: [
                for (final id in _quick)
                  if (byId[id] case final g?)
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: scheme.primaryContainer,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go('/g/${g.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.title,
                                style: TextStyle(
                                  fontFamily: 'Noto Naskh Arabic',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                _progress(g, arabic),
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: Store.favRev,
              builder: (context, _, _) {
                final favs = [
                  for (final id in Store.list('favourites'))
                    if (byId[id] != null) byId[id]!,
                ];
                if (favs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text('المفضلة', style: text.titleLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in favs)
                          ActionChip(
                            avatar: Icon(
                              Icons.favorite,
                              size: 16,
                              color: scheme.error,
                            ),
                            label: Text(g.title),
                            onPressed: () => context.go('/g/${g.id}'),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text('الفئات', style: text.titleLarge),
            const SizedBox(height: 10),
            _Columns(
              minWidth: 200,
              children: [
                for (final c in data.categories)
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go('/c/${c.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(categoryIcon(c.icon), color: scheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              c.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              adhkarCountLabel(
                                c.groupIds.length,
                                arabicDigits: arabic,
                              ),
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 36),
            const _Footer(),
          ],
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 24,
        runSpacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'أذكار من كتب الحديث المشهورة مع تخريج كل ذكر. بلا إعلانات ولا تتبّع. '
              'التذكيرات والأذان في تطبيق أندرويد.',
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.8),
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => openLink('$sourceUrl/releases'),
                child: const Text('تطبيق أندرويد والحاسوب'),
              ),
              TextButton(
                onPressed: () => openLink(sourceUrl),
                child: const Text('الشيفرة المصدرية'),
              ),
              TextButton(
                onPressed: () => openLink(sponsorUrl),
                child: const Text('ادعم المشروع'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A category's groups, the favourites (`fav`), or search results.
class WebGroupList extends StatelessWidget {
  const WebGroupList({super.key, this.category, this.query});

  final String? category;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final data = AdhkarScope.of(context);
    if (data == null) return _loading();
    return _Page(
      builder: (context) => ValueListenableBuilder(
        valueListenable: Store.favRev,
        builder: (context, _, _) {
          final scheme = Theme.of(context).colorScheme;
          final arabic = Store.b('arabicDigits', def: true);
          final byId = {for (final g in data.groups) g.id: g};
          final favs = Store.list('favourites');
          final cat = data.categories
              .where((c) => c.id == category)
              .firstOrNull;
          final String title;
          final List<DhikrGroup> groups;
          if (query != null) {
            title = 'نتائج البحث عن «$query»';
            groups = [for (final (g, _) in searchGroups(data, query!)) g];
          } else if (cat != null) {
            title = cat.title;
            groups = [for (final id in cat.groupIds) byId[id]!];
          } else {
            title = 'المفضلة';
            groups = [
              for (final id in favs)
                if (byId[id] != null) byId[id]!,
            ];
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _Crumbs([
                ('الرئيسية', '/'),
                (query != null ? 'البحث' : title, null),
              ]),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (groups.isNotEmpty)
                Text(
                  adhkarCountLabel(groups.length, arabicDigits: arabic),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    query != null ? 'لا نتائج' : 'لا توجد أذكار هنا بعد.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 16),
              _Columns(
                minWidth: 360,
                children: [
                  for (final g in groups)
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        title: Text(g.title),
                        subtitle: Text(_progress(g, arabic)),
                        onTap: () => context.go('/g/${g.id}'),
                        trailing: IconButton(
                          tooltip: favs.contains(g.id)
                              ? 'إزالة من المفضلة'
                              : 'إضافة إلى المفضلة',
                          isSelected: favs.contains(g.id),
                          icon: const Icon(Icons.favorite_border),
                          selectedIcon: Icon(
                            Icons.favorite,
                            color: scheme.error,
                          ),
                          onPressed: () => Store.toggleFavourite(
                            Store.list('favourites'),
                            g.id,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One group as a single scrolling page: every dhikr is a card with its own
/// count button, so the text can be selected and searched with the browser
/// without counting. Finishing one scrolls to the next unfinished dhikr.
/// `?d=3` opens the page at dhikr 3.
class WebReader extends StatefulWidget {
  const WebReader({super.key, required this.groupId, this.dhikr});

  final String groupId;
  final int? dhikr;

  @override
  State<WebReader> createState() => _WebReaderState();
}

class _WebReaderState extends State<WebReader> {
  ReaderController? _c;
  final _scroll = ScrollController();
  List<GlobalKey> _keys = [];
  final _doneKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = AdhkarScope.of(context);
    final g = data?.groups.where((g) => g.id == widget.groupId).firstOrNull;
    if (g == null || _c?.group.id == g.id) return;
    _c?.dispose();
    final c = ReaderController(g);
    _keys = [for (final _ in g.items) GlobalKey()];
    keepAwake(true);
    final d = widget.dhikr;
    if (d != null && d >= 1 && d <= c.length) {
      c.goTo(d - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(d - 1));
    }
    // listen only now: the jump above happens mid-build, which this
    // build already shows
    _c = c..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_c != null) keepAwake(false);
    _c?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTo(int i) {
    final ctx = (i < _keys.length ? _keys[i] : _doneKey).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  void _count(int i) {
    final c = _c!;
    if (c.index != i) c.goTo(i);
    if (!c.tap()) return;
    // finished with auto-advance: the next unfinished dhikr becomes current
    final next = [for (var j = i + 1; j < c.length; j++) j]
        .where((j) => !c.itemDone(j))
        .firstOrNull;
    final allDone = [for (var j = 0; j < c.length; j++) j].every(c.itemDone);
    if (next != null) {
      c.goTo(next);
    } else if (allDone) {
      c.goTo(c.length);
    } else {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(c.index));
  }

  void _copyLink(int? i) {
    final path = '/g/${widget.groupId}${i == null ? '' : '?d=${i + 1}'}';
    final base = Uri.base;
    final url = '${base.origin}${base.path}#$path';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (AdhkarScope.of(context) == null) return _loading();
    if (c == null) {
      return const Center(child: Text('لم يُعثر على هذه المجموعة'));
    }
    return ValueListenableBuilder(
      valueListenable: Store.rev,
      builder: (context, _, _) => _body(context, c),
    );
  }

  Widget _body(BuildContext context, ReaderController c) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final data = AdhkarScope.of(context)!;
    final cat = data.categories
        .where((x) => x.id == c.group.category)
        .firstOrNull;
    final favs = Store.list('favourites');
    final isFav = favs.contains(c.group.id);
    final done = c.doneCount;
    return Column(
      children: [
        Material(
          color: scheme.surfaceContainerLowest,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Crumbs([
                      ('الرئيسية', '/'),
                      if (cat != null) (cat.title, '/c/${cat.id}'),
                      (c.group.title, null),
                    ]),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.group.title,
                            style: const TextStyle(
                              fontFamily: 'Noto Naskh Arabic',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: isFav
                              ? 'إزالة من المفضلة'
                              : 'إضافة إلى المفضلة',
                          isSelected: isFav,
                          icon: const Icon(Icons.favorite_border),
                          selectedIcon: Icon(
                            Icons.favorite,
                            color: scheme.error,
                          ),
                          onPressed: () {
                            Store.toggleFavourite(favs, c.group.id);
                            setState(() {});
                          },
                        ),
                        IconButton(
                          tooltip: 'نسخ رابط المجموعة',
                          icon: const Icon(Icons.link),
                          onPressed: () => _copyLink(null),
                        ),
                        IconButton(
                          tooltip: 'إعادة',
                          icon: const Icon(Icons.restart_alt),
                          onPressed: () {
                            c.reset();
                            _scroll.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // stays put while the adhkar scroll under it
                    Row(
                      children: [
                        Text(
                          c.isDone || done == c.length
                              ? 'اكتملت المجموعة'
                              : 'تم ${digits(done, arabic: arabic)} من ${digits(c.length, arabic: arabic)}',
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: c.length == 0 ? 0 : done / c.length,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        if (!c.isDone) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _scrollTo(c.index),
                            child: const Text('انتقل إلى الحالي'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SelectionArea(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    children: [
                      for (var i = 0; i < c.length; i++)
                        _dhikr(context, c, i, arabic),
                      if (c.isDone) _done(context, c, cat),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dhikr(BuildContext context, ReaderController c, int i, bool arabic) {
    final scheme = Theme.of(context).colorScheme;
    final item = c.group.items[i];
    final finished = c.itemDone(i);
    final current = !c.isDone && i == c.index;
    final font = Store.s('fontFamily');
    final text = Store.b('tashkeel', def: true)
        ? item.text
        : stripTashkeel(item.text);
    final muted = TextStyle(
      color: scheme.onSurfaceVariant,
      fontSize: 13,
      height: 1.8,
    );
    return Opacity(
      key: _keys[i],
      opacity: finished && !current ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            width: current ? 2 : 1,
            color: current ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: current
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(digits(i + 1, arabic: arabic)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'نسخ رابط هذا الذكر',
                  icon: const Icon(Icons.link, size: 20),
                  onPressed: () => _copyLink(i),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: (font != null && font.isNotEmpty)
                    ? font
                    : fontFamilies.first,
                fontSize: 28 * Store.i('fontScale', def: 100) / 100,
                height: 2,
              ),
            ),
            if (item.note.isNotEmpty || item.source.isNotEmpty) ...[
              const Divider(height: 28),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  if (item.note.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text('الفضل: ${item.note}', style: muted),
                    ),
                  if (item.source.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text('التخريج: ${item.source}', style: muted),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    repeatLabel(item.count, arabicDigits: arabic),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                if (finished)
                  FilledButton.tonalIcon(
                    onPressed: null,
                    icon: const Icon(Icons.check),
                    label: const Text('تم'),
                  )
                else
                  FilledButton(
                    onPressed: () => _count(i),
                    child: Text(
                      'اضغط للعدّ · ${digits(c.counts[i], arabic: arabic)} من ${digits(item.count, arabic: arabic)}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _done(BuildContext context, ReaderController c, AdhkarCategory? cat) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: _doneKey,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 64, color: scheme.primary),
          const SizedBox(height: 12),
          Text('أتممت الذكر', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  c.reset();
                  _scroll.jumpTo(0);
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('إعادة'),
              ),
              if (cat != null)
                OutlinedButton(
                  onPressed: () => context.go('/c/${cat.id}'),
                  child: Text('العودة إلى ${cat.title}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
