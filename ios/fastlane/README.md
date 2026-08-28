Tài liệu fastlane
----

# Cài đặt

Đảm bảo máy đã cài phiên bản mới nhất của Xcode command line tools:

```sh
xcode-select --install
```

Hướng dẫn cài _fastlane_: [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Actions có sẵn

## iOS

### ios build_dev_debug

```sh
[bundle exec] fastlane ios build_dev_debug
```

Biên dịch với environment=dev và flavor=debug.

### ios build_prod_release

```sh
[bundle exec] fastlane ios build_prod_release
```

Biên dịch với environment=prod và flavor=release.

### ios reset

```sh
[bundle exec] fastlane ios reset
```

Biên dịch và upload iOS store.

### ios build_store

```sh
[bundle exec] fastlane ios build_store
```

Biên dịch và upload iOS store.

----

README.md này được auto-generate và sẽ được sinh lại mỗi khi chạy
[_fastlane_](https://fastlane.tools).

Thông tin thêm về _fastlane_ có tại [fastlane.tools](https://fastlane.tools).

Tài liệu _fastlane_ có tại [docs.fastlane.tools](https://docs.fastlane.tools).
