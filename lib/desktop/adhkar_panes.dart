import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../adhkar.dart';
import '../digits.dart';
import '../home.dart' show adhkarCountLabel, categoryIcon;
import '../reader_controller.dart';
import '../search.dart';
import '../store.dart';
import 'reader_pane.dart';

const _favourites = 'fav';

/// The adhkar section: categories | groups | reader, side by side.
/// The last opened category and group come back on the next launch.
class AdhkarPanes extends StatefulWidget {
  const AdhkarPanes({
    super.key,
    required this.data,
    required this.query,
    required this.active,
    required this.onClearSearch,
  });

  final AdhkarData data;

  /// Top-bar search text; non-empty replaces the group list with results.
  final String query;

  /// Whether this section is the one on screen (it lives in an IndexedStack).
  final bool active;

  /// Empties the top-bar search, so a picked category shows its groups.
  final VoidCallback onClearSearch;

  @override
  State<AdhkarPanes> createState() => _AdhkarPanesState();
}

class _AdhkarPanesState extends State<AdhkarPanes> {
  // the saved category, unless a data update has removed it
  late String _cat = switch (Store.s('deskCat')) {
    final id?
        when id == _favourites ||
            widget.data.categories.any((c) => c.id == id) =>
      id,
    _ => widget.data.categories.first.id,
  };
  ReaderController? _reader;
  bool _focusMode = false;
  final _readerFocus = FocusNode(debugLabel: 'reader');

  @override
  void initState() {
    super.initState();
    final gid = Store.s('deskGroup');
    final g = widget.data.groups.where((g) => g.id == gid).firstOrNull;
    if (g != null) _open(g, focus: false);
  }

  @override
  void didUpdateWidget(AdhkarPanes old) {
    super.didUpdateWidget(old);
    // back on this section: keys go to the reader again
    if (widget.active && !old.active && _reader != null) {
      _readerFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _reader?.dispose();
    _readerFocus.dispose();
    super.dispose();
  }

  void _open(DhikrGroup g, {bool focus = true}) {
    if (_reader?.group.id != g.id) {
      _reader?.dispose();
      _reader = ReaderController(g)..addListener(_changed);
      Store.setS('deskGroup', g.id);
    }
    setState(() {});
    // a node not yet in the tree takes focus once its pane is built
    if (focus) _readerFocus.requestFocus();
  }

  // reader progress shows in the group list too
  void _changed() => setState(() {});

  void _pickCategory(String id) {
    if (widget.query.trim().isNotEmpty) widget.onClearSearch();
    setState(() => _cat = id);
    Store.setS('deskCat', id);
  }

  @override
  Widget build(BuildContext context) {
    final reader = _reader;
    return Row(
      children: [
        if (!_focusMode) ...[
          SizedBox(width: 240, child: _categories(context)),
          const VerticalDivider(width: 1),
          SizedBox(width: 320, child: _groups(context)),
          const VerticalDivider(width: 1),
        ],
        Expanded(
          child: reader == null
              ? _pickHint(context)
              : ReaderPane(
                  key: ValueKey(reader.group.id),
                  controller: reader,
                  focusNode: _readerFocus,
                  focusMode: _focusMode,
                  onToggleFocusMode: () =>
                      setState(() => _focusMode = !_focusMode),
                ),
        ),
      ],
    );
  }

  Widget _pickHint(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'اختر مجموعة من القائمة لتبدأ القراءة',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _paneTitle(BuildContext context, String title, [String? sub]) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (sub != null)
            Text(
              sub,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _categories(BuildContext context) {
    final arabic = Store.b('arabicDigits', def: true);
    final searching = widget.query.trim().isNotEmpty;
    Widget tile(String id, IconData icon, String title, String count) =>
        ListTile(
          dense: true,
          selected: !searching && _cat == id,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(icon, size: 20),
          title: Text(title, style: const TextStyle(fontSize: 15)),
          trailing: Text(count),
          onTap: () => _pickCategory(id),
        );
    return ValueListenableBuilder(
      valueListenable: Store.favRev,
      builder: (context, _, _) {
        final favs = Store.list('favourites').length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            _paneTitle(context, 'الفئات'),
            tile(
              _favourites,
              Icons.favorite_outline,
              'المفضلة',
              favs == 0 ? '—' : digits(favs, arabic: arabic),
            ),
            for (final c in widget.data.categories)
              tile(
                c.id,
                categoryIcon(c.icon),
                c.title,
                digits(c.groupIds.length, arabic: arabic),
              ),
          ],
        );
      },
    );
  }

  Widget _groups(BuildContext context) {
    final arabic = Store.b('arabicDigits', def: true);
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: Store.favRev,
      builder: (context, _, _) {
        final favs = Store.list('favourites');
        final byId = {for (final g in widget.data.groups) g.id: g};
        final String title;
        final List<(DhikrGroup, bool)> list;
        if (widget.query.trim().isNotEmpty) {
          title = 'نتائج البحث';
          list = searchGroups(widget.data, widget.query);
        } else if (_cat == _favourites) {
          title = 'المفضلة';
          list = [
            for (final id in favs)
              if (byId[id] != null) (byId[id]!, true),
          ];
        } else {
          final c = widget.data.categories.firstWhere((c) => c.id == _cat);
          title = c.title;
          list = [for (final id in c.groupIds) (byId[id]!, true)];
        }
        final empty = widget.query.trim().isNotEmpty
            ? 'لا نتائج'
            : _cat == _favourites
            ? 'لا توجد أذكار في المفضلة بعد. اضغط القلب بجانب أي مجموعة.'
            : '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _paneTitle(
              context,
              title,
              list.isEmpty
                  ? null
                  : adhkarCountLabel(list.length, arabicDigits: arabic),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  empty,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final (g, titleHit) = list[i];
                  final isFav = favs.contains(g.id);
                  final p = _reader?.group.id == g.id
                      ? (_reader!.doneCount, _reader!.length)
                      : ReaderController.savedProgress(g);
                  final meta = [
                    adhkarCountLabel(g.items.length, arabicDigits: arabic),
                    if (p != null && p.$1 > 0)
                      'تم ${digits(p.$1, arabic: arabic)} من ${digits(p.$2, arabic: arabic)}',
                    if (!titleHit) 'في النص',
                  ].join(' · ');
                  return ListTile(
                    selected: _reader?.group.id == g.id,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(g.title),
                    subtitle: Text(meta),
                    onTap: () => _open(g),
                    trailing: IconButton(
                      tooltip: isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                      isSelected: isFav,
                      icon: const Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite, color: scheme.error),
                      onPressed: () =>
                          Store.toggleFavourite(Store.list('favourites'), g.id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Copies [text] to the clipboard and confirms with a snackbar.
void copyWithNotice(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('تم النسخ')));
}
