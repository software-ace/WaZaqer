import 'dart:math';

/// Offline prayer times and qibla bearing. The `adhan` package is Dart 2
/// only, so this is the standard astronomical method (as in praytimes.org):
/// sun declination and equation of time, then the hour angle at which the
/// sun reaches each prayer's depression angle.

class CalcMethod {
  const CalcMethod(this.id, this.name, this.fajr, this.isha,
      {this.ishaMinutes = 0});

  final String id;
  final String name;
  final double fajr; // sun depression angle, degrees
  final double isha; // ignored when ishaMinutes > 0
  final int ishaMinutes; // fixed minutes after maghrib (Umm al-Qura, Qatar)
}

const methods = [
  CalcMethod('mwl', 'رابطة العالم الإسلامي', 18, 17),
  CalcMethod('makkah', 'أم القرى، مكة المكرمة', 18.5, 0, ishaMinutes: 90),
  CalcMethod('egypt', 'الهيئة المصرية العامة للمساحة', 19.5, 17.5),
  CalcMethod('karachi', 'جامعة العلوم الإسلامية، كراتشي', 18, 18),
  CalcMethod('isna', 'الجمعية الإسلامية لأمريكا الشمالية', 15, 15),
  CalcMethod('dubai', 'دبي', 18.2, 18.2),
  CalcMethod('kuwait', 'الكويت', 18, 17.5),
  CalcMethod('qatar', 'قطر', 18, 0, ishaMinutes: 90),
  CalcMethod('turkey', 'رئاسة الشؤون الدينية التركية', 18, 17),
  CalcMethod('morocco', 'المغرب', 19, 17),
  CalcMethod('algeria', 'الجزائر', 18, 17),
  CalcMethod('tunisia', 'تونس', 18, 18),
  CalcMethod('singapore', 'سنغافورة وماليزيا وإندونيسيا', 20, 18),
];

CalcMethod methodById(String? id) =>
    methods.firstWhere((m) => m.id == id, orElse: () => methods.first);

class City {
  const City(this.name, this.lat, this.lng, this.method);

  final String name;
  final double lat;
  final double lng;
  final String method; // CalcMethod.id used in the region
}

/// Manual-pick list; also drives the automatic method (nearest city's).
const cities = [
  City('مكة المكرمة', 21.4225, 39.8262, 'makkah'),
  City('المدينة المنورة', 24.4686, 39.6142, 'makkah'),
  City('الرياض', 24.7136, 46.6753, 'makkah'),
  City('جدة', 21.4858, 39.1925, 'makkah'),
  City('الدمام', 26.4207, 50.0888, 'makkah'),
  City('الكويت', 29.3759, 47.9774, 'kuwait'),
  City('الدوحة', 25.2854, 51.5310, 'qatar'),
  City('المنامة', 26.2285, 50.5860, 'makkah'),
  City('دبي', 25.2048, 55.2708, 'dubai'),
  City('أبوظبي', 24.4539, 54.3773, 'dubai'),
  City('مسقط', 23.5880, 58.3829, 'mwl'),
  City('صنعاء', 15.3694, 44.1910, 'mwl'),
  City('القاهرة', 30.0444, 31.2357, 'egypt'),
  City('الإسكندرية', 31.2001, 29.9187, 'egypt'),
  City('الخرطوم', 15.5007, 32.5599, 'egypt'),
  City('طرابلس', 32.8872, 13.1913, 'egypt'),
  City('عمّان', 31.9454, 35.9284, 'mwl'),
  City('القدس', 31.7683, 35.2137, 'mwl'),
  City('غزة', 31.5017, 34.4668, 'mwl'),
  City('دمشق', 33.5138, 36.2765, 'mwl'),
  City('بيروت', 33.8938, 35.5018, 'mwl'),
  City('بغداد', 33.3152, 44.3661, 'mwl'),
  City('تونس', 36.8065, 10.1815, 'tunisia'),
  City('الجزائر', 36.7538, 3.0588, 'algeria'),
  City('الرباط', 34.0209, -6.8416, 'morocco'),
  City('الدار البيضاء', 33.5731, -7.5898, 'morocco'),
  City('نواكشوط', 18.0735, -15.9582, 'mwl'),
  City('إسطنبول', 41.0082, 28.9784, 'turkey'),
  City('أنقرة', 39.9334, 32.8597, 'turkey'),
  City('كراتشي', 24.8607, 67.0011, 'karachi'),
  City('لاهور', 31.5204, 74.3587, 'karachi'),
  City('دكا', 23.8103, 90.4125, 'karachi'),
  City('جاكرتا', -6.2088, 106.8456, 'singapore'),
  City('كوالالمبور', 3.1390, 101.6869, 'singapore'),
  City('سنغافورة', 1.3521, 103.8198, 'singapore'),
  City('لندن', 51.5074, -0.1278, 'mwl'),
  City('باريس', 48.8566, 2.3522, 'mwl'),
  City('برلين', 52.5200, 13.4050, 'mwl'),
  City('نيويورك', 40.7128, -74.0060, 'isna'),
  City('تورونتو', 43.6532, -79.3832, 'isna'),
];

