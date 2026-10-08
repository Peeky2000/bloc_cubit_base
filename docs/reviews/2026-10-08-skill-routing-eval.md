# Eval định tuyến skill (2026-10-08)

- Ngày: 2026-10-08
- Phạm vi: 24 skill trong `.agents/skills/`. Chỉ đo việc agent chọn skill từ
  `name` và `description`. Không đo chất lượng việc skill làm.
- Bộ eval: [`.agents/skills/evals/routing.json`](../../.agents/skills/evals/routing.json),
  90 câu. Cách chạy lại ở [README của eval](../../.agents/skills/evals/README.md).
- Thay đổi: chỉ sửa trường `description:` của 11 skill. Không sửa thân skill,
  không sửa `skill-creator`.

## Kết luận ngắn

- Trước khi sửa, agent gần như luôn chọn đúng skill chính (100% với model lớn).
  Lỗi nằm ở chỗ nạp **thêm** skill không cần, hoặc **thiếu** skill thứ hai.
- Sau khi sửa: 4/5 judge đúng 78/78 câu. Judge nhỏ nhất (Haiku) đúng 76/78.
- Bộ 12 câu giữ lại (holdout) lên từ 75–92% lên 100% ở cả 4 judge.
- Còn hai điểm yếu nhỏ, ghi ở cuối.

## 1. Kiểm tra frontmatter

`quick_validate.py` của `skill-creator` không chạy được. Python thiếu
`PyYAML` (`ModuleNotFoundError: No module named 'yaml'`), cả bản Homebrew lẫn
`/usr/bin/python3`. Tôi không cài thêm package.

Tôi kiểm tra tương đương bằng Ruby `YAML.safe_load`, với đúng các luật của
script: key được phép, `name` dạng kebab-case và trùng tên thư mục,
`description` có nội dung, không có `<` hoặc `>`, dài tối đa 1024 ký tự.

| Lần | Kết quả |
|---|---|
| Trước khi sửa | 24/24 skill hợp lệ. Dài nhất: `brainstorm` 789 ký tự. |
| Sau khi sửa | 24/24 skill hợp lệ. Dài nhất vẫn là `brainstorm` 789; skill đã sửa dài nhất là `flutter-atomic-design` 769. |

Một lỗi cấu trúc không thuộc skill nào:

- `.agents/skills/skills` là symlink tới `../.agents/skills`. Đích này không
  tồn tại, nên link bị hỏng. Link có từ commit `ad76805` (2026-06-09). Tôi
  không sửa vì nằm ngoài phạm vi. Nên xoá link này, hoặc sửa đích nếu có
  công cụ cần nó.

## 2. Cách đo

- 78 câu dùng để tinh chỉnh, cộng 12 câu `holdout-` viết sau khi đã thấy lỗi
  vòng đầu. Holdout dùng để xem bản sửa có tổng quát không, không bị "học
  thuộc" bộ đề.
- Câu hỏi viết theo cách PM/PO và dev trong repo hay nói: tiếng Việt, tiếng
  Anh, hoặc trộn. Mỗi skill có ít nhất 2 câu nên kích hoạt. Có 27 câu
  near-miss: trùng từ khoá với skill khác nhưng thuộc skill này. Có 3 câu
  không cần skill nào.
- Judge là subagent mới, chỉ được đọc một file prompt. File có danh sách
  name + description và các câu hỏi đã xáo thứ tự. Judge không thấy đáp án,
  không thấy thân skill, không thấy repo.
- Mỗi lần đo dùng 5 judge cho bộ 78 câu: 3 Opus, 1 Sonnet, 1 Haiku. Bộ
  holdout dùng 4 judge (2 Opus, Sonnet, Haiku) trước khi sửa.
- "Đúng hoàn toàn" nghĩa là tập skill judge chọn trùng khớp đáp án. "Đúng
  skill chính" nghĩa là skill đầu tiên judge chọn nằm trong đáp án.
- Lần chạy thử đầu tiên với 72 câu cho kết quả gần như hoàn hảo. Vì vậy tôi
  thêm 6 câu near-miss khó hơn trước khi đo baseline chính thức. Kết quả lần
  thử đó không tính vào bảng dưới.

## 3. Kết quả trước và sau

### Bộ 78 câu

| Judge | Trước: đúng hoàn toàn | Sau: đúng hoàn toàn | Trước: đúng skill chính | Sau: đúng skill chính |
|---|---|---|---|---|
| Opus A | 74/78 (94,9%) | 78/78 (100%) | 78/78 | 78/78 |
| Opus B | 73/78 (93,6%) | 78/78 (100%) | 78/78 | 78/78 |
| Opus C | 71/78 (91,0%) | 78/78 (100%) | 78/78 | 78/78 |
| Sonnet | 75/78 (96,2%) | 78/78 (100%) | 78/78 | 78/78 |
| Haiku | 73/78 (93,6%) | 76/78 (97,4%) | 75/78 | 78/78 |
| **Tổng 5 judge** | **366/390 (93,8%)** | **388/390 (99,5%)** | 387/390 | 390/390 |

