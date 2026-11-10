import 'package:flutter_test/flutter_test.dart';
import 'package:wazaqer/digits.dart';
import 'package:wazaqer/prayer.dart';

/// Reference: api.aladhan.com for 2026-11-10 (local times converted to UTC).
void main() {
  void expectTimes(PrayerTimes t, List<String> utc) {
    for (var i = 0; i < 6; i++) {
      final got = t.all[i].toUtc();
      final p = utc[i].split(':');
      final want = DateTime.utc(2026, 11, 10, int.parse(p[0]), int.parse(p[1]));
      expect(got.difference(want).inMinutes.abs(), lessThanOrEqualTo(2),
          reason: '${prayerNames[i]}: got $got, want $want');
    }
  }

  final date = DateTime(2026, 11, 10);

  test('Makkah, Umm al-Qura (isha = maghrib + 90 min)', () {
    expectTimes(prayerTimes(date, 21.4225, 39.8262, methodById('makkah')),
        ['02:10', '03:29', '09:05', '12:17', '14:40', '16:10']);
  });

  test('Cairo, Egyptian authority', () {
    expectTimes(prayerTimes(date, 30.0444, 31.2357, methodById('egypt')),
        ['02:47', '04:16', '09:39', '12:41', '15:02', '16:21']);
  });

  test('London, MWL', () {
    expectTimes(prayerTimes(date, 51.5074, -0.1278, methodById('mwl')),
        ['05:14', '07:10', '11:44', '13:55', '16:18', '18:08']);
  });

  test('qibla bearing from known cities', () {
    expect(qiblaBearing(30.0444, 31.2357), closeTo(136.1, 0.5)); // Cairo
    expect(qiblaBearing(51.5074, -0.1278), closeTo(118.99, 0.5)); // London
    expect(qiblaBearing(40.7128, -74.0060), closeTo(58.5, 0.5)); // New York
    expect(qiblaBearing(-6.2088, 106.8456), closeTo(295.1, 0.5)); // Jakarta
  });

  test('nearest city picks the regional method', () {
    expect(nearestCity(30.1, 31.3).method, 'egypt');
    expect(nearestCity(21.5, 39.9).name, 'مكة المكرمة');
    expect(methodById('nope').id, 'mwl');
  });

  test('12-hour clock label', () {
    expect(clock(8, 0), '٠٨:٠٠ ص');
    expect(clock(22, 5), '١٠:٠٥ م');
    expect(clock(0, 30, arabic: false), '12:30 ص');
    expect(clock(12, 0, arabic: false), '12:00 م');
  });
}
