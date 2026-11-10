const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Latin digits by default? No: Arabic-Indic unless the caller asks for Latin.
String digits(int n, {bool arabic = true}) => arabic
    ? n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join()
    : '$n';

/// 12-hour clock: ٠٨:٠٠ ص، ١٠:٣٠ م
String clock(int hour, int minute, {bool arabic = true}) {
  String two(int n) => digits(n, arabic: arabic).padLeft(2, arabic ? '٠' : '0');
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '${two(h)}:${two(minute)} ${hour < 12 ? 'ص' : 'م'}';
}
