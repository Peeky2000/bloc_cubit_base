# Chọn Cubit Hay BLoC

Dùng state machine nhỏ nhất nhưng vẫn làm hành vi đủ tường minh.

| Tín hiệu | Cubit | BLoC cổ điển |
|---|---:|---:|
| Method cho button/form và async flow tuyến tính | ✓ | |
| Một vài command từ một màn hình | ✓ | |
| Named event từ nhiều producer | | ✓ |
| Debounce, restartable, droppable, sequential semantics | | ✓ |
| Audit/replay vocabulary quan trọng | | ✓ |
| Màn hình CRUD đơn giản | ✓ | |

Cả hai đều extend base primitive, nhận UseCase qua constructor, emit state
Equatable immutable, và độc lập với BuildContext/navigation.

Không chọn BLoC chỉ vì trông “enterprise” hơn, và không ép dùng Cubit khi event
concurrent sẽ buộc phải dùng flag mong manh. Ghi lý do trong feature spec hoặc
comment ngắn trong code khi lựa chọn không hiển nhiên.
