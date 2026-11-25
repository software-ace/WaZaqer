import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'adhkar.dart';
import 'digits.dart';
import 'reader_controller.dart';
import 'reminders.dart';
import 'store.dart';

/// Shares what [c] shows: the current dhikr, or on the done page the whole
/// group. A snackbar says so where the platform can't share.
void shareReading(BuildContext context, ReaderController c) {
  try {
    SharePlus.instance.share(
      ShareParams(
        text: '${c.group.title}\n\n${c.shareText}',
        title: c.group.title,
      ),
    );
  } on Exception {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('المشاركة غير مدعومة')));
  }
}

/// Paged dhikr reader: one dhikr per card, a built-in tap counter with a
/// progress ring, auto-advance, persisted per-group progress, and a
/// completion state after the last dhikr.
///
/// Settings are read from Store with the same defaults as the settings page.
class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.group,
    this.restartIfDone = false,
  });

  final DhikrGroup group;

  /// Start a finished group over instead of showing its done page. Set when
  /// a reminder opens the group: the reminder asks for a fresh reading.
  final bool restartIfDone;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final _c = ReaderController(
    widget.group,
    restartIfDone: widget.restartIfDone,
  )..addListener(_changed);
  late final _controller = PageController(initialPage: _c.index);

  @override
  void initState() {
    super.initState();
    keepAwake(true);
  }

  @override
  void dispose() {
    keepAwake(false);
    _c.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _increment() {
    if (_c.tap()) _advance();
  }

  // moves by animating the pager; onPageChanged then tells the controller
  void _advance() {
    if (_c.index < _c.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _controller.jumpToPage(_c.length);
    }
  }

  Future<void> _askLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الخروج من الأذكار؟'),
        content: const Text(
          'لم تُكمل الأذكار بعد. تقدّمك محفوظ ويمكنك المتابعة لاحقًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('متابعة'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  void _reset() {
    _c.reset();
    _controller.jumpToPage(0);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _c.shareText));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }

  void _reminders() => showReminderSheet(context, widget.group);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    // PopScope covers the app bar arrow, system back and the back gesture
    return PopScope(
      canPop: !_c.confirmLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askLeave();
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        // the title lives in the body box below: long titles were truncated here
        appBar: AppBar(
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: () => shareReading(context, _c)),
            IconButton(icon: const Icon(Icons.copy), onPressed: _copy),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: _reminders,
            ),
            IconButton(icon: const Icon(Icons.restart_alt), onPressed: _reset),
          ],
        ),
        body: Column(
          children: [
            _TitleBox(title: widget.group.title),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.group.items.length + 1,
                onPageChanged: _c.goTo,
                itemBuilder: (context, i) => i < widget.group.items.length
                    ? _buildDhikr(context, scheme, arabic, i)
                    : _buildDone(context, scheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // pages render by their own index: PageView builds neighbours mid-jump,
  // when _c.index may already sit on another page
  Widget _buildDhikr(
    BuildContext context,
    ColorScheme scheme,
    bool arabic,
    int i,
  ) {
    final item = widget.group.items[i];
    final text = Store.b('tashkeel', def: true)
        ? item.text
        : stripTashkeel(item.text);
    // fontScale: percent of the 26px base, from the settings stepper
    final fontSize = 26 * Store.i('fontScale', def: 100) / 100;
    final fontFamily = Store.s('fontFamily');
    final style = Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: fontSize,
      height: 1.9,
      fontFamily: (fontFamily != null && fontFamily.isNotEmpty)
          ? fontFamily
          : null,
    );
    return Column(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(indent: 8, endIndent: 8),
                            ),
                            Icon(
                              Icons.menu_book,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const Expanded(
                              child: Divider(indent: 8, endIndent: 8),
                            ),
                          ],
                        ),
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
              Text(
                repeatLabel(item.count, arabicDigits: arabic),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              _Counter(
                done: _c.counts[i],
                total: item.count,
                arabic: arabic,
                onTap: _increment,
              ),
              Text(
                '${digits(i + 1, arabic: arabic)} / '
                '${digits(widget.group.items.length, arabic: arabic)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
            style: Theme.of(context).textTheme.bodyMedium
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

/// Group title above the dhikr card; wraps instead of truncating.
class _TitleBox extends StatelessWidget {
  const _TitleBox({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
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
