# AI Agents — Flutter Base Template

## Start

1. [ai-process.md](ai-process.md)
2. [docs/prerequisites.md](docs/prerequisites.md)
3. [.agents/skills/project-convention/SKILL.md](.agents/skills/project-convention/SKILL.md)

## Agents

| Agent | Invoke |
|-------|--------|
| PM | `@.agents/agents/pm.md` |
| Coder | `@.agents/agents/coder.md` |
| Reviewer | `@.agents/agents/reviewer.md` |
| Quick fix | `@.agents/agents/flutter-engineer.md` |

```bash
python3 .agents/skills/app-memory/scripts/mem_search.py "auth"
```

## Layer order

Entity → Model → DataSource → Repository → UseCase → Cubit → Screen → Route → l10n → DI
