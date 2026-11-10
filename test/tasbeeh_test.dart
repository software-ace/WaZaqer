import 'package:flutter_test/flutter_test.dart';

import 'package:wazaqer/tasbeeh.dart';

void main() {
  test('target 33: taps count up, the tap that reaches the target wraps and cycles',
      () {
    final st = TasbeehState(target: 33);
    for (var i = 0; i < 32; i++) {
      st.tap();
      expect(st.count, i + 1);
      expect(st.cycles, 0);
    }
    st.tap(); // the 33rd tap completes the cycle
    expect(st.count, 0);
    expect(st.cycles, 1);

    // and the next round counts on
    st.tap();
    expect(st.count, 1);
    expect(st.cycles, 1);
  });

  test('target 100 wraps at 100', () {
    final st = TasbeehState(target: 100);
    for (var i = 0; i < 99; i++) {
      st.tap();
    }
    expect(st.count, 99);
    expect(st.cycles, 0);
    st.tap();
    expect(st.count, 0);
    expect(st.cycles, 1);
  });

  test('unlimited target never cycles', () {
    final st = TasbeehState(target: null);
    for (var i = 0; i < 250; i++) {
      st.tap();
    }
    expect(st.count, 250);
    expect(st.cycles, 0);
  });

  test('changing target starts a new count, keeps cycles', () {
    final st = TasbeehState(target: 33);
    for (var i = 0; i < 33; i++) {
      st.tap();
    }
    expect(st.cycles, 1);
    st.setTarget(100);
    expect(st.count, 0);
    expect(st.cycles, 1);
    st.tap();
    expect(st.count, 1);
  });
}
