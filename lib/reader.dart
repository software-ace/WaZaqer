import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'adhkar.dart';
import 'digits.dart';
import 'store.dart';

/// Paged dhikr reader: one dhikr per card, a built-in tap counter with a
/// progress ring, auto-advance, persisted per-group progress, and a
/// completion state after the last dhikr.
///
/// Settings are read from Store with defaults; the settings UI comes with
/// the settings epic.
class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.group});

  final DhikrGroup group;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late List<int> _counts;
  late int _index;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    final saved = Store.s('prog:${widget.group.id}');
    if (saved != null) {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      _counts = [for (final c in (j['c'] as List)) c as int];
      final i = j['i'] as int;
      // a finished group reopens on the done page
      _index = i >= widget.group.items.length ||
              _counts.every((c) => c > 0)
          ? widget.group.items.length
          : i.clamp(0, widget.group.items.length - 1);
    } else {
      _index = 0;
      _counts = [for (final _ in widget.group.items) 0];
    }
    _controller = PageController(initialPage: _index);
    _wake(true);
  }

  @override
  void dispose() {
    _wake(false);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _wake(bool on) async {
    if (Store.b('keepAwake', def: true)) {
      try {
        await WakelockPlus.toggle(enable: on);
      } on Exception {
        // keep-awake is a nicety; unsupported platforms stay silent
      }
    }
  }

  void _persist() => Store.setS(
      'prog:${widget.group.id}', jsonEncode({'i': _index, 'c': _counts}));

  DhikrItem get _item => widget.group.items[_index];

  void _increment() {
    if (_counts[_index] >= _item.count) return;
    if (Store.b('haptics', def: true)) HapticFeedback.lightImpact();
    if (Store.b('sound', def: false)) SystemSound.play(SystemSoundType.click);
    setState(() {
      _counts[_index]++;
      _persist();
      if (_counts[_index] >= _item.count && Store.b('autoAdvance', def: true)) {
        if (_index < widget.group.items.length - 1) {
          _controller.nextPage(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        } else {
          _controller.jumpToPage(widget.group.items.length);
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _index = 0;
      _counts = [for (final _ in widget.group.items) 0];
      _persist();
      _controller.jumpToPage(0);
    });
  }

  void _copy() {
    final item = widget.group.items[_index];
    Clipboard.setData(ClipboardData(
      text: [
        item.text,
        if (item.note.isNotEmpty) item.note,
        if (item.source.isNotEmpty) item.source,
      ].join('\n\n'),
    ));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }

  void _share() {
    final item = widget.group.items[_index];
    final text = [
      item.text,
      if (item.note.isNotEmpty) item.note,
      if (item.source.isNotEmpty) item.source,
    ].join('\n\n');
    try {
      SharePlus.instance.share(
        ShareParams(text: '${widget.group.title}\n\n$text',
            title: widget.group.title),
      );
    } on Exception {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('المشاركة غير مدعومة')));
    }
  }

  void _reminders() {
    // placeholder until the reminders epic lands
    showModalBottomSheet(
      context: context,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('التذكيرات — قريبًا'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(widget.group.title),
        actions: [
          IconButton(
              icon: const Icon(Icons.share), onPressed: _share),
          IconButton(
              icon: const Icon(Icons.copy), onPressed: _copy),
          IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: _reminders),
          IconButton(
              icon: const Icon(Icons.restart_alt), onPressed: _reset),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.group.items.length + 1,
        onPageChanged: (i) => setState(() {
          _index = i;
          _persist();
        }),
        itemBuilder: (context, i) => i < widget.group.items.length
            ? _buildDhikr(context, scheme, arabic, i)
            : _buildDone(context, scheme),
      ),
    );
  }

  // pages render by their own index: PageView builds neighbours mid-jump,
  // when _index may already sit on another page
  Widget _buildDhikr(
      BuildContext context, ColorScheme scheme, bool arabic, int i) {
    final item = widget.group.items[i];
    final text = Store.b('tashkeel', def: true)
        ? item.text
        : stripTashkeel(item.text);
    final fontSize = Store.i('dhikrFontSize', def: 26);
    final fontFamily = Store.s('fontFamily');
    final style = Theme.of(context).textTheme.titleLarge!.copyWith(
          fontSize: fontSize.toDouble(),
          height: 1.9,
          fontFamily:
              (fontFamily != null && fontFamily.isNotEmpty) ? fontFamily : null,
        );
    return Column(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              onTap: _increment,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(text, style: style, textAlign: TextAlign.center),
                      if (item.note.isNotEmpty || item.source.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          const Expanded(
                              child: Divider(indent: 8, endIndent: 8)),
                          Icon(Icons.menu_book,
                              size: 16, color: scheme.onSurfaceVariant),
                          const Expanded(
                              child: Divider(indent: 8, endIndent: 8)),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          item.source.isNotEmpty ? item.source : item.note,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(repeatLabel(item.count, arabicDigits: arabic),
                  style: Theme.of(context).textTheme.bodySmall),
              _Counter(
                done: _counts[i],
                total: item.count,
                arabic: arabic,
                onTap: _increment,
              ),
              Text('${digits(i + 1, arabic: arabic)} / '
                  '${digits(widget.group.items.length, arabic: arabic)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDone(BuildContext context, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 72, color: scheme.primary),
          const SizedBox(height: 16),
          Text('أتممت الذكر', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            widget.group.title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('إعادة'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رجوع'),
          ),
        ],
      ),
    );
  }
}

/// Circular counter: ring fills toward the repeat total, number in the middle.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.done,
    required this.total,
    required this.arabic,
    required this.onTap,
  });

  final int done;
  final int total;
  final bool arabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: total > 0 ? done / total : 0,
              strokeWidth: 4,
              backgroundColor: scheme.surfaceContainerHighest,
              strokeCap: StrokeCap.round,
            ),
            Text(
              digits(done, arabic: arabic),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
