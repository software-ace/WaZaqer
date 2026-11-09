import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:wazaqer/adhkar.dart';

void main() {
  // parse the shipped asset exactly as the app will
  final data = AdhkarData.fromJson(
    File('assets/adhkar.json').readAsStringSync(),
  );

  test('12 categories, content present', () {
    expect(data.categories, hasLength(12));
    expect(data.groups.length, greaterThan(130));
    expect(data.groups.every((g) => g.items.isNotEmpty), isTrue);
    expect(
      data.groups.every((g) => g.items.every((i) => i.text.trim().isNotEmpty)),
      isTrue,
    );
    expect(
      data.groups.every((g) => g.items.every((i) => i.count >= 1)),
      isTrue,
    );
  });

  test('no orphan groups, ids unique', () {
    final ids = data.groups.map((g) => g.id);
    expect(ids, hasLength(ids.toSet().length));
    final known = ids.toSet();
    for (final c in data.categories) {
      expect(c.groupIds.every(known.contains), isTrue,
          reason: '${c.id} references unknown group');
    }
    // every group belongs to a real category
    final catIds = data.categories.map((c) => c.id).toSet();
    expect(data.groups.every((g) => catIds.contains(g.category)), isTrue);
    // 'all' category holds every group exactly once
    final all = data.categories.firstWhere((c) => c.id == 'all');
    expect(all.groupIds, unorderedEquals(ids));
  });

  test('every group belongs to a real category, none to all', () {
    final all = data.categories.firstWhere((c) => c.id == 'all');
    expect(all.groupIds, contains(data.groups.first.id));
    for (final g in data.groups) {
      expect(g.category, isNot('all'));
    }
  });

  test('stripTashkeel removes diacritics, keeps letters', () {
    expect(stripTashkeel('اللّٰهُمَّ صَلِّ'), 'اللهم صل');
    expect(stripTashkeel('سُبْحَانَكَ\nاللَّهُمَّ'), 'سبحانك اللهم');
    expect(stripTashkeel('بِسْمِ'), contains('بسم'));
  });

  test('repeat labels', () {
    expect(repeatLabel(1), 'مرة واحدة');
    expect(repeatLabel(2), 'مرتان');
    expect(repeatLabel(3), '٣ مرات');
    expect(repeatLabel(10), '١٠ مرات');
    expect(repeatLabel(100), '١٠٠ مرة');
    expect(repeatLabel(7, arabicDigits: false), '7 مرات');
  });
}
