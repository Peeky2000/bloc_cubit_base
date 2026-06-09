# Analyze with Figma

Use this flow when the requester provides a **Figma link**.

## Flow

1. **Read / analyze the Figma link**
   - Prefer Figma MCP if available; otherwise use requester description or exported assets.
   - Extract: layout, frames, components, typography, colors, spacing, and any design tokens or variants.

2. **If read fails** (access, permission, or format error):
   - Notify requester: *"Unable to read Figma link (access / permission / format error). Please check the link or provide a screenshot / description instead."*
   - **Stop** — do not proceed with spec generation.

3. **Output for main workflow**
   - Design understanding (layout, UI elements, states, style) to feed into Step 3 (Load skills and analyze) and later into fe.md (design inputs, section 3.1 Design element analysis).

### Output for naming (Step 4.5)

- **Description:** Normalize the **frame or page name** from Figma to English, kebab-case (e.g. "Login - Light" → "Login Light", "Transaction List" → "Transaction List").
- **Keywords:** From context: `screen` if the frame is a full screen/page, `component` if it is a component/symbol; add theme if present: `light`, `dark`, `pink`.
- Pass these to the naming script — see [spec-naming-guide.md](spec-naming-guide.md).
