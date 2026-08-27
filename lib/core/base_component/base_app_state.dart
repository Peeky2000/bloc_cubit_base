import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:equatable/equatable.dart';

class BaseAppState extends Equatable {
  const BaseAppState({required this.loading, this.error});

  final LoadingStatus loading;
  final Object? error;

  @override
  List<Object?> get props => [loading, error];
}
