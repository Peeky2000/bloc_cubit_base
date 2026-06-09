# AI Process — Flutter Base

Quy trình chuẩn khi dùng repo này làm **Flutter base template** (Clean Architecture + agents/skills).

**Đọc trước:** [docs/prerequisites.md](docs/prerequisites.md) · [project-convention](.agents/skills/project-convention/SKILL.md)

---

## Kiến trúc

```
presentation/{feature}/cubit + view
        ↓
domain/use_case + repositories + entities
        ↓
data/repositories + datasource + model
        ↓
core (routing, error, widget, app)
```

| Thành phần | Công nghệ |
|------------|-----------|
| State | `BaseCubit`, `BaseAppState`, `LoadingStatus` |
| DI | `get_it` — `lib/di/injection.dart` |
| HTTP | Dio — `ApiHandler` |
| Route | `SLIRouting`, `AppPage` |
| i18n | `lib/l10n/arb/` |

---

## Workflow

```
[1] Brainstorm / Spec (AI)
[2] User review & Q&A ✋  ⛔ GATE: hết open questions
[3] Plan (AI)
[4] User duyệt plan ✋
[5] Code (coder)
[6] AI review → FAIL → lặp [5]
[7] Self test ✋
```

### Artifacts

| Bước | Output |
|------|--------|
| Brainstorm | `docs/brainstorm/YYYY-MM-DD-{topic}.md` |
| Spec | `docs/specs/{NNN}-{name}/fe.md` |
| Checklists | `docs/specs/.../checklists/` |
| Plan | `docs/plan/YYYY-MM-DD-{topic}.md` |
| Review | `docs/reviews/YYYY-MM-DD-hh-mm-ss-{topic}.md` |

---

## Layer order (coder)

```
Entity → Model → DataSource → Repo (if + impl) → UseCase → Cubit → Screen → Route → ARB → DI
```

Paths: [canonical-paths.md](.agents/skills/project-convention/references/canonical-paths.md)

**Quality gate:**
```bash
dart format lib/ --set-exit-if-changed
flutter analyze
dart run build_runner build --delete-conflicting-outputs   # khi đổi JSON models
```

**Tìm code có sẵn:**
```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "<keyword>"
```

---

## Agents

| Agent | File |
|-------|------|
| PM | `.agents/agents/pm.md` |
| Coder | `.agents/agents/coder.md` |
| Reviewer | `.agents/agents/reviewer.md` |
| Quick task | `.agents/agents/flutter-engineer.md` |

**Lệnh mẫu:**
```
@.agents/agents/pm.md Lập plan từ docs/specs/001-login/fe.md
@.agents/agents/coder.md Implement docs/plan/2026-06-01-login.md
@.agents/agents/reviewer.md Review feature login
```

---

## Fork base sang dự án mới

1. Đổi `name:` trong `pubspec.yaml` → chạy replace `package:<old>/` trong `lib/`.
2. Cập nhật `docs/prerequisites.md` (mô tả app, features).
3. Xóa nội dung mẫu trong `docs/brainstorm`, `docs/specs`, `docs/plan` nếu không cần.
4. Reset / cập nhật `.agents/memories/*.json` cho codebase mới.

---

## Lưu ý

- Plan chưa duyệt → không giao coder.
- Task nhỏ → `flutter-engineer`, vẫn tuân convention.
- **Không** dùng layout `lib/features/`, `lib/shared/` từ template cũ.
