import 'package:bloc_cubit_base/core/base_component/base_app_state.dart';
import 'package:bloc_cubit_base/core/base_component/base_bloc.dart';
import 'package:bloc_cubit_base/core/base_component/base_cubit.dart';
import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('representative state starts immutable and typed', () async {
    final cubit = _LifecycleCubit();
    final bloc = _LifecycleBloc();
    expect(cubit.state, _LifecycleState.initial());
    expect(bloc.state, _LifecycleState.initial());
    await cubit.close();
    await bloc.close();
  });

  group('BaseCubit contract', () {
    blocTest<_LifecycleCubit, _LifecycleState>(
      'covers initial, loading and success with typed state',
      build: _LifecycleCubit.new,
      act: (cubit) => cubit.execute(),
      expect: () => [
        _LifecycleState.initial().copyWith(loading: LoadingStatus.loading),
        _LifecycleState.initial().copyWith(
          loading: LoadingStatus.complete,
          value: 1,
        ),
      ],
    );

    blocTest<_LifecycleCubit, _LifecycleState>(
      'publishes a typed failure',
      build: _LifecycleCubit.new,
      act: (cubit) => cubit.execute(shouldFail: true),
      expect: () => [
        _LifecycleState.initial().copyWith(loading: LoadingStatus.loading),
        _LifecycleState.initial().copyWith(
          loading: LoadingStatus.error,
          error: _LifecycleFailure.rejected,
        ),
      ],
    );
  });

  group('BaseBloc contract', () {
    blocTest<_LifecycleBloc, _LifecycleState>(
      'covers initial, loading and success for named events',
      build: _LifecycleBloc.new,
      act: (bloc) => bloc.add(const _ExecuteRequested()),
      expect: () => [
        _LifecycleState.initial().copyWith(loading: LoadingStatus.loading),
        _LifecycleState.initial().copyWith(
          loading: LoadingStatus.complete,
          value: 1,
        ),
      ],
    );

    blocTest<_LifecycleBloc, _LifecycleState>(
      'publishes a typed failure for a named event',
      build: _LifecycleBloc.new,
      act: (bloc) => bloc.add(const _ExecuteRequested(shouldFail: true)),
      expect: () => [
        _LifecycleState.initial().copyWith(loading: LoadingStatus.loading),
        _LifecycleState.initial().copyWith(
          loading: LoadingStatus.error,
          error: _LifecycleFailure.rejected,
        ),
      ],
    );
  });
}

enum _LifecycleFailure { rejected }

class _LifecycleState extends BaseAppState<_LifecycleFailure> {
  const _LifecycleState({required super.loading, super.error, this.value = 0});

  final int value;

  factory _LifecycleState.initial() {
    return const _LifecycleState(loading: LoadingStatus.initial);
  }

  _LifecycleState copyWith({
    LoadingStatus? loading,
    _LifecycleFailure? error,
    int? value,
  }) {
    return _LifecycleState(
      loading: loading ?? this.loading,
      error: error,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [...super.props, value];
}

class _LifecycleCubit extends BaseCubit<_LifecycleState> {
  _LifecycleCubit() : super(_LifecycleState.initial());

  Future<void> execute({bool shouldFail = false}) async {
    emit(state.copyWith(loading: LoadingStatus.loading));
    if (shouldFail) {
      emit(
        state.copyWith(
          loading: LoadingStatus.error,
          error: _LifecycleFailure.rejected,
        ),
      );
      return;
    }
    emit(state.copyWith(loading: LoadingStatus.complete, value: 1));
  }
}

sealed class _LifecycleEvent {
  const _LifecycleEvent();
}

final class _ExecuteRequested extends _LifecycleEvent {
  const _ExecuteRequested({this.shouldFail = false});

  final bool shouldFail;
}

class _LifecycleBloc extends BaseBloc<_LifecycleEvent, _LifecycleState> {
  _LifecycleBloc() : super(_LifecycleState.initial()) {
    on<_ExecuteRequested>((event, emit) {
      emit(state.copyWith(loading: LoadingStatus.loading));
      if (event.shouldFail) {
        emit(
          state.copyWith(
            loading: LoadingStatus.error,
            error: _LifecycleFailure.rejected,
          ),
        );
        return;
      }
      emit(state.copyWith(loading: LoadingStatus.complete, value: 1));
    });
  }
}
