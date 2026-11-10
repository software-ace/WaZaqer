import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'prayer.dart';
import 'store.dart';

/// The user's stored location: from the GPS or a picked city. It stays on
/// the device and is only asked for from the prayer-times and qibla tabs.
class SavedLocation {
  const SavedLocation(this.lat, this.lng, this.name);

  final double lat;
  final double lng;
  final String name;
}

SavedLocation? savedLocation() {
  final lat = Store.d('lat'), lng = Store.d('lng');
  if (lat == null || lng == null) return null;
  return SavedLocation(lat, lng, Store.s('city') ?? '');
}

Future<void> saveLocation(double lat, double lng, String name) async {
  await Store.setD('lat', lat);
  await Store.setD('lng', lng);
  await Store.setS('city', name);
  Store.changed();
}

Future<void> clearLocation() async {
  for (final k in ['lat', 'lng', 'city']) {
    await Store.remove(k);
  }
  Store.changed();
}

/// Method in effect: the setting, or with automatic on, the nearest city's.
CalcMethod currentMethod(SavedLocation loc) => Store.b('autoMethod', def: true)
    ? methodById(nearestCity(loc.lat, loc.lng).method)
    : methodById(Store.s('method'));

// Android LocationManager via MainActivity: location plugins pull in Google
// Play Services, which F-Droid builds can't ship.
const _channel = MethodChannel('wazaqer/location');

Future<void> useGps(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (await Permission.locationWhenInUse.request().isGranted) {
      final r = await _channel
          .invokeMapMethod<String, double>('current')
          .timeout(const Duration(seconds: 20));
      if (r != null) {
        final lat = r['lat']!, lng = r['lng']!;
        await saveLocation(lat, lng, 'موقعي (قرب ${nearestCity(lat, lng).name})');
        return;
      }
    }
  } on Exception {
    // no plugin on desktop, location off, or timed out: fall through
  }
  messenger.showSnackBar(
    const SnackBar(content: Text('تعذّر تحديد الموقع، اختر مدينة من القائمة')),
  );
}

/// Bottom sheet: current GPS position first, then the city list.
Future<void> chooseLocation(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => ListView(
          controller: controller,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('استخدم موقعي الحالي'),
              onTap: () {
                Navigator.pop(sheet);
                useGps(context);
              },
            ),
            const Divider(),
            for (final c in cities)
              ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(c.name),
                onTap: () {
                  Navigator.pop(sheet);
                  saveLocation(c.lat, c.lng, c.name);
                },
              ),
          ],
        ),
      ),
    );

/// Shows [builder] once a location is stored, else an empty state that asks
/// for one.
class LocationGate extends StatelessWidget {
  const LocationGate({super.key, required this.message, required this.builder});

  final String message;
  final Widget Function(BuildContext, SavedLocation) builder;

  @override
  Widget build(BuildContext context) {
    final loc = savedLocation();
    if (loc != null) return builder(context, loc);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => useGps(context),
              icon: const Icon(Icons.my_location),
              label: const Text('استخدم موقعي الحالي'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => chooseLocation(context),
              icon: const Icon(Icons.location_city),
              label: const Text('اختر مدينة'),
            ),
          ],
        ),
      ),
    );
  }
}
