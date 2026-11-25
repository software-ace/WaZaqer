import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../digits.dart';
import '../hijri.dart';
import '../location.dart';
import '../prayer.dart';
import '../prayer_page.dart';
import '../qibla.dart';
import '../store.dart';

/// Prayer times and Qibla on one page, also used by the web layout. With no
/// compass the dial is drawn with north up, as the mobile tab does without
/// a sensor.
class DesktopPrayer extends StatelessWidget {
  const DesktopPrayer({
    super.key,
    this.qiblaNote = 'لا توجد بوصلة في الحاسوب: اجعل أعلى الدائرة نحو الشمال، والسهم يشير إلى القبلة.',
  });

  /// How to read the north-up dial on this platform.
  final String qiblaNote;

  @override
  Widget build(BuildContext context) => LocationGate(
    message: 'حدّد موقعك لعرض مواقيت الصلاة واتجاه القبلة',
    builder: (context, loc) => LayoutBuilder(
      // two panels side by side when they fit; on a phone, full width each
      builder: (context, box) {
        final room = box.maxWidth - 2 * 20;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(width: min(560.0, room), child: _times(context, loc)),
                SizedBox(width: min(400.0, room), child: _qibla(context, loc)),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _panel(BuildContext context, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }

  Widget _times(BuildContext context, SavedLocation loc) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final (times, next) = upcomingPrayers(loc, DateTime.now());
    return _panel(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مواقيت الصلاة',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      formatHijri(DateTime.now(), arabicDigits: arabic),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => chooseLocation(context),
                icon: const Icon(Icons.location_on_outlined),
                label: Text(loc.name),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: i == next ? scheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    prayerNames[i],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: i == next ? FontWeight.bold : null,
                      color: i == next ? scheme.onPrimaryContainer : null,
                    ),
                  ),
                  if (i == next) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'القادمة',
                        style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    clock(
                      times.all[i].hour,
                      times.all[i].minute,
                      arabic: arabic,
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: i == next ? FontWeight.bold : null,
                      color: i == next ? scheme.onPrimaryContainer : null,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'طريقة الحساب: ${currentMethod(loc).name}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _qibla(BuildContext context, SavedLocation loc) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final bearing = qiblaBearing(loc.lat, loc.lng);
    return _panel(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('القبلة', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Center(
            child: SizedBox.square(
              dimension: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(260),
                    painter: QiblaDialPainter(
                      scheme,
                      fontFamily: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.fontFamily,
                    ),
                  ),
                  Transform.rotate(
                    angle: bearing * pi / 180,
                    child: Icon(
                      Icons.navigation,
                      size: 120,
                      color: scheme.tertiary,
                    ),
                  ),
                  Icon(Icons.mosque, size: 28, color: scheme.onPrimary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'اتجاه القبلة: ${digits(bearing.round(), arabic: arabic)}° من الشمال',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            qiblaNote,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
