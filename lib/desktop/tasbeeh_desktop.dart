import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../digits.dart';
import '../store.dart';
import '../tasbeeh.dart';
import 'desktop_shell.dart' show KeyHint;

/// Desktop tasbeeh: one large click target with the ring, target and cycles
/// beside it. Space or Enter counts, Esc offers to reset. Same saved
/// counter as the mobile tab.
class DesktopTasbeeh extends StatefulWidget {
  const DesktopTasbeeh({super.key, required this.active});

  /// Whether this section is on screen; it then takes keyboard focus.
  final bool active;

  @override
  State<DesktopTasbeeh> createState() => _DesktopTasbeehState();
}

class _DesktopTasbeehState extends State<DesktopTasbeeh> {
  final _st = TasbeehState.load();
  final _focus = FocusNode(debugLabel: 'tasbeeh');

  @override
  void didUpdateWidget(DesktopTasbeeh old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _focus.requestFocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _tap() {
    setState(_st.tap);
    _st.save();
  }

  Future<void> _reset() async {
    if (!await confirmTasbeehReset(context)) return;
    setState(() {
      _st.count = 0;
      _st.cycles = 0;
    });
    _st.save();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final t = _st.target;
    Widget stat(String label, String value) => Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _tap,
        const SingleActivator(LogicalKeyboardKey.enter): _tap,
        const SingleActivator(LogicalKeyboardKey.escape): _reset,
      },
      child: Focus(
        focusNode: _focus,
        autofocus: widget.active,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SegmentedButton<int?>(
                          segments: [
                            ButtonSegment(
                              value: 33,
                              label: Text(digits(33, arabic: arabic)),
                            ),
                            ButtonSegment(
                              value: 100,
                              label: Text(digits(100, arabic: arabic)),
                            ),
                            const ButtonSegment(value: null, label: Text('∞')),
                          ],
                          selected: {t},
                          onSelectionChanged: (s) {
                            setState(() => _st.setTarget(s.first));
                            _st.save();
                            _focus.requestFocus();
                          },
                        ),
                        const SizedBox(height: 24),
                        Tooltip(
                          message: 'سبّح (Space)',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              _focus.requestFocus();
                              _tap();
                            },
                            child: SizedBox.square(
                              dimension: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox.square(
                                    dimension: 280,
                                    child: CircularProgressIndicator(
                                      value: t == null ? 0 : _st.count / t,
                                      strokeWidth: 14,
                                      strokeCap: StrokeCap.round,
                                      backgroundColor:
                                          scheme.surfaceContainerHighest,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        digits(_st.count, arabic: arabic),
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'انقر أو اضغط Space',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      stat(
                        'الهدف',
                        t == null ? '∞' : digits(t, arabic: arabic),
                      ),
                      const SizedBox(height: 12),
                      stat('الدورات', digits(_st.cycles, arabic: arabic)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('إعادة العدّ'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const KeyHint('Space'),
                          Text(
                            'عدّ',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          const KeyHint('Esc'),
                          Text(
                            'إعادة العدّ',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
