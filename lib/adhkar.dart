import 'package:flutter/services.dart' show rootBundle;

import 'dart:convert';

import 'digits.dart';

/// Models and repository for the bundled adhkar content.

class DhikrItem {
  const DhikrItem({
    required this.text,
    required this.count,
    this.note = '',
    this.source = '',
  });

  final String text; // with tashkeel
  final int count; // times to repeat (1, 3, 7, 10, 100...)
  final String note; // virtue / fadl
  final String source; // takhrij: book, volume/page, hadith number

  factory DhikrItem.fromJson(Map<String, dynamic> j) => DhikrItem(
        text: j['text'] as String,
        count: j['count'] as int,
        note: j['note'] as String? ?? '',
        source: j['source'] as String? ?? '',
      );
}

class DhikrGroup {
  const DhikrGroup({
    required this.id,
    required this.title,
    required this.category,
    required this.items,
  });

  final String id;
  final String title;
  final String category;
  final List<DhikrItem> items;

  factory DhikrGroup.fromJson(Map<String, dynamic> j) => DhikrGroup(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        items: [
          for (final item in (j['items'] as List)) DhikrItem.fromJson(item)
        ],
      );
}

class AdhkarCategory {
  const AdhkarCategory({
    required this.id,
    required this.title,
    required this.en,
    required this.icon,
    required this.groupIds,
  });

  final String id;
  final String title; // Arabic
  final String en;
  final String icon; // Material icon code point name
  final List<String> groupIds; // ordered; 'all' holds every group

  factory AdhkarCategory.fromJson(
    Map<String, dynamic> j,
    List<DhikrGroup> allGroups,
  ) =>
      AdhkarCategory(
        id: j['id'] as String,
        title: j['title'] as String,
        en: j['en'] as String,
        icon: j['icon'] as String,
        groupIds: j['all'] == true
            ? [for (final g in allGroups) g.id]
            : [for (final g in allGroups) if (g.category == j['id']) g.id],
      );
}

class AdhkarData {
  const AdhkarData({required this.categories, required this.groups});

  final List<AdhkarCategory> categories;
  final List<DhikrGroup> groups;

  factory AdhkarData.fromJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final groups = [
      for (final g in (j['groups'] as List)) DhikrGroup.fromJson(g)
    ];
    return AdhkarData(
      categories: [
        for (final c in (j['categories'] as List))
          AdhkarCategory.fromJson(c, groups),
      ],
      groups: groups,
    );
  }

  static Future<AdhkarData> load() async =>
      AdhkarData.fromJson(await rootBundle.loadString('assets/adhkar.json'));
}

/// Removes harakat, shadda, sukun, dagger alif and tatweel — for the
/// no-tashkeel display setting and for search normalisation.
String stripTashkeel(String s) => s
    .replaceAll(RegExp('[\u064B-\u0652\u0670\u06D6-\u06ED\u0640]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Repeat-count label: مرة واحدة، مرتان، ٣ مرات، ١٠٠ مرة
String repeatLabel(int count, {bool arabicDigits = true}) {
  final n = digits(count, arabic: arabicDigits);
  if (count == 1) return 'مرة واحدة';
  if (count == 2) return 'مرتان';
  if (count == 100) return '$n مرة';
  if (count % 100 == 3 || count % 100 == 4 || count % 100 == 10) {
    return '$n مرات';
  }
  if (count >= 3 && count <= 10) return '$n مرات';
  return '$n مرة';
}
