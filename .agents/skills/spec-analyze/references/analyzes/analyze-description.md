# Analyze with Description (and Documentation link)

Use this flow when the requester provides a **requirement description** and/or a **documentation link**.

## Flow

1. **Analyze the description**
   - Understand: feature name, screen(s), user flow, business rules, and acceptance expectations.
   - Identify: entities (components, APIs, routes, validators, utilities) implied by the text.

2. **If a documentation link is provided**
   - Read the documentation (fetch URL or follow requester instructions).
   - Extract: functional requirements, UI requirements, constraints, and any existing spec or PRD content.

3. **When only documentation + description** (no Figma / screenshot)
   - If concrete implementation (component, pattern, or tech choice) is needed, **research** in the relevant skill or codebase and suggest how to implement.
   - Use design-to-code and project conventions to infer structure where the design is not visual.

4. **Output for main workflow**
   - Requirements understanding to feed into Step 3 (Load skills and analyze) and into fe.md (design inputs, in scope/out of scope, acceptance criteria). No design assets to save.

### Output for naming (Step 4.5)

- **Description:** Short English summary of the requirement (e.g. "Add transaction form with category picker", "Fix login header alignment").
- **Keywords:** Parse **intent** and **subject** from the text:
  - Intent: "tạo mới màn hình" / "new screen" → `new-screen`; "tạo component" → `new-component`; "fix lỗi giao diện" / "fix design" → `fix-design`; "fix lỗi logic" / "fix bug" → `fix-logic`; "refactor" → `refactor`.
  - Subject: screen name, component name, or area (e.g. transaction, budget, login). Use `--type` when intent is clear.
- Pass these to the naming script — see [spec-naming-guide.md](spec-naming-guide.md).
