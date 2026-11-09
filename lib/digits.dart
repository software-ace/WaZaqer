const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Latin digits by default? No: Arabic-Indic unless the caller asks for Latin.
String digits(int n, {bool arabic = true}) => arabic
    ? n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join()
    : '$n';
