import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'digits.dart';
import 'header.dart';
import 'location.dart';
import 'prayer.dart';
import 'store.dart';

/// Qibla compass: magnetometer heading against the great-circle bearing to
/// the Kaaba. AppShell builds this tab only while it is visible, so the
/// sensor stops when the user leaves.
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<MagnetometerEvent>? _sub;
  bool _noSensor = false;
  // low-pass filtered heading as a unit vector, so 359°→1° doesn't jump
  double _sx = 0, _cy = 1;
  bool _haveHeading = false;

  @override
  void initState() {
    super.initState();
    try {
      _sub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval)
          .listen(_onField, onError: (_) => setState(() => _noSensor = true));
    } on Exception {
      _noSensor = true;
    }
  }

  void _onField(MagnetometerEvent e) {
    // Phone held flat: heading of the top edge, clockwise from magnetic
    // north. shortcut: no tilt compensation or magnetic declination (a few
    // degrees in most Muslim-majority regions); add accelerometer fusion and
    // a declination model if accuracy complaints come in.
    final h = atan2(-e.x, e.y);
    setState(() {
      _sx = _haveHeading ? _sx * 0.85 + sin(h) * 0.15 : sin(h);
      _cy = _haveHeading ? _cy * 0.85 + cos(h) * 0.15 : cos(h);
      _haveHeading = true;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WaZaqerHeader(title: 'القبلة'),
        Expanded(
          child: LocationGate(
            message: 'حدّد موقعك لمعرفة اتجاه القبلة',
            builder: _compass,
          ),
        ),
      ],
    );
  }

  Widget _compass(BuildContext context, SavedLocation loc) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final bearing = qiblaBearing(loc.lat, loc.lng);
    final heading = atan2(_sx, _cy) * 180 / pi;
    final live = _haveHeading && !_noSensor;
    final diff = ((bearing - heading) % 360 + 360) % 360;
    final aligned = live && (diff < 5 || diff > 355);
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'اتجاه القبلة: ${digits(bearing.round(), arabic: arabic)}° من الشمال',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(loc.name, textAlign: TextAlign.center, style: muted),
        const SizedBox(height: 24),
        Center(
          child: SizedBox.square(
            dimension: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // the dial turns so its north follows magnetic north
                Transform.rotate(
                  angle: live ? -heading * pi / 180 : 0,
                  child: CustomPaint(
                    size: const Size.square(260),
                    painter: _DialPainter(scheme),
                  ),
                ),
                Transform.rotate(
                  angle: (live ? diff : bearing) * pi / 180,
                  child: Icon(
                    Icons.navigation,
                    size: 120,
                    color: aligned ? scheme.primary : scheme.tertiary,
                  ),
                ),
                Icon(Icons.mosque, size: 28, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (aligned)
          Text('أنت متجه نحو القبلة',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
        Text(
          live
              ? 'ضع الهاتف بشكل مسطح، وإن بدا الاتجاه غير دقيق فحرّكه على شكل الرقم ٨ لمعايرة البوصلة'
              : 'لا يتوفر مستشعر البوصلة على هذا الجهاز؛ السهم يشير إلى القبلة باعتبار أعلى الشاشة هو الشمال',
          textAlign: TextAlign.center,
          style: muted,
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.scheme);

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = scheme.surfaceContainerHighest);
    final tick = Paint()
      ..color = scheme.outline
      ..strokeWidth = 2;
    for (var deg = 0; deg < 360; deg += 30) {
      final a = deg * pi / 180;
      final dir = Offset(sin(a), -cos(a));
      canvas.drawLine(c + dir * (r - 12), c + dir * r, tick);
    }
    // ش ق ج غ: north, east, south, west
    const labels = ['ش', 'ق', 'ج', 'غ'];
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == 0 ? scheme.error : scheme.onSurfaceVariant,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final p = c + Offset(sin(a), -cos(a)) * (r - 28);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.scheme != scheme;
}
