import 'package:bloc_cubit_base/core/base_component/ui_effect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factory assigns a new revision to every one-shot effect', () {
    final factory = _EffectFactory();

    final first = factory.createEffect('open-dialog');
    final second = factory.createEffect('open-dialog');

    expect(first.revision, 1);
    expect(second.revision, 2);
    expect(first, isNot(second));
  });
}

class _EffectFactory with UiEffectFactory {}
