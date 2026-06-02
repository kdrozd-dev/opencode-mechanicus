# RITES — Sacred Designation Scripts

## OVERVIEW

Bash scripts that patch oh-my-openagent plugin dist files with Mechanicus designations and hook fixes.

## Migration History (v3.0 — 2026-06-01)

This forge-world migrated from `oh-my-openagent@4.5.12` to `oh-my-opencode-slim@1.x` on 2026-06-01.

**The `sacred-designation.sh` patching rite is OBSOLETE.** Slim provides native `displayName` config in `oh-my-opencode-slim.json` — Mechanicus aliasing is now config-only, no dist patching required.

**Commit attribution suppression** is enforced via `.git/hooks/commit-msg` (a git-level safety net). The AGENTS.md prompt rule remains as belt-and-suspenders.

**Legacy mainline doctrine** archived in `.omo.archive/` for historical reference.

**Revert path**: `git checkout main -- opencode.json` (atomic plugin pointer revert) or `git checkout main` (full branch revert).

## Operational Doctrine (Slim)

- **Mechanicus naming**: Configured via `oh-my-opencode-slim.json` → `agents.<key>.displayName`
- **Commit attribution**: `.git/hooks/commit-msg` strips AI attribution lines at git-level
- **AGENTS.md injection**: Handled by opencode core (unchanged from mainline)
- **Agent roster**: 9 agents — orchestrator, oracle, librarian, explorer, fixer, designer, observer (disabled), council, councillor
- **Legacy archive**: `.omo.archive/` contains prior plans and the retired `sacred-designation.sh` doctrine

## FILES

> **These files are RETIRED as of the omo→slim migration (2026-06-01). The table below is historical reference only.**

| File | Former Purpose |
|------|---------|
| `sacred-designation.sh` (DELETED) | Patched display names + 4 hook functions + neutralized AI attribution |

## ANTI-PATTERNS (RETIRED — for historical reference only)

> These rules applied to the deleted `sacred-designation.sh` rite. They are no longer operational.

- **NEVER** use line numbers in sed addresses — dist files shift between plugin versions
- **NEVER** modify `apply_designations` sed rules without testing against a fresh (unpatched) dist
- **NEVER** patch functions that already use `getAgentConfigKey` — those resolve names correctly
- **NEVER** expand scope beyond the 4 identified broken hook functions
- ~~**MUST** re-run with `-f` after `npm install` or `bun install` — patches are overwritten~~
- Repeated sed on already-patched files can corrupt — the idempotency guards prevent this, do not bypass them
