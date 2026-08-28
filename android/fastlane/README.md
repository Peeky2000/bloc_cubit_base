Tài liệu fastlane
----

# Cài đặt

Đảm bảo máy đã cài phiên bản mới nhất của Xcode command line tools:

```sh
xcode-select --install
```

Hướng dẫn cài _fastlane_: [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Actions có sẵn

## Android

### android build_dev_debug

```sh
[bundle exec] fastlane android build_dev_debug
```

Biên dịch với environment=dev và flavor=debug.

### android build_prod_release

```sh
[bundle exec] fastlane android build_prod_release
```

Biên dịch với environment=prod và flavor=release.

### android build_store

```sh
[bundle exec] fastlane android build_store
```

Biên dịch và upload Android store.

----

README.md này được auto-generate và sẽ được sinh lại mỗi khi chạy
[_fastlane_](https://fastlane.tools).

Thông tin thêm về _fastlane_ có tại [fastlane.tools](https://fastlane.tools).

Tài liệu _fastlane_ có tại [docs.fastlane.tools](https://docs.fastlane.tools).
