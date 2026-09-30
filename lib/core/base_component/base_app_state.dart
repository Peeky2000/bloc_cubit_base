import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:equatable/equatable.dart';

class BaseAppState<Failure extends Object> extends Equatable {
  const BaseAppState({required this.loading, this.error});

  final LoadingStatus loading;
  final Failure? error;

  @override
  List<Object?> get props => [loading, error];
}