### Bộ 12 câu holdout

| Judge | Trước | Sau |
|---|---|---|
| Opus A | 11/12 | 12/12 |
| Opus B | 11/12 | 12/12 |
| Sonnet | 11/12 | 12/12 |
| Haiku | 9/12 | 12/12 |

Sau vòng sửa thứ hai, tôi chạy lại holdout với 1 Opus và 1 Haiku: vẫn 12/12.

### Precision và recall theo skill (bộ 78 câu, cộng 5 judge)

Chỉ liệt kê skill có thay đổi. Các skill còn lại đều 100%/100% cả trước và sau.

| Skill | Precision trước → sau | Recall trước → sau |
|---|---|---|
| flutter-datasource | 62% → 100% | 100% → 100% |
| flutter-atomic-design | 75% → 100% | 75% → 95% |
| flutter-error-handling | 94% → 100% | 100% → 100% |
| project-convention | 91% → 100% | 100% → 100% |
| spec-analyze | 95% → 100% | 100% → 100% |
| mobile-security-privacy | 97% → 100% | 100% → 100% |
| flutter-model-entity | 100% → 100% | 95% → 100% |
| tech-design | 100% → 100% | 93% → 100% |
| flutter-code-review | 100% → 100% | 93% → 93% |

### Các lỗi trước khi sửa (bộ 78 câu)

| Câu | Đáp án | Judge chọn sai | Số judge sai |
|---|---|---|---|
| multi-test-atomic-01 (test BottomSheet dùng chung) | testing + atomic-design | chỉ testing | 5/5 |
| repo-02 (AuthRepoImpl tự lưu session) | repository | repository + datasource | 4/5 |
| brainstorm-02 (tách sli_common) | brainstorm | brainstorm + atomic-design | 3/5 |
| repo-01 (OrderRepo gộp remote và cache) | repository | repository + datasource | 3/5 |
| near-l10n-vs-atomic-01 (nút "Thử lại" hardcode) | translations | translations + atomic-design | 2/5 |
| near-repo-vs-datasource-01 (repo gọi thẳng Dio?) | repository | repository + datasource | 2/5 |
| multi-review-security-01 (review diff refresh token) | code-review + security | chỉ security | 1/5 |
| near-datasource-vs-security-01 (lưu refresh token) | datasource | datasource + security | 1/5 |
| near-l10n-vs-error-01 (message code theo ngôn ngữ) | translations | error-handling + translations | 1/5 |
| near-model-vs-convention-01 (entity có fromJson?) | model-entity | project-convention | 1/5 |
| near-tech-vs-spec-01 (PO gửi docx, triển khai luôn) | tech-design | spec-analyze | 1/5 |

Holdout trước khi sửa: `holdout-test-atomic-01` sai 4/4 (thiếu atomic-design),
`holdout-datasource-02` sai 1/4 (thêm bloc-cubit), `holdout-repo-02` sai 1/4
(chọn brainstorm).

## 4. Description đã sửa và lý do

Mọi bản sửa giữ kiểu folded `>` của file gốc. Riêng `spec-analyze` vốn dùng
chuỗi trong dấu nháy đơn, nên tôi chỉ thêm một câu vào cuối chuỗi.

