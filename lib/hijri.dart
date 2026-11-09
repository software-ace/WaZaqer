import 'digits.dart';

final hijriMonths = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأول', 'جمادى الآخر',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

/// Standard integer Hijri conversion (tabular, Kuwaiti algorithm).
/// shortcut: drifts ±1 day against Umm al-Qura, fine for a display date,
/// upgrade when reminders need prayer-accurate dates.
List<int> gregorianToHijri(DateTime date) {
  final day = date.day, month = date.month, year = date.year;
  final a = (14 - month) ~/ 12;
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  final jdn = day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 +
      y ~/ 400 - 32045;
  int l = jdn - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
      (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final hMonth = (24 * l) ~/ 709;
  final hDay = l - (709 * hMonth) ~/ 24;
  final hYear = 30 * n + j - 30;
  return [hYear, hMonth, hDay];
}

/// e.g. ٢٩ جمادى الأول ١٤٤٨
String formatHijri(DateTime date, {bool arabicDigits = true}) {
  final h = gregorianToHijri(date);
  return '${digits(h[2], arabic: arabicDigits)} '
      '${hijriMonths[h[1] - 1]} ${digits(h[0], arabic: arabicDigits)}';
}
