import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../adhkar.dart';
import '../digits.dart';
import '../reader.dart' show shareReading;
import '../reader_controller.dart';
import '../reminders.dart';
import '../settings.dart' show fontFamilies;
import '../store.dart';
import 'adhkar_panes.dart' show copyWithNotice;
import 'desktop_shell.dart' show KeyHint;

/// Desktop reader for one group: a numbered strip of every dhikr, the
/// current one as a large card, and a counter with previous/next beside it.
///
/// Keys while it has focus: Space or Enter counts, ← next and → previous
/// (reading direction is right to left), F toggles focus mode, Ctrl C copies.
class ReaderPane extends StatefulWidget {
  const ReaderPane({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.focusMode,
    required this.onToggleFocusMode,
  });

  final ReaderController controller;
  final FocusNode focusNode;
  final bool focusMode;
  final VoidCallback onToggleFocusMode;

  @override
  State<ReaderPane> createState() => _ReaderPaneState();
}

class _ReaderPaneState extends State<ReaderPane> {
  ReaderController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    keepAwake(true);
  }

  @override
  void dispose() {
    keepAwake(false);
    super.dispose();
  }

  void _tap() {
    if (_c.isDone) return;
    final wasDone = _c.itemDone(_c.index);
    if (!_c.tap()) return;
    if (wasDone) return _c.next();
    // let the ring visibly fill before moving on
    final at = _c.index;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _c.index == at) _c.next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final arabic = Store.b('arabicDigits', def: true);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _tap,
        const SingleActivator(LogicalKeyboardKey.enter): _tap,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _c.next,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _c.previous,
        const SingleActivator(LogicalKeyboardKey.keyF):
            widget.onToggleFocusMode,
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () =>
            copyWithNotice(context, _c.shareText),
      },
      child: Focus(
        focusNode: widget.focusNode,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, arabic),
              const SizedBox(height: 14),
              _steps(context, arabic),
              const SizedBox(height: 16),
              Expanded(
                child: _c.isDone ? _done(context) : _card(context, _c.item!),
              ),
              if (!_c.isDone) ...[
                const SizedBox(height: 16),
                _footer(context, arabic, _c.item!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool arabic) {
    final scheme = Theme.of(context).colorScheme;
    final pos = _c.isDone
        ? 'اكتملت المجموعة'
        : '${digits(_c.index + 1, arabic: arabic)} من ${digits(_c.length, arabic: arabic)}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _c.group.title,
                style: const TextStyle(
                  fontFamily: 'Noto Naskh Arabic',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              Text(pos, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          tooltip: widget.focusMode ? 'إظهار القوائم (F)' : 'وضع التركيز (F)',
          isSelected: widget.focusMode,
          icon: const Icon(Icons.fullscreen),
          selectedIcon: const Icon(Icons.fullscreen_exit),
          onPressed: widget.onToggleFocusMode,
        ),
        IconButton(
          tooltip: 'نسخ (Ctrl C)',
          icon: const Icon(Icons.copy),
          onPressed: () => copyWithNotice(context, _c.shareText),
        ),
        IconButton(
          tooltip: 'مشاركة',
          icon: const Icon(Icons.share),
          onPressed: () => shareReading(context, _c),
        ),
        IconButton(
          tooltip: 'إعادة',
          icon: const Icon(Icons.restart_alt),
          onPressed: _c.reset,
        ),
        IconButton(
          // background reminders only fire on Android
          tooltip: Reminders.supported
              ? 'إعدادات التذكير'
              : 'التذكير متاح على أندرويد فقط',
          icon: const Icon(Icons.notifications_none),
          onPressed: Reminders.supported
              ? () => showReminderSheet(context, _c.group)
              : null,
        ),
      ],
    );
  }

  Widget _steps(BuildContext context, bool arabic) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < _c.length; i++)
          Tooltip(
            message: 'الذكر ${digits(i + 1, arabic: arabic)}',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                _c.goTo(i);
                widget.focusNode.requestFocus();
              },
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _c.itemDone(i) && i != _c.index
                      ? scheme.primary
                      : scheme.surface,
                  border: Border.all(
                    width: i == _c.index ? 2 : 1,
                    color: i == _c.index
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
                child: Text(
                  digits(i + 1, arabic: arabic),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == _c.index ? FontWeight.bold : null,
                    color: _c.itemDone(i) && i != _c.index
                        ? scheme.onPrimary
                        : i == _c.index
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, DhikrItem item) {
    final scheme = Theme.of(context).colorScheme;
    final text = Store.b('tashkeel', def: true)
        ? item.text
        : stripTashkeel(item.text);
    final font = Store.s('fontFamily');
    final reading = TextStyle(
      // the interface font is Tajawal; adhkar keep the chosen reading font
      fontFamily: (font != null && font.isNotEmpty) ? font : fontFamilies.first,
      fontSize: 30 * Store.i('fontScale', def: 100) / 100,
      height: 2,
      color: scheme.onSurface,
    );
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.8);
    Widget meta(String label, String body) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: scheme.onSurface,
            ),
          ),
          Text(body, style: muted),
        ],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          widget.focusNode.requestFocus();
          _tap();
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            child: ConstrainedBox(
              // a comfortable reading line on wide windows
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  Text(text, style: reading, textAlign: TextAlign.center),
                  if (item.note.isNotEmpty || item.source.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Divider(color: scheme.outlineVariant),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.note.isNotEmpty) meta('الفضل', item.note),
                        if (item.note.isNotEmpty && item.source.isNotEmpty)
                          const SizedBox(width: 24),
                        if (item.source.isNotEmpty)
                          meta('التخريج', item.source),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, bool arabic, DhikrItem item) {
    final scheme = Theme.of(context).colorScheme;
    final count = _c.counts[_c.index];
    final muted = TextStyle(color: scheme.onSurfaceVariant, fontSize: 13);
    return Row(
      children: [
        Expanded(
          child: Text(
            repeatLabel(item.count, arabicDigits: arabic),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        IconButton.outlined(
          tooltip: 'السابق (→)',
          // arrow_back mirrors under RTL, so it points right: backwards
          icon: const Icon(Icons.arrow_back),
          onPressed: _c.index > 0 ? _c.previous : null,
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'عدّ (Space)',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              widget.focusNode.requestFocus();
              _tap();
            },
            child: SizedBox.square(
              dimension: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 80,
                    child: CircularProgressIndicator(
                      value: item.count > 0 ? count / item.count : 0,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  Text(
                    digits(count, arabic: arabic),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.outlined(
          tooltip: 'التالي (←)',
          icon: const Icon(Icons.arrow_forward),
          onPressed: _c.next,
        ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              const KeyHint('Space'),
              Text('عدّ', style: muted),
              const KeyHint('←'),
              Text('التالي', style: muted),
              const KeyHint('→'),
              Text('السابق', style: muted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 72, color: scheme.primary),
          const SizedBox(height: 16),
          Text('أتممت الذكر', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _c.group.title,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _c.reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('إعادة'),
              ),
              OutlinedButton.icon(
                onPressed: () => copyWithNotice(context, _c.shareText),
                icon: const Icon(Icons.copy),
                label: const Text('نسخ المجموعة كاملة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
