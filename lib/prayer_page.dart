import 'package:flutter/material.dart';

import 'digits.dart';
import 'header.dart';
import 'hijri.dart';
import 'location.dart';
import 'prayer.dart';
import 'store.dart';

/// Today's five prayers plus sunrise, the next prayer highlighted.
/// After isha it shows tomorrow, with fajr as next.
class PrayerTimesPage extends StatelessWidget {
  const PrayerTimesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arabic = Store.b('arabicDigits', def: true);
    final loc = savedLocation();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        WaZaqerHeader(
          title: 'مواقيت الصلاة',
          subtitle: [
            formatHijri(DateTime.now(), arabicDigits: arabic),
            if (loc != null) loc.name,
          ].join(' • '),
          actions: [
            if (loc != null)
              IconButton(
                icon: const Icon(Icons.edit_location_alt_outlined),
                color: scheme.onPrimary,
                tooltip: 'تغيير الموقع',
                onPressed: () => chooseLocation(context),
              ),
          ],
        ),
        Expanded(
          child: LocationGate(
            message: 'حدّد موقعك لعرض مواقيت الصلاة',
            builder: (context, loc) => _table(context, loc, arabic),
          ),
        ),
      ],
    );
  }

  Widget _table(BuildContext context, SavedLocation loc, bool arabic) {
    final scheme = Theme.of(context).colorScheme;
    final method = currentMethod(loc);
    final now = DateTime.now();
    var times = prayerTimes(now, loc.lat, loc.lng, method);
    // next prayer: sunrise (index 1) is not a prayer
    var next = [0, 2, 3, 4, 5].where((i) => times.all[i].isAfter(now)).firstOrNull;
    if (next == null) {
      times = prayerTimes(
          DateTime(now.year, now.month, now.day + 1), loc.lat, loc.lng, method);
      next = 0;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < 6; i++)
          Card(
            color: i == next ? scheme.primaryContainer : null,
            child: ListTile(
              leading: Icon(
                i == 1 ? Icons.wb_twilight : Icons.access_time,
                color: i == next ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Text(
                prayerNames[i],
                style: i == next
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
              subtitle: i == next ? const Text('الصلاة القادمة') : null,
              trailing: Text(
                clock(times.all[i].hour, times.all[i].minute, arabic: arabic),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'طريقة الحساب: ${method.name}',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
