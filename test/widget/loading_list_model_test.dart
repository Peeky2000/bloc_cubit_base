import 'package:bloc_cubit_base/core/common/enum.dart';
import 'package:bloc_cubit_base/widget/loading_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadingListModel', () {
    test('append returns a new immutable value', () {
      final original = LoadingListModel<int>(data: const [1]);

      final updated = original.addData(2);

      expect(original.data, const [1]);
      expect(updated.data, const [1, 2]);
      expect(() => updated.data.add(3), throwsUnsupportedError);
    });

    test('copyWithAddData preserves current data and loading status', () {
      final original = LoadingListModel<int>(data: const [1]);

      final updated = original.copyWithAddData(
        loading: LoadingStatus.complete,
        data: const [2, 3],
      );

      expect(updated.loading, LoadingStatus.complete);
      expect(updated.data, const [1, 2, 3]);
    });
  });
}
