# ADR 0005: Giữ SLIRouting

- Trạng thái: Accepted
- Ngày: 2026-08-26

## Quyết định

Giữ stack navigation hiện có gồm `SLIRouting`, `AppPage`, và `SLIPage` trong
đợt modernization này.

## Hệ quả

Việc migrate navigation không bị trộn vào cleanup kiến trúc. State manager vẫn
không được navigate trực tiếp; presentation nhận effect tường minh và gọi
routing.
