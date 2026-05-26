# RITES — Sacred Designation Scripts

## OVERVIEW

Bash scripts that patch oh-my-openagent plugin dist files with Mechanicus designations and hook fixes.

## FILES

| File | Purpose |
|------|---------|
| `sacred-designation.sh` | Patches display names + 4 hook functions + neutralizes AI attribution |

## HOW IT WORKS

Targets `node_modules/oh-my-openagent/dist/index.js` and `dist/cli/index.js`:

1. **Display names**: sed replacements scoped to `AGENT_DISPLAY_NAMES = { ... };` block
2. **Hook patches** (4 functions that don't recognize Mechanicus names):
   - `isPrometheusAgent` → adds `"magos tacticae"` recognition
   - `isPlannerAgent` → adds `"tacticae"` to condition
   - `PLAN_FAMILY_NAMES` → appends `"magos tacticae"` to array
   - `normalizeAgentName` → inserts `getAgentConfigKey` lookup before name matching
3. **Attribution neutralization**: `buildCommitFooterInjection` replaced with `return ""`
4. **Idempotency**: checks for `"Magos Dominus"` + `"magos tacticae"` markers before applying

## USAGE

```bash
./sacred-designation.sh        # Normal (prints status)
./sacred-designation.sh -q     # Quiet (for shell wrappers)
./sacred-designation.sh -f     # Force reapply (REQUIRED after plugin update)
```

## ANTI-PATTERNS

- **NEVER** use line numbers in sed addresses — dist files shift between plugin versions
- **NEVER** modify `apply_designations` sed rules without testing against a fresh (unpatched) dist
- **NEVER** patch functions that already use `getAgentConfigKey` — those resolve names correctly
- **NEVER** expand scope beyond the 4 identified broken hook functions
- **MUST** re-run with `-f` after `npm install` or `bun install` — patches are overwritten
- Repeated sed on already-patched files can corrupt — the idempotency guards prevent this, do not bypass them
