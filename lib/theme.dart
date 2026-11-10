import 'package:flutter/material.dart';

abstract final class WaZaqerTheme {
  static const seed = Color(0xFF0E7C5B); // deep green

  /// Accent presets offered in settings; the first is the default.
  static const accents = [
    seed,
    Color(0xFF00796B), // teal
    Color(0xFF1565C0), // blue
    Color(0xFF3949AB), // indigo
    Color(0xFF6A1B9A), // purple
    Color(0xFFAD1457), // rose
    Color(0xFFC62828), // red
    Color(0xFFEF6C00), // orange
    Color(0xFF8D6E63), // brown
  ];

  static final light = of(seed, Brightness.light);
  static final dark = of(seed, Brightness.dark);

  static ThemeData of(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Noto Naskh Arabic', // bundled OFL naskh, Arabic-first default
      colorScheme: scheme,
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
