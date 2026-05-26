# Forge Memory — Index (Compiled Wiki TOC)

Karpathy compiler model: raw `tasks/*.md` (source) → AI compiler → these wiki files (executable).

<!-- last-compiled: never -->

## Topics (compiled output)
- `learnings.md` — General accumulated wisdom across sessions
- `patterns.md` — Code patterns, conventions, idioms worth remembering
- `gotchas.md` — Pitfalls, edge cases, things that don't work as expected
- `decisions.md` — Architectural decisions with rationale
- `tools.md` — Tool/library specific knowledge
- `open-questions.md` — Contradictions and unresolved items flagged by compile pass

## Source vs. Executable
- `tasks/*.md` = raw source (immutable until pruned). These wiki files = compiled output (Compile Pass only).
- The `<!-- last-compiled: ... -->` marker tracks when the AI last synthesized new sources.

## Journal Entry Template
```markdown
---
project: <slug>
started: YYYY-MM-DDTHH:MM:SSZ
completed: YYYY-MM-DDTHH:MM:SSZ
agents: [orchestrator, ...]
files_touched: [path1, path2]
status: done|partial|abandoned
---
# <Brief Title>
## Goal
- 1-line goal
## Outcome
- bullets (≤5)
## Notes
- bullets (≤5, optional)
```
## How to Use
- Read this file first for orientation and template reference
- Load topical files on demand via Read when relevant to current work
- Run `bash ~/.config/opencode/rites/forge-memory.sh -h` for tooling commands
