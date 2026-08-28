# ADR 0003: Giữ State Ứng Dụng Bằng Equatable

- Trạng thái: Accepted
- Ngày: 2026-08-26

## Quyết định

Giữ `BaseAppState` immutable, Equatable, và `copyWith` thủ công. Không migrate
state mặc định sang Freezed hoặc HydratedBloc.

## Hệ quả

State vẫn tường minh và ít phụ thuộc generator. Review và test phải đảm bảo
field immutable, `props` đầy đủ, và hành vi `copyWith` với nullable field không
mơ hồ.
