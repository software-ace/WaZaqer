import 'package:flutter/material.dart';

import 'adhkar.dart';
import 'header.dart';
import 'home.dart' show categoryIcon;
import 'reader.dart';
import 'store.dart';

/// Category screen, and — with [category] null — the favourites screen.
/// Scoped search matches group titles and dhikr text, tashkeel-insensitive.
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.data, this.category});

  final AdhkarData data;
  final AdhkarCategory? category; // null = favourites

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String _query = '';
  final List<String> _favs = Store.list('favourites');

  bool _isFav(String id) => _favs.contains(id);

  Future<void> _toggleFav(String id) async {
    setState(() {
      _isFav(id) ? _favs.remove(id) : _favs.add(id);
    });
    await Store.setList('favourites', _favs);
  }

  late final _iconOf = {
    for (final c in widget.data.categories) c.id: categoryIcon(c.icon),
  };

  List<DhikrGroup> get _groups {
    final byId = {for (final g in widget.data.groups) g.id: g};
    final base = widget.category == null
        ? [
            for (final id in _favs)
              if (byId[id] != null) byId[id]!,
          ]
        : [for (final id in widget.category!.groupIds) byId[id]!];
    final q = searchKey(_query);
    if (q.isEmpty) return base;
    return [
      for (final g in base)
        if (searchKey(g.title).contains(q) ||
            g.items.any((i) => searchKey(i.text).contains(q)))
          g,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = widget.category?.title ?? 'المفضلة';
    final groups = _groups;
    return Scaffold(
      body: Column(
        children: [
          WaZaqerHeader(title: title, showBack: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ابحث',
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: groups.isEmpty && _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        const Text('لا توجد مفضلات بعد'),
                      ],
                    ),
                  )
                : groups.isEmpty
                ? const Center(child: Text('لا نتائج'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groups.length,
                    itemBuilder: (context, i) {
                      final g = groups[i];
                      return Card(
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              _isFav(g.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFav(g.id)
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                            onPressed: () => _toggleFav(g.id),
                          ),
                          title: Text(
                            g.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconOf[g.category] ?? Icons.menu_book,
                              size: 20,
                              color: scheme.primary,
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderPage(group: g),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
