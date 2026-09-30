import 'package:equatable/equatable.dart';

final class UiEffect<T> extends Equatable {
  const UiEffect({required this.revision, required this.value});

  final int revision;
  final T value;

  @override
  List<Object?> get props => [revision];
}

mixin UiEffectFactory {
  int _effectRevision = 0;

  UiEffect<T> createEffect<T>(T value) {
    return UiEffect<T>(revision: ++_effectRevision, value: value);
  }
}
