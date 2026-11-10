import 'package:flutter/material.dart';

import 'adhkar.dart';
import 'header.dart';
import 'reader.dart';
import 'store.dart';

/// Search across every group in [data]. Title matches come first, marked
/// «في العنوان»; text-only matches follow, marked «في النص».
/// Matching is tashkeel-insensitive and ignores hamza/alef variants.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.data});

  final AdhkarData data;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  final List<String> _favs = Store.list('favourites');

  Future<void> _toggleFav(String id) async {
    setState(() {
      _favs.contains(id) ? _favs.remove(id) : _favs.add(id);
    });
    await Store.setList('favourites', _favs);
  }

  // Title-matching groups first, then the rest; each entry carries its match tag.
  List<(DhikrGroup, bool)> get _results {
    final q = searchKey(_query);
    if (q.isEmpty) return [];
    final titleHits = <(DhikrGroup, bool)>[];
    final textHits = <(DhikrGroup, bool)>[];
    for (final g in widget.data.groups) {
      if (searchKey(g.title).contains(q)) {
        titleHits.add((g, true));
      } else if (g.items.any((i) => searchKey(i.text).contains(q))) {
        textHits.add((g, false));
      }
    }
    return [...titleHits, ...textHits];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = _results;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MihrabPage(
        child: Column(
          children: [
            const WaZaqerHeader(title: 'البحث', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'ابحث في جميع الأذكار',
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
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: scheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          _query.isEmpty
                              ? const Text('اكتب للبحث في جميع الأذكار')
                              : const Text('لا نتائج'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final (g, byTitle) = results[i];
                        final fav = _favs.contains(g.id);
                        return Card(
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                fav ? Icons.favorite : Icons.favorite_border,
                                color:
                                    fav ? scheme.error : scheme.onSurfaceVariant,
                              ),
                              onPressed: () => _toggleFav(g.id),
                            ),
                            title: Text(
                              g.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              byTitle ? 'في العنوان' : 'في النص',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
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
      ),
    );
  }
}
