#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

# Dùng đúng Dart của Flutter đã ghim trong .fvmrc, không dùng `dart` trên PATH.
dart_cmd=(dart)
if command -v fvm >/dev/null 2>&1; then
  dart_cmd=(fvm dart)
fi

"${dart_cmd[@]}" run build_runner build

# flutter_gen_runner >=5.14 ghi file qua bước post-process. Cache build cũ trong
# .dart_tool có thể khiến build_runner xoá các file này mà không sinh lại.
# Khi thiếu file, xoá cache rồi build lại một lần.
expected_outputs=(lib/generated/assets.gen.dart lib/generated/fonts.gen.dart)
for output in "${expected_outputs[@]}"; do
  if [[ ! -f "$output" ]]; then
    echo "Thiếu $output sau khi build; chạy build_runner clean rồi build lại." >&2
    "${dart_cmd[@]}" run build_runner clean
    "${dart_cmd[@]}" run build_runner build
    break
  fi
done

for output in "${expected_outputs[@]}"; do
  if [[ ! -f "$output" ]]; then
    echo "Vẫn thiếu $output sau khi build lại." >&2
    exit 1
  fi
done
./scripts/format.sh
