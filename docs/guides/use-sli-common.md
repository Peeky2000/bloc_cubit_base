# Dùng `sli_common`

App consume `sli_common` qua Git submodule tại `lib/modules/sli_common` và path
dependency trong `pubspec.yaml`.

Trước khi tạo widget, mở
[`sli_common/README.md`](../../lib/modules/sli_common/README.md) để xem quick
gallery, sau đó tra
[`docs/catalog`](../../lib/modules/sli_common/docs/catalog/README.md) theo nhu
cầu và maturity status. Catalog trả lời tên API, hình dạng, cách dùng, source và
test; không cần đoán theo tên file.

## Consume

```dart
import 'package:sli_common/sli_common.dart';

SliButton(
  label: 'Save',
  onPressed: onSave,
)
```

Ưu tiên component và token semantic `Sli*`. Import symbol chọn lọc bằng `show`
khi điều đó làm dependency rõ hơn. Không import `lib/src/...` hoặc dùng API
`shadcn_flutter` trực tiếp trong màn hình app.

## Contribute

Chỉ tạo shared abstraction khi nó tái sử dụng được qua nhiều sản phẩm. Làm việc
và verify trong repo độc lập `sli_common` trước:

```bash
cd lib/modules/sli_common
flutter analyze lib/src test example/lib
flutter test
```

Commit và push thay đổi package, rồi quay lại base và commit submodule pointer
mới. Ghi breaking change và migration trong CHANGELOG/docs của toolkit.

Product-specific copy, routes, Cubits/BLoCs, APIs, và business behavior vẫn nằm
trong application ngay cả khi UI được compose từ shared component.

## Migration widget legacy

Không migrate widget trong `lib/core/widget` chỉ vì trùng tên với export của
`sli_common`. Thứ tự bắt buộc:

1. inventory caller và behavior của app;
2. đọc maturity/contract trong catalog;
3. lập compatibility matrix giữa app, legacy shared và nguồn tham khảo;
4. thêm story/test/preview cho stable replacement;
5. adapter + `@Deprecated`, rồi migrate caller theo component family.

BottomSheet đang là pilot: `BottomSheetWidget` của package vẫn ở trạng thái
legacy/candidate và chưa được coi là replacement tự động cho bản app.