| Skill | Độ dài trước → sau | Lý do |
|---|---|---|
| flutter-datasource | 217 → 739 | Từ khoá "remote", "local storage", "token" quá rộng. Agent nạp datasource cho mọi việc về repository (9 lần thừa). Bản mới nói rõ: thêm endpoint, chọn nơi lưu, lưu token sau login. Thêm "Not for": repo gộp remote/local (dùng flutter-repository), audit lưu token (dùng mobile-security-privacy). Thêm cụm tiếng Việt: "gọi API", "lưu xuống máy". |
| flutter-repository | 133 → 611 | Mô tả cũ chỉ có 3 từ khoá. Bản mới nói repo gộp remote + local, offline fallback, phân chia trách nhiệm (session thuộc SessionRepo), repo không gọi thẳng Dio. Chỉ nạp thêm datasource khi chính data source phải đổi. |
| flutter-atomic-design | 209 → 769 | Lỗi cả hai chiều. Thiếu khi test widget dùng chung, thừa khi brainstorm về sli_common hoặc dịch text. Bản mới nói nạp cùng flutter-testing khi test nhắm vào widget dùng chung hoặc `Sli*`. Thêm "Not for": chuyển text sang ARB, brainstorm kiến trúc package, jank. |
| flutter-translations | 147 → 658 | Thêm trường hợp: text hardcode trong widget dùng chung hoặc trong thông báo lỗi, thêm bản tiếng Anh, server code thành câu theo ngôn ngữ. Thêm cụm "đa ngôn ngữ", "hardcode text". Thêm "Not for": vị trí widget, luồng lỗi qua các layer. |
| flutter-error-handling | 197 → 545 | Từ "error" kéo nó vào câu chỉ hỏi về câu chữ của lỗi. Bản mới nói rõ phạm vi (layer nào bắt lỗi, màn hình hiện gì, retry, 401) và "Not for": câu chữ hoặc bản dịch của lỗi. |
| flutter-model-entity | 172 → 492 | Câu "entity có được viết fromJson không" bị đẩy sang project-convention. Bản mới có câu hỏi kiểu "entity được chứa gì" và câu "ưu tiên skill này hơn project-convention cho luật về entity và model". |
| project-convention | 215 → 617 | Mô tả cũ liệt kê cả DI, Cubit/BLoC nên giành việc của skill layer. Bản mới giữ vai trò luật chung (import, đặt tên, dependency flow) và chỉ ra skill layer cho luật trong một layer. |
| tech-design | 445 → 616 | Câu "PO gửi tài liệu, triển khai luôn" bị đẩy sang spec-analyze. Thêm cụm "làm luôn", "triển khai", "implement" khi có tài liệu PO/PM. Thêm "Not for": fe.md (spec-analyze), chia task sau khi tech.md đã duyệt (plan-writer). |
| spec-analyze | 618 → 691 | Thêm một câu: không dùng để biến PRD thành code hay thiết kế kỹ thuật (dùng tech-design). |
| flutter-code-review | 316 → 544 | Có judge bỏ code-review khi review diff đụng token. Bản mới nói: review chung một diff đụng auth/token/PII/log/deep link thì nạp thêm mobile-security-privacy. Vòng 1 làm judge nạp code-review cả cho câu chỉ hỏi bảo mật, nên vòng 2 thêm "Not for": kiểm tra chỉ về bảo mật. |
| mobile-security-privacy | 326 → 683 | Phân biệt ba trường hợp. Kiểm tra chỉ về bảo mật: chỉ skill này. Review PR chung: đi kèm code-review. Code data layer lưu token bình thường: thuộc flutter-datasource. |

Vòng 1 sửa 11 skill. Kết quả: 77/78 với Opus, 78/78 với Sonnet. Lỗi mới là
câu `near-security-vs-review-02` ("PR này có lộ token, API key không"). Opus
nạp thêm code-review vì câu mới trong description. Vòng 2 chỉ sửa lại câu đó
trong `flutter-code-review` và `mobile-security-privacy`.

Không sửa 13 skill còn lại. Chúng đạt 100% precision và recall ở mọi judge.

## 5. Điểm yếu còn lại

- **Haiku vẫn bỏ skill thứ hai.** Sau sửa, Haiku sai 2/78: chỉ chọn
  flutter-testing cho test BottomSheet dùng chung, và chỉ chọn security cho
  review diff refresh token. Model nhỏ hay chọn một skill. Nếu agent thật
  dùng model nhỏ, nên thêm luật ghép skill vào agent (`flutter-tester`,
  `reviewer`) thay vì kéo dài description.
- **Description dài hơn.** Tổng độ dài 11 skill đã sửa tăng từ 2.995 lên
  6.965 ký tự. Mọi skill vẫn dưới 1024. Khi thêm skill mới, giữ cùng mẫu:
  làm gì, khi nào dùng, cụm từ người dùng gõ, "Not for X (use Y)".
- **Bộ eval còn nhỏ.** 2–5 câu mỗi skill. Một câu sai đổi recall 20–50%.
  Nên thêm câu thật từ lịch sử chat khi có.
- **Judge không phải agent thật.** Judge thấy danh sách skill dạng văn bản và
  được dặn chỉ nạp skill thứ hai khi thật cần. Agent thật có thể nạp skill
  qua frontmatter `skills:` của file agent, hoặc theo luật trong `AGENTS.md`.
  Kết quả ở đây là cận trên cho việc tự chọn skill.
- **Một số câu có thể tranh cãi.** Ví dụ `repo-01` (viết OrderRepo gộp remote
  và cache) có thể cần cả datasource nếu data source chưa có. Đáp án hiện tại
  giả định data source đã có. Khi review, nên đọc lại `expected` của các câu
  near-miss.
- **Symlink hỏng** `.agents/skills/skills` vẫn còn (xem mục 1).
- **`quick_validate.py` vẫn không chạy** khi thiếu PyYAML. Muốn dùng nó trong
  CI thì cần cài PyYAML, hoặc dùng bước kiểm tra Ruby.

## 6. Bằng chứng và giới hạn

- Câu trả lời thô của judge, prompt và answer key nằm ở `/tmp/sre/`, không
  commit vào repo. README của eval có lệnh tạo lại prompt và chấm điểm.
- Không chạy `derry quality`. Thay đổi chỉ nằm trong frontmatter skill và
  file tài liệu, không đụng `lib/`, `test/`, `tool/`.
- Không chạy git add, commit, stash hay checkout.
