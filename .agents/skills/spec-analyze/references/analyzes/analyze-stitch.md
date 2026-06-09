# Analyze with Stitch Project

Use this flow when the requester provides a **Stitch Screen ID**.

## Flow

1. **Resolve project and screen**
   - Extract the **Stitch Project ID** from `docs/prerequisites.md`.
   - Use the **screen ID** provided by the requester.

2. **Call get_screen**
   - MCP server of Stitch.
   - Tool: `get_screen` (or equivalent) with:
     - `name`: `projects/{project_id}/screens/{screen_id}`
     - `projectId`: the extracted project ID
     - `screenId`: the provided screen ID

3. **From the response**
   - **Screenshot:** use `screenshot.downloadUrl` — fetch the image from that URL and analyze it (same flow as [analyze-screenshot.md](analyze-screenshot.md): layout, UI elements, states). **Do not save yet.**
   - **HTML:** use `htmlCode.downloadUrl` to fetch the HTML, or read `htmlCode.fileContentBase64` if no download URL — analyze as **design reference** (exact CSS values, layout, colors, typography, structure). **Do not save yet.**

4. **Keep in memory for Step 5**
   - Store both download URLs (or inline content) so that in **Step 5.2** you can save:
     - Screen image → `{spec-dir}/references/screen.png`
     - HTML content → `{spec-dir}/references/screen.html`
   - Saving happens only after the spec folder is created by the script (Step 5.1).

5. **Output for main workflow**
   - Design understanding (from screenshot + HTML analysis) for Step 3 and fe.md.
   - URLs/content for saving in Step 5.2 after folder exists.

### Output for naming (Step 4.5)

- **Description:** Normalize the **screen title** from the Stitch response to English (e.g. "Danh sách Giao dịch (Sáng)" → "Transaction list (Light)" or "Transaction list, light mode"). Optionally add a one-line summary from screenshot/HTML analysis.
- **Keywords:** From the title and analysis: entity (transaction, budget, etc.), screen type (list, form, dashboard), and theme (light, dark, pink) if present in title or design.
- Pass these to the naming script — see [spec-naming-guide.md](spec-naming-guide.md).
