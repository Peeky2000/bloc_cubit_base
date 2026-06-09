---
name: brainstorm
description: "Structured deep-thinking and problem analysis before proposing solutions. Use when: (1) user wants to think through a bug before fixing, (2) planning a new feature and needs to analyze requirements/edge cases/risks/alternatives, (3) considering a refactor and needs to evaluate scope/risk/approach, (4) designing architecture and needs to compare options, (5) diagnosing a performance problem, (6) assessing security concerns, (7) analyzing a UX problem. Trigger on: 'brainstorm', 'think through', 'analyze', 'phân tích', 'suy nghĩ', 'plan', 'deep dive', 'before we implement', 'what could go wrong', 'help me think about', 'let's think through'. Always trigger this skill when the user wants structured thinking before jumping to a solution — even if they don't use the word 'brainstorm'."
---

# Brainstorm

## Purpose

Guide deep, structured thinking before proposing a solution. The goal is to surface the right questions — not just the obvious ones — to uncover hidden assumptions, risks, and alternatives that would be missed by jumping straight to implementation.

Thinking deeply upfront is cheap. Discovering a wrong assumption mid-implementation is expensive.

---

## Workflow

### Step 1 — Identify Problem Type

Determine the type from context. If unclear, ask: *"Loại vấn đề bạn muốn phân tích là gì? (bug / feature / refactor / architecture / performance / security / ux / design-api)"*

| Type | When to use |
|------|-------------|
| **bug** | Unexpected behavior, crash, wrong output, regression |
| **feature** | New screen, new component, new behavior, new logic |
| **refactor** | Restructure code without changing external behavior |
| **architecture** | System design, data flow, module boundaries, tech decisions |
| **performance** | Slow UI, expensive queries, memory issues, startup time |
| **security** | Vulnerability, data exposure, auth/authz issue |
| **ux** | Confusing flow, accessibility gap, usability problem |
| **design-api** | Design REST API contract for a screen (Dio/ApiHandler style) — only if backend design is in scope; see `flutter-datasource` skill |

### Step 2 — Load Question Template

Load `references/{type}.md`. This file contains the structured question template for the identified type.

### Step 3 — Answer Every Question

Work through each question in the template:
- Answer based on available context (code, description, design)
- If an answer is unknown, state *what information would resolve it* — don't skip
- State assumptions explicitly where data is lacking
- Flag risks and uncertainties as they appear

Do not skip questions silently. If a question is genuinely irrelevant for this specific case, write one sentence explaining why, then move on.

### Step 4 — Synthesize

After answering all questions, write a synthesis:
- **Key insight** — the most important finding from the analysis
- **Recommended approach** — what to do and why (not how to code it)
- **Risks to watch** — top 2–3 risks to keep in mind during implementation
- **Open questions** — what still needs answering before you can commit to an approach

### Step 5 — Save to File (MANDATORY)

**Always** write the brainstorm document to `docs/brainstorm/YYYY-MM-DD-{topic}.md` before replying — no exceptions, even if the user did not ask. Use today's date and a short kebab-case topic slug derived from the problem title.

The document structure:

```
# Brainstorm: {problem title}

**Type:** {type}
**Date:** {today}

---

## Analysis

### {Question 1}
{Answer}

### {Question 2}
{Answer}

...

---

## Synthesis

### Key Insight
{...}

### Recommended Approach
{...}

### Risks to Watch
- ...

### Open Questions
- ...
```

### Step 6 — Reply with File Link

After saving, reply to the user with:
1. The file path as a clickable reference: `docs/brainstorm/YYYY-MM-DD-{topic}.md`
2. A concise summary of the **Key Insight** and **Recommended Approach** (3–5 sentences max)
3. The full brainstorm content inline so the user can read it without opening the file

---

## Question Templates — Quick Reference

Full templates with guidance are in `references/{type}.md`.

| Type | Core questions |
|------|----------------|
| **bug** | What happened vs expected? When/where? Root cause? What does the affected code depend on and what depends on it (dependency map)? Scope of impact? Fix risks? How to verify? |
| **feature** | What problem does this solve? Who benefits? What are the core use cases? Edge cases? Alternatives considered? Technical constraints? Risks? |
| **refactor** | Why now? What changes vs what stays? What depends on this code (dependency map)? Scope? Migration strategy? Risks? Expected improvement? |
| **architecture** | Problem statement? Constraints? Quality attributes? Alternative approaches? Trade-offs of each? Integration points? Risks? |
| **performance** | Where is the bottleneck (measured, not guessed)? What are the targets? Root cause? Solutions? Trade-offs? How to measure improvement? |
| **security** | Threat model? What data is at risk? Attack surface? Existing defenses? Vulnerabilities? Mitigations? Compliance requirements? |
| **ux** | Who are the users? What is the user goal? Current pain point? User flows affected? Accessibility? Edge cases for users? Consistency with design system? |
| **design-api** | Which screens/features in scope? What data to read/write? Which Oracle tables (NANDEMO000/001) back it? Endpoint shape per need (/sync, /lookup, /transactions, /ops)? Full contract per endpoint (method, auth, params, request/response JSON, field→column mapping, errors, idempotency, cache)? Actual SQL with bind vars? Middleware pipeline for writes? App-side impact (models/api/repo/DAO/bloc)? Risks & open mappings? |
