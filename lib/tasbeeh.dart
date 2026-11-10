import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'digits.dart';
import 'header.dart';
import 'store.dart';

/// Tasbeeh rules, kept free of widgets so the wrap/cycle logic is testable.
class TasbeehState {
  TasbeehState({this.count = 0, this.cycles = 0, this.target = 33});

  int count;
  int cycles;

  /// null = unlimited. Stored as 0 in SharedPreferences, mapped in the widget.
  int? target;

  void tap() {
    // The tap that reaches the target completes the cycle: it resets the
    // count and bumps cycles, with the strong haptic as feedback.
    if (target != null && count + 1 == target) {
      count = 0;
      cycles++;
      return;
    }
    count++;
  }

  void setTarget(int? t) {
    target = t;
    // A new round starts at 0; cycles keep, they count finished rounds.
    count = 0;
  }
}

class TasbeehPage extends StatefulWidget {
  const TasbeehPage({super.key});

  @override
  State<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends State<TasbeehPage> {
  final _st = TasbeehState(
    count: Store.i('tasbeehCount'),
    cycles: Store.i('tasbeehCycles'),
    target: () {
      final t = Store.i('tasbeehTarget', def: 33);
      return t == 0 ? null : t;
    }(),
  );

  void _save() {
    Store.setI('tasbeehCount', _st.count);
    Store.setI('tasbeehCycles', _st.cycles);
    Store.setI('tasbeehTarget', _st.target ?? 0);
  }

  void _tap() {
    setState(_st.tap);
    // Heavy on cycle completion so wrapping is felt, light on every other tap.
    HapticFeedback.lightImpact();
    if (_st.count == 0 && _st.cycles > 0) HapticFeedback.heavyImpact();
    _save();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة الضبط؟'),
        content: const Text('يعود العدد والدورات إلى الصفر.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _st.count = 0;
        _st.cycles = 0;
      });
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arabic = Store.b('arabicDigits', def: true);
    final t = _st.target;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        // behaviour: opaque so taps on empty areas count too; the bottom
        // navigation sits outside this body and is unaffected.
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Column(
          children: [
            WaZaqerHeader(
              title: 'السبحة',
              subtitle: 'اضغط في أي مكان للتسبيح',
              actions: [
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  color: scheme.onPrimary,
                  tooltip: 'إعادة الضبط',
                  onPressed: _reset,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        _save();
                      },
                    ),
                    // Flexible: on a wide or short window the square takes the
                    // space left, instead of the full width, and overflowing
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final size = box.biggest.width;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (t != null)
                                    SizedBox(
                                      width: size,
                                      height: size,
                                      child: CircularProgressIndicator(
                                        value: _st.count / t,
                                        strokeWidth: 12,
                                        strokeCap: StrokeCap.round,
                                        color: scheme.primary,
                                        backgroundColor: scheme.primary
                                            .withValues(alpha: 0.15),
                                      ),
                                    ),
                                  Text(
                                    digits(_st.count, arabic: arabic),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(color: scheme.onSurface),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            'الدورات: ${digits(_st.cycles, arabic: arabic)}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'الهدف: ${t == null ? '∞' : digits(t, arabic: arabic)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
