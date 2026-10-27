import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/domain/overlays/danmaku_load_budget.dart';

void main() {
  test('sustained load reduces admission and retains a nonzero floor', () {
    final budget = DanmakuLoadBudget(40);
    expect(budget.observeWindow(.2), isFalse);
    expect(budget.density, 40);
    expect(budget.observeWindow(.2), isTrue);
    expect(budget.density, 20);
    budget.observeWindow(.2);
    expect(budget.observeWindow(.2), isTrue);
    expect(budget.density, 10);
    for (var i = 0; i < 1000; i++) {
      expect(budget.observeWindow(1), isFalse);
    }
    expect(budget.density, 10);
  });

  test(
    'isolated compositor stalls and measurement resets do not lower density',
    () {
      final budget = DanmakuLoadBudget(20);
      budget.observeWindow(.5);
      budget.observeWindow(0);
      budget.observeWindow(.5);
      expect(budget.density, 20);
      budget.resetMeasurements();
      expect(budget.observeWindow(.5), isFalse);
      expect(budget.density, 20);
    },
  );
}