City nearestCity(double lat, double lng) {
  // equirectangular distance is plenty to rank cities
  double d(City c) {
    final x = (c.lng - lng) * cos(_rad((c.lat + lat) / 2));
    final y = c.lat - lat;
    return x * x + y * y;
  }

  return cities.reduce((a, b) => d(a) <= d(b) ? a : b);
}

const prayerNames = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

class PrayerTimes {
  const PrayerTimes(this.all);

  /// Local times in [prayerNames] order: fajr, sunrise, dhuhr, asr, maghrib, isha.
  final List<DateTime> all;

  DateTime get sunrise => all[1];
  DateTime get maghrib => all[4];
}

/// Prayer times for the civil [date] at ([lat], [lng]), in device local time.
/// Asr uses the standard (Shafi'i) shadow factor.
/// shortcut: no high-latitude rule, so above ~48° in summer fajr/isha clamp
/// to midnight; add angle-based adjustment if users there need it.
PrayerTimes prayerTimes(DateTime date, double lat, double lng, CalcMethod m) {
  final jd = _julian(date.year, date.month, date.day) - lng / 360;

  // Each time is solved with the sun's position at a first guess of that
  // time (hours, local solar), like praytimes.org's single iteration.
  double noon(double t) => _fix(12 - _sun(jd + t / 24).$2, 24);
  double angleTime(double angle, double t, {bool before = false}) {
    final decl = _sun(jd + t / 24).$1;
    final cosH = (-sin(_rad(angle)) - sin(_rad(decl)) * sin(_rad(lat))) /
        (cos(_rad(decl)) * cos(_rad(lat)));
    final h = _deg(acos(cosH.clamp(-1.0, 1.0))) / 15;
    return noon(t) + (before ? -h : h);
  }

  double asr(double t) {
    final decl = _sun(jd + t / 24).$1;
    final angle = -_deg(atan(1 / (1 + tan(_rad((lat - decl).abs())))));
    return angleTime(angle, t);
  }

  final sunset = angleTime(0.833, 18);
  final hours = [
    angleTime(m.fajr, 5, before: true),
    angleTime(0.833, 6, before: true),
    noon(12),
    asr(13),
    sunset,
    m.ishaMinutes > 0 ? sunset + m.ishaMinutes / 60 : angleTime(m.isha, 18),
  ];
  final day = DateTime.utc(date.year, date.month, date.day);
  return PrayerTimes([
    for (final h in hours)
      // solar time → UTC, rounded to the minute, then to device local time
      day.add(Duration(minutes: ((h - lng / 15) * 60).round())).toLocal(),
  ]);
}

const kaabaLat = 21.4225, kaabaLng = 39.8262;

/// Initial great-circle bearing to the Kaaba, degrees clockwise from true north.
double qiblaBearing(double lat, double lng) {
  final p1 = _rad(lat), p2 = _rad(kaabaLat), dl = _rad(kaabaLng - lng);
  final b = atan2(sin(dl), cos(p1) * tan(p2) - sin(p1) * cos(dl));
  return _fix(_deg(b), 360);
}

double _rad(double d) => d * pi / 180;
double _deg(double r) => r * 180 / pi;
double _fix(double a, double b) => a - b * (a / b).floor();

double _julian(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = y ~/ 100;
  final b = 2 - a + a ~/ 4;
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524.5;
}

/// (declination°, equation of time in hours) for Julian date [jd].
(double, double) _sun(double jd) {
  final d = jd - 2451545.0;
  final g = _fix(357.529 + 0.98560028 * d, 360);
  final q = _fix(280.459 + 0.98564736 * d, 360);
  final l = _fix(q + 1.915 * sin(_rad(g)) + 0.020 * sin(_rad(2 * g)), 360);
  final e = 23.439 - 0.00000036 * d;
  final ra = _fix(_deg(atan2(cos(_rad(e)) * sin(_rad(l)), cos(_rad(l)))) / 15, 24);
  final decl = _deg(asin(sin(_rad(e)) * sin(_rad(l))));
  return (decl, q / 15 - ra);
}
