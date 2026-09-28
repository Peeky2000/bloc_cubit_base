# ADR 0008: Skill Tập Trung Flutter/Mobile, Không Adopt VIPER

- Trạng thái: Accepted
- Ngày: 2026-09-28
- Supersedes một phần định hướng “hoãn VIPER/AI nâng cao” trong ADR-0006

## Bối cảnh

Base đã có agents/skills hỗ trợ tạo layer Clean Architecture và triển khai
feature. `aiworkshop-viper` từng được xem là nguồn tham khảo cho workflow AI
nâng cao, nhưng đưa thêm một process framework vào base sẽ làm tăng độ phức tạp
mà không cải thiện trực tiếp chất lượng Flutter runtime hoặc mobile delivery.

Khoảng trống thực tế cần giải quyết là năng lực engineering: source review,
performance profiling, testing, security/privacy, platform lifecycle,
accessibility và release readiness.

## Quyết định

- Không adopt framework VIPER, quy trình năm pha hoặc AI gate của
  `aiworkshop-viper` vào kiến trúc/runtime của base.
- Giữ `.agents` như bộ playbook hỗ trợ Flutter/mobile engineering, không phải
  một framework điều phối sản phẩm.
- `project-convention` tiếp tục là source of truth cho invariant của repo; các
  skill chuyên biệt sở hữu workflow có bằng chứng và cách verify rõ ràng.
- Skill quality phải evidence-first: code review ưu tiên correctness/race/
  security hơn style; performance phải đo trước và sau; test phải chọn đúng cấp.
- Skill vẫn có thể dùng kiến thức Flutter/mobile chung, đồng thời đọc convention
  của repo khi thực hiện thay đổi trong `bloc_cubit_base`.

## Hệ quả

- Roadmap tập trung vào Flutter base, `sli_common`, developer experience và
  mobile quality thay vì mở rộng thành AI process framework.
- Các skill mới được thêm dần theo giá trị: code review, performance, testing,
  security/privacy, lifecycle và release.
- `aiworkshop-viper` không còn là dependency hay future phase của base; chỉ có
  thể được đọc như tài liệu tham khảo ngoài source of truth.
- Version Health/Firebase Observability là capability mobile riêng và vẫn được
  hoãn tới sau khi core base đạt zero-debt.
