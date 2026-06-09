import 'package:mOrder/core/common/enum.dart';

class BaseAppState {
  LoadingStatus loading;
  dynamic error;

  BaseAppState({required this.loading, this.error});
}
