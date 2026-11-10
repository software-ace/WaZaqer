import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'adhkar.dart';
import 'category.dart';
import 'digits.dart';
import 'header.dart';
import 'hijri.dart';
import 'reminders.dart';
import 'search.dart';
import 'store.dart';

/// Arabic plural: ذكر واحد، ذكران، ٣-١٠ أذكار، ١١+ ذكرًا
String adhkarCountLabel(int n, {bool arabicDigits = true}) {
  final num = digits(n, arabic: arabicDigits);
  if (n == 1) return 'ذكر واحد';
  if (n == 2) return 'ذكران';
  if (n >= 3 && n <= 10) return '$num أذكار';
  return '$num ذكرًا';
}

IconData categoryIcon(String name) => switch (name) {
  'wb_sunny' => Icons.wb_sunny,
  'home' => Icons.home,
  'restaurant' => Icons.restaurant,
  'sentiment_satisfied' => Icons.sentiment_satisfied,
  'directions_car' => Icons.directions_car,
  'mosque' => Icons.mosque,
  'spa' => Icons.spa,
  'flight' => Icons.flight,
  'handshake' => Icons.handshake,
  'water_drop' => Icons.water_drop,
  'healing' => Icons.healing,
  _ => Icons.apps,
};

/// The landing tab: header with search, salawat + reminder cards, category grid.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AdhkarData? _data;
  bool _salawatFav = false;
  bool _notifCard = true;
  int _favCount = 0;

  @override
  void initState() {
    super.initState();
    _salawatFav = Store.b('salawatFav');
    _notifCard = !Store.b('notifGranted') && !Store.b('notifDismissed');
    _favCount = Store.list('favourites').length;
    AdhkarData.load().then((d) => setState(() => _data = d));
  }

  Future<void> _enableNotifications() async {
    final granted = await Reminders.requestPermission();
    if (granted) await Reminders.enableDefaults();
    if (granted && mounted) setState(() => _notifCard = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final data = _data;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              _buildHeader(context, scheme, arabic, data),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SalawatCard(
                  fav: _salawatFav,
                  arabic: arabic,
                  onFav: () {
                    setState(() => _salawatFav = !_salawatFav);
                    Store.setB('salawatFav', _salawatFav);
                  },
                  onSettings: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalawatSettingsPage(),
                    ),
                  ),
                ),
              ),
              if (_notifCard)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _NotifCard(
                    onEnable: _enableNotifications,
                    onLater: () {
                      setState(() => _notifCard = false);
                      Store.setB('notifDismissed', true);
                    },
                  ),
                ),
              Expanded(
                child: data == null
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // wider window: more columns, capped at 5
                          final cross = (constraints.maxWidth / 260)
                              .floor()
                              .clamp(2, 5)
                              .toInt();
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.35,
                                ),
                            itemCount: data.categories.length + 1,
                            itemBuilder: (context, i) => i == 0
                                ? _FavTile(
                                    count: _favCount,
                                    arabic: arabic,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CategoryPage(
                                            data: data,
                                          ),
                                        ),
                                      );
                                      setState(() => _favCount =
                                          Store.list('favourites').length);
                                    },
                                  )
                                : _CategoryTile(
                                    category: data.categories[i - 1],
                                    data: data,
                                    arabic: arabic,
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme, bool arabic,
      AdhkarData? data) {
    return HeaderGradient(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _StarPainter(color: scheme.onPrimary),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'وَذَكِر',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatHijri(DateTime.now(), arabicDigits: arabic),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: data == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchPage(data: data),
                          ),
                        ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: scheme.onPrimary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ابحث في الأذكار',
                        style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Own artwork: an eight-pointed star (two rotated squares) in a circle.
class _StarPainter extends CustomPainter {
  _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.12);
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    for (final angle in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: r), paint);
      canvas.restore();
    }
    canvas.drawCircle(center, r * 1.35, paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}

class _SalawatCard extends StatelessWidget {
  const _SalawatCard({
    required this.fav,
    required this.arabic,
    required this.onFav,
    required this.onSettings,
  });

  final bool fav;
  final bool arabic;
  final VoidCallback onFav;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                color: scheme.primary,
              ),
              onPressed: onFav,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'صلِّ على محمد ﷺ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      salawatSummary(arabic: arabic),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid tile opening the favourites screen (CategoryPage with no category).
class _FavTile extends StatelessWidget {
  const _FavTile({
    required this.count,
    required this.arabic,
    required this.onTap,
  });

  final int count;
  final bool arabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite, size: 22, color: scheme.primary),
              ),
              const Spacer(),
              Text('المفضلة', style: Theme.of(context).textTheme.titleMedium),
              Text(
                count == 0 ? '—' : adhkarCountLabel(count, arabicDigits: arabic),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.onEnable, required this.onLater});

  final VoidCallback onEnable;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'فعِّل الإشعارات لتصلك تذكيرات أذكار الصباح والمساء',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onLater, child: const Text('لاحقًا')),
            FilledButton(onPressed: onEnable, child: const Text('تفعيل')),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.data,
    required this.arabic,
  });

  final AdhkarCategory category;
  final AdhkarData data;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = category.groupIds.length;
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryPage(data: data, category: category),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -8,
              bottom: -8,
              child: Icon(
                categoryIcon(category.icon),
                size: 88,
                color: scheme.primary.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon(category.icon),
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    adhkarCountLabel(count, arabicDigits: arabic),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
