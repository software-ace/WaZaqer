import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'adhkar.dart';
import 'store.dart';

/// Reading progress through one group: a count per dhikr and the current
/// position, saved under `prog:<group id>` as `{"i": index, "c": counts}`.
/// Shared by the mobile pager and the desktop reader pane; it knows nothing
/// about pages or animation, the UI decides how to move.
class ReaderController extends ChangeNotifier {
  ReaderController(this.group, {bool restartIfDone = false}) {
    final saved = Store.s(_key);
    if (saved != null) {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      final c = j['c'] as List;
      // fitted to the group: an update may have added or removed adhkar
      counts = [
        for (var k = 0; k < length; k++) k < c.length ? c[k] as int : 0,
      ];
      final i = j['i'] as int;
      // finished = every dhikr said its full number of times, not just started
      final done =
          i >= length || [for (var k = 0; k < length; k++) k].every(itemDone);
      // a finished group reopens on the done page, unless asked to restart
      index = done ? length : i.clamp(0, length - 1);
    }
    if (saved == null || (restartIfDone && isDone)) {
      index = 0;
      counts = [for (final _ in group.items) 0];
    }
  }

  final DhikrGroup group;

  /// Times each dhikr has been counted, in group order.
  late List<int> counts;

  /// Current dhikr; [length] means the done page after the last one.
  late int index;

  String get _key => 'prog:${group.id}';
  int get length => group.items.length;
  bool get isDone => index >= length;
  DhikrItem? get item => isDone ? null : group.items[index];
  bool itemDone(int i) => counts[i] >= group.items[i].count;
  int get doneCount =>
      [for (var i = 0; i < length; i++) i].where(itemDone).length;

  /// Leaving mid-way through a multi-dhikr group is worth confirming.
  bool get confirmLeave => length > 1 && !isDone && counts.any((c) => c > 0);

  void _persist() => Store.setS(_key, jsonEncode({'i': index, 'c': counts}));

  /// Counts the current dhikr. Returns true when the reader should move on:
  /// the card was already finished (revisited), or this tap finished it with
  /// auto-advance on. The caller decides how to move (page animation, jump).
  bool tap() {
    if (isDone) return false;
    if (itemDone(index)) return true;
    if (Store.b('haptics', def: true)) HapticFeedback.lightImpact();
    if (Store.b('sound', def: false)) SystemSound.play(SystemSoundType.click);
    counts[index]++;
    _persist();
    notifyListeners();
    return itemDone(index) && Store.b('autoAdvance', def: true);
  }

  /// Moves to dhikr [i], or the done page when [i] is [length].
  void goTo(int i) {
    index = i.clamp(0, length);
    _persist();
    notifyListeners();
  }

  void next() => goTo(index + 1);
  void previous() => goTo(index - 1);

  void reset() {
    index = 0;
    counts = [for (final _ in group.items) 0];
    _persist();
    notifyListeners();
  }

  static String _itemText(DhikrItem item) => [
    item.text,
    if (item.note.isNotEmpty) item.note,
    if (item.source.isNotEmpty) item.source,
  ].join('\n\n');

  /// The current dhikr, or on the done page (no single dhikr) the whole group.
  String get shareText => isDone
      ? group.items.map(_itemText).join('\n\n* * *\n\n')
      : _itemText(group.items[index]);

  /// Saved progress of [g] as (done, total) without loading a controller;
  /// null when the group was never opened.
  static (int, int)? savedProgress(DhikrGroup g) {
    final saved = Store.s('prog:${g.id}');
    if (saved == null) return null;
    final c = (jsonDecode(saved) as Map<String, dynamic>)['c'] as List;
    var done = 0;
    for (var i = 0; i < g.items.length && i < c.length; i++) {
      if ((c[i] as int) >= g.items[i].count) done++;
    }
    return (done, g.items.length);
  }
}

/// Keeps the screen on while reading, when the setting allows it.
Future<void> keepAwake(bool on) async {
  if (!Store.b('keepAwake', def: true)) return;
  try {
    await WakelockPlus.toggle(enable: on);
  } catch (_) {
    // keep-awake is a nicety; unsupported platforms (web throws a JS
    // error, not an Exception) stay silent
  }
}
