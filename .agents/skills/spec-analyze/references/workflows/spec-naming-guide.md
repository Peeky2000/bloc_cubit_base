# Spec Naming Guide

Use this guide when **choosing the spec folder name** (slug) in Step 4.5. The slug is passed to `create-spec-folder.py` and must be **kebab-case**, **unique** among existing `docs/specs/NNN-*` folders, and follow project conventions.

---

## 1. Spec types and slug examples

| Spec type        | Slug example                    | Keywords / hints                                      |
| -----------------|----------------------------------|--------------------------------------------------------|
| **New screen**   | `transaction-list-light`        | screen, màn hình, list, dashboard, form                 |
| **New component**| `transaction-summary-card`      | component, atom, molecule, organism                    |
| **New logic**    | `budget-calculation-rules`      | logic, calculation, validation, hook                   |
| **Fix design**   | `fix-design-login-header`       | fix design, fix UI, sửa giao diện                      |
| **Fix logic**    | `fix-logic-budget-total`        | fix bug, fix logic, sửa lỗi                            |
| **Refactor**     | `refactor-overview-nav`         | refactor, cải tiến, tách component                     |

---

## 2. Per input type: description source and keywords

Use the table below to know **what to extract** for naming, then pass it to the script (see section 4).

| Input type     | Description source                    | Keyword source                         | Notes                                      |
|----------------|----------------------------------------|----------------------------------------|--------------------------------------------|
| **Figma link** | Frame or page name from Figma          | screen / component; theme (light, dark, pink) | Normalize to English, kebab-case.          |
| **Screenshot** | One short sentence from image analysis | Layout (list, form, dashboard) + entity + theme | Default spec_type: screen.                  |
| **Stitch**     | Screen title from Stitch response      | Entity + screen type + theme from title/HTML | Normalize Vietnamese title to English.      |
| **Description**| Short summary of the requirement text  | Intent (new screen, fix, refactor) + subject | Parse intent and subject from text.        |

---

## 3. How to run the naming script

From **project root**:

```bash
python3 .agents/skills/spec-analyze/scripts/generate-spec-name.py \
  --description "<short English description>" \
  [--keywords "keyword1,keyword2"] \
  [--type new-screen|new-component|new-logic|fix-design|fix-logic|refactor]
```

**Examples:**

```bash
# New screen from Stitch title "Danh sách Giao dịch (Sáng)"
python3 .agents/skills/spec-analyze/scripts/generate-spec-name.py \
  --description "Transaction list screen, light mode" \
  --keywords "screen,list,transaction,light"

# Fix design
python3 .agents/skills/spec-analyze/scripts/generate-spec-name.py \
  --description "Login screen header alignment" \
  --type fix-design

# From description only
python3 .agents/skills/spec-analyze/scripts/generate-spec-name.py \
  --description "Add transaction form with category picker" \
  --keywords "screen,form,transaction"
```

**Output:** The script prints the **slug** (and optionally a **suggested title** for fe.md). Use the slug in Step 5.1: `python .agents/skills/spec-analyze/scripts/create-spec-folder.py <slug>`.

---

## 4. Conventions (used by the script)

- **Slug:** lowercase, letters and hyphens only; no spaces or special characters.
- **Prefix by intent:** `fix-design-*`, `fix-logic-*`, `refactor-*` when `--type` is set accordingly.
- **Theme suffix:** if keywords contain `light`, `dark`, or `pink`, the slug may end with `-light`, `-dark`, or `-pink`.
- **Uniqueness:** script checks existing `docs/specs/NNN-*` folders and, if the slug exists, suggests a variant (e.g. `-v2`) or reports conflict.
