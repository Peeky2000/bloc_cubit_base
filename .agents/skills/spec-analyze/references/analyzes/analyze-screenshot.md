# Analyze with Screenshot

Use this flow when the requester provides a **screenshot** (attached image or file path).

## Flow

1. **Read and analyze the screenshot**
   - If path is given: load the image from that path.
   - If attached: use the provided image.
   - Identify: layout structure, UI elements, hierarchy, states (default, hover, error if visible), and any text/copy visible.

2. **Extract for spec**
   - Layout blocks and nesting.
   - Components (buttons, inputs, cards, tables, etc.).
   - Typography (sizes, weights), colors, spacing (padding, margin, gap), border-radius, shadows where visible.

3. **Output for main workflow**
   - Design understanding to feed into Step 3 (Load skills and analyze) and into fe.md (design inputs, section 3.1 Design element analysis). No assets to save later unless Stitch is also provided.

### Output for naming (Step 4.5)

- **Description:** One short sentence summarizing the screen (e.g. "Transaction list screen with summary cards and FAB, light background").
- **Keywords:** From analysis: layout type (`list`, `form`, `dashboard`, `detail`, `settings`), main entity (`transaction`, `budget`, `profile`, `login`, `report`), and theme if visible (`light`, `dark`, `pink`). Default spec type: screen.
- Pass these to the naming script — see [spec-naming-guide.md](spec-naming-guide.md).
