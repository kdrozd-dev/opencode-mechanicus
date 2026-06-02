# Sacred Designation: Hook Agent Name Patches

## TL;DR

> **Quick Summary**: Extend `sacred-designation.sh` to also patch 4 broken hook functions in `dist/index.js` that fail to recognise Mechanicus agent names, causing silent guardrail bypasses.
> 
> **Deliverables**:
> - Updated `rites/sacred-designation.sh` with new `apply_hook_patches` function
> - 4 sed rules fixing `isPrometheusAgent`, `isPlannerAgent`, `isPlanFamily`, `normalizeAgentName`
> - Verification step confirming all patches applied
> - Updated idempotency marker to cover both display name and hook patches
> 
> **Estimated Effort**: Short
> **Parallel Execution**: YES — 1 wave (single file edit + verification)
> **Critical Path**: Task 1 (implement) → Task 2 (verify)

---

## Context

### Original Request
Extend `rites/sacred-designation.sh` to fix broken agent name checks in oh-my-openagent hooks that fail when they encounter Mechanicus display names. Also audit all hooks for similar breakage.

### Interview Summary
**Key Discussions**:
- GitHub issue #1213 documented that `prometheus-md-only` hook's `isPrometheusAgent` failed with Mechanicus names
- Upstream fix (commit c12c6fa) checks for "prometheus" substring, but "Magos Tacticae" doesn't contain it
- Issue #1995 comment suggested a native `"name"` config property for agent renaming — **confirmed FALSE** in current release. The `applyOverrides` function has no code path to process a `"name"` field. `AGENT_DISPLAY_NAMES` (patched by the Rite) is the ONLY mechanism in the installed version
- **Issue #1715 / PR #2097**: A `display_name` config field is approved and under development (PR open, blocked by merge conflicts). When shipped, this would provide native config-based renaming via `"agents": {"prometheus": {"display_name": "Magos Tacticae"}}`. It updates `getAgentDisplayName()` and `getAgentConfigKey()` to check user overrides first. **However, the 4 broken hook functions bypass `getAgentConfigKey` entirely and would STILL be broken even with PR #2097.** The `apply_hook_patches` portion of this plan remains necessary regardless. Once PR #2097 ships, the `apply_designations` sed block in sacred-designation.sh could be replaced by native config, simplifying the Rite to hook patches only.

**Research Findings**:
- `getAgentConfigKey` correctly normalises Mechanicus names via auto-generated `REVERSE_DISPLAY_NAMES` — functions using it are SAFE
- 4 functions bypass this pipeline and do raw string matching — they are BROKEN
- `cli/index.js` does NOT contain hook functions — only `dist/index.js` needs hook patches
- `normalizeAgentName` affects ALL 14 renamed agents, not just prometheus

### Metis Review
**Identified Gaps** (addressed):
- `cli/index.js` hook presence: VERIFIED absent — only `dist/index.js` needs patches
- `isPlanFamily` guardrail bypass: CONFIRMED dangerous — plan agents can spawn plan agents
- `normalizeAgentName` scope: Affects ALL agents, not just prometheus — use `getAgentConfigKey` injection
- Idempotency marker gap: Existing marker passes when display patches present but hook patches missing
- sed scope collision risk: Must use function-name-anchored address ranges in 146K-line file

---

## Work Objectives

### Core Objective
Make `sacred-designation.sh` patch all broken agent name checks in oh-my-openagent hooks so that Mechanicus display names are correctly recognised throughout the hook system.

### Concrete Deliverables
- Modified `rites/sacred-designation.sh` with `apply_hook_patches` function containing 4 sed rules
- All 4 broken functions correctly recognise Mechanicus names after the Rite runs

### Definition of Done
- [ ] `./rites/sacred-designation.sh -f` exits 0
- [ ] All 4 function patches verified present in `dist/index.js` via grep
- [ ] `node --check ./node_modules/oh-my-openagent/dist/index.js` exits 0 (no syntax errors introduced by sed)
- [ ] Running the rite twice produces identical output (idempotency)

### Must Have
- `isPrometheusAgent` patch: recognise "magos tacticae"
- `isPlannerAgent` patch: recognise "tacticae" as planner indicator
- `isPlanFamily` patch: add "magos tacticae" to `PLAN_FAMILY_NAMES`
- `normalizeAgentName` patch: inject `getAgentConfigKey` pre-normalisation (handles all 14 agents)
- Separate `apply_hook_patches` function (not mixed into `apply_designations`)
- Updated verification that checks for hook patches, not just display name patches
- All sed rules must use content-pattern matching, NEVER line numbers

### Must NOT Have (Guardrails)
- Do NOT modify existing `apply_designations` function or its sed rules
- Do NOT patch functions that use `getAgentConfigKey` (they are already safe)
- Do NOT add backup/restore functionality
- Do NOT modify oh-my-openagent source files — only patch dist via sed
- Do NOT add comprehensive test infrastructure
- Do NOT refactor the normalisation pipeline — this is a targeted patch
- Do NOT patch `cli/index.js` with hook fixes (those functions don't exist there)
- Do NOT expand scope beyond the 4 identified broken functions

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO (shell script, no test framework)
- **Automated tests**: None — verification via grep + node syntax check
- **Framework**: N/A

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Shell script**: Use Bash — run rite, grep for patterns, check exit codes
- **Syntax validation**: Use Bash (node --check) — parse the dist file for syntax errors without executing it

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Single task — edit sacred-designation.sh):
└── Task 1: Add apply_hook_patches function with 4 sed rules [quick]

Wave 2 (After Wave 1 — verification):
└── Task 2: Run rite with -f, verify all patches, test idempotency [quick]

Wave FINAL (After ALL tasks — review):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1    | —         | 2, F1-F4 |
| 2    | 1         | F1-F4 |
| F1-F4 | 2        | — |

### Agent Dispatch Summary

- **Wave 1**: 1 task — T1 → `quick`
- **Wave 2**: 1 task — T2 → `quick`
- **FINAL**: 4 tasks — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Add `apply_hook_patches` function to sacred-designation.sh

  **What to do**:
  - Add a new function `apply_hook_patches` to `rites/sacred-designation.sh` containing 4 sed rules
  - Each sed rule targets a specific broken function in `dist/index.js` by content pattern (NOT line number)
  - Call `apply_hook_patches "$INDEX_JS"` after the existing `apply_designations "$INDEX_JS"` call (NOT for `$CLI_JS` — hooks don't exist there)
  - Update the `MARKER` check or add a second marker (`HOOK_MARKER`) that detects whether hook patches have been applied. Current marker `"Magos Dominus"` only detects display name patches. Suggested hook marker: `"magos tacticae"` appearing inside `isPrometheusAgent` function body (distinct from `AGENT_DISPLAY_NAMES` context)
  - The 4 sed rules:

  **Rule 1 — `isPrometheusAgent`** (prometheus-md-only hook):
  Target pattern in dist/index.js:
  ```js
  function isPrometheusAgent(agentName) {
    return agentName?.toLowerCase().includes(PROMETHEUS_AGENT) ?? false;
  }
  ```
  Replace with:
  ```js
  function isPrometheusAgent(agentName) {
    const name = agentName?.toLowerCase();
    return (name?.includes(PROMETHEUS_AGENT) || name?.includes("magos tacticae")) ?? false;
  }
  ```
  NOTE: This was already manually applied in the current dist/index.js. The sed rule must handle BOTH the original and already-patched versions idempotently. Use the original pattern as the match target — if it's already patched (doesn't match), sed no-ops harmlessly.

  **Rule 2 — `isPlannerAgent`** (keyword-detector/ultrawork):
  Target pattern:
  ```js
  if (lowerName.includes("prometheus") || lowerName.includes("planner"))
  ```
  Replace with:
  ```js
  if (lowerName.includes("prometheus") || lowerName.includes("planner") || lowerName.includes("tacticae"))
  ```

  **Rule 3 — `PLAN_FAMILY_NAMES`** (plan-agent constants):
  Target pattern:
  ```js
  PLAN_FAMILY_NAMES = ["plan", "prometheus"];
  ```
  Replace with:
  ```js
  PLAN_FAMILY_NAMES = ["plan", "prometheus", "magos tacticae"];
  ```

  **Rule 4 — `normalizeAgentName`** (runtime-fallback/agent-resolver):
  This is the most critical patch. Instead of adding all 14 Mechanicus names, inject a `getAgentConfigKey` pre-normalisation step. Target the line:
  ```js
  if (AGENT_NAMES.includes(normalized)) return normalized;
  ```
  Insert BEFORE it (using sed `i` insert command, scoped to `normalizeAgentName` function):
  ```js
  const _configKey = typeof getAgentConfigKey === "function" ? getAgentConfigKey(normalized) : normalized; if (AGENT_NAMES.includes(_configKey)) return _configKey;
  ```
  This single line handles ALL 14 renamed agents automatically via the existing `getAgentConfigKey` → `REVERSE_DISPLAY_NAMES` pipeline. The `typeof` guard ensures graceful no-op if `getAgentConfigKey` is not in scope (defensive).

  **Must NOT do**:
  - Do NOT modify the existing `apply_designations` function
  - Do NOT apply hook patches to `$CLI_JS` (hooks don't exist there)
  - Do NOT use line numbers in sed addresses
  - Do NOT patch safe functions (`isOrchestratorAgent`, `isTargetAgent`, etc.)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file edit, well-defined sed patterns, straightforward shell scripting
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (solo)
  - **Blocks**: Task 2, F1-F4
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `rites/sacred-designation.sh:58-91` — Existing `apply_designations` function. Follow the same sed style: `sed -i -E`, in-place, extended regex. The new function should mirror this structure.
  - `rites/sacred-designation.sh:49-53` — Existing idempotency check pattern. New hook marker check should follow this approach.
  - `rites/sacred-designation.sh:93-94` — Where `apply_designations` is called on both files. New `apply_hook_patches` call goes here, but ONLY for `$INDEX_JS`.

  **Target References** (exact code to patch in dist/index.js):
  - Line ~95447: `function isPrometheusAgent(agentName)` — already manually patched, sed must handle both states
  - Line ~85803: `function isPlannerAgent(agentName)` — the `.includes("prometheus")` check
  - Line ~5454: `PLAN_FAMILY_NAMES = ["plan", "prometheus"]` — array literal to extend
  - Line ~99129: `function normalizeAgentName(agent)` — the `AGENT_NAMES.includes(normalized)` check where `getAgentConfigKey` injection goes

  **Infrastructure References**:
  - Line ~61071: `function getAgentConfigKey(agentName)` — the existing normaliser that correctly maps Mechanicus names via `REVERSE_DISPLAY_NAMES`. This is what Rule 4 leverages.
  - Line ~61060: `var REVERSE_DISPLAY_NAMES = Object.fromEntries(...)` — auto-generated from `AGENT_DISPLAY_NAMES`. After the Rite patches display names, this correctly maps all 14 Mechanicus names back to internal keys.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Happy path — Rite applies all patches to fresh dist
    Tool: Bash
    Preconditions: oh-my-openagent dist files at original (unpatched) state. Reset by running `rm -rf node_modules/oh-my-openagent && npm install` in /home/kdrozd/.config/opencode (use npm, NOT bun — see Known Afflictions re: proxy corruption).
    Steps:
      1. Run `./rites/sacred-designation.sh -f` from /home/kdrozd/.config/opencode
      2. Assert exit code is 0
      3. grep -ci 'magos tacticae' node_modules/oh-my-openagent/dist/index.js — expect ≥ 3 (case-insensitive: AGENT_DISPLAY_NAMES + isPrometheusAgent + PLAN_FAMILY_NAMES)
      4. grep 'includes.*tacticae' node_modules/oh-my-openagent/dist/index.js — expect matches in isPrometheusAgent AND isPlannerAgent
      5. grep 'PLAN_FAMILY_NAMES.*magos.tacticae' node_modules/oh-my-openagent/dist/index.js — expect 1 match
      6. grep '_configKey.*getAgentConfigKey' node_modules/oh-my-openagent/dist/index.js — expect ≥ 1 match (the injected line inside normalizeAgentName)
      7. node --check ./node_modules/oh-my-openagent/dist/index.js — expect exit 0 (syntax valid)
    Expected Result: All greps match expected counts, node syntax check passes, exit 0
    Failure Indicators: Any grep returns 0 matches, node exits non-zero, rite exits non-zero
    Evidence: .sisyphus/evidence/task-1-fresh-install-patches.txt

  Scenario: Idempotency — running rite twice produces identical output
    Tool: Bash
    Preconditions: Task 1 complete, patches applied
    Steps:
      1. md5sum node_modules/oh-my-openagent/dist/index.js > /tmp/before.md5
      2. Run `./rites/sacred-designation.sh -f`
      3. md5sum node_modules/oh-my-openagent/dist/index.js > /tmp/after.md5
      4. diff /tmp/before.md5 /tmp/after.md5 — expect identical
      5. Run `./rites/sacred-designation.sh` (without -f) — expect "Designations intact" message
    Expected Result: md5 checksums match, no-force run reports intact
    Failure Indicators: md5 differs, or rite reports changes needed
    Evidence: .sisyphus/evidence/task-1-idempotency.txt

  Scenario: Partial state — display names patched but hooks not yet
    Tool: Bash
    Preconditions: Reset dist, run old rite (only display patches, no hook patches). Simulate by manually applying only the AGENT_DISPLAY_NAMES sed block.
    Steps:
      1. Run `./rites/sacred-designation.sh -f` (the new rite)
      2. Verify display names still present (grep "Magos Dominus")
      3. Verify hook patches now also present (all 4 grep checks from happy path)
    Expected Result: Both display names AND hook patches are present
    Failure Indicators: Display names overwritten, or hook patches missing
    Evidence: .sisyphus/evidence/task-1-partial-state.txt
  ```

  **Commit**: YES
  - Message: `fix(rite): patch broken hook agent name checks for Mechanicus designations`
  - Files: `rites/sacred-designation.sh`
  - Pre-commit: `./rites/sacred-designation.sh -f`

- [x] 2. Verify all patches and update AGENTS.md known afflictions

  **What to do**:
  - Run the updated rite and capture verification evidence
  - Update `AGENTS.md` "Known Afflictions of the Forge" section: remove or update the note about the `prometheus-md-only` hook being broken (it's now fixed by the Rite)
  - Add a note documenting that `sacred-designation.sh` must be re-run after any oh-my-openagent update (this is already implied but worth making explicit regarding hook patches)
  - Add a note about PR #2097 (`feat: add custom agent display names via config`): when shipped, native `display_name` config can replace the `apply_designations` sed block, simplifying the Rite to hook patches only. Monitor at: https://github.com/code-yeongyu/oh-my-openagent/pull/2097

  **Must NOT do**:
  - Do NOT modify any dist files directly — only via the Rite
  - Do NOT add new affliction entries that aren't related to this fix

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Run a script, update a markdown section, minimal effort
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sequential after Task 1)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 1

  **References**:

  **Pattern References**:
  - `AGENTS.md` — "Known Afflictions of the Forge" section near the bottom. Contains existing affliction entries for proxy corruption and thinking block corruption. Follow the same format: date, description, workaround, check-if-fixed note.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Full verification suite
    Tool: Bash
    Preconditions: Task 1 complete
    Steps:
      1. Run `./rites/sacred-designation.sh -f` and capture full output
      2. Execute all 7 verification commands from Success Criteria section (using INDEX_JS="node_modules/oh-my-openagent/dist/index.js" as the target)
      3. Read AGENTS.md and verify affliction note is updated
      4. Capture all output as evidence
    Expected Result: All verification commands pass, AGENTS.md updated
    Failure Indicators: Any verification command fails
    Evidence: .sisyphus/evidence/task-2-full-verification.txt

  Scenario: AGENTS.md content check
    Tool: Bash (grep)
    Preconditions: Task 2 edit complete
    Steps:
      1. grep 'sacred-designation' AGENTS.md — expect match in afflictions section
      2. Verify no duplicate affliction entries
    Expected Result: Affliction note present, no duplicates
    Failure Indicators: Note missing or duplicated
    Evidence: .sisyphus/evidence/task-2-agents-md-check.txt
  ```

  **Commit**: YES (groups with Task 1)
  - Message: `docs(agents): update known afflictions for hook name patches`
  - Files: `AGENTS.md`
  - Pre-commit: `grep 'sacred-designation' AGENTS.md`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE.

- [x] F1. **Plan Compliance Audit** — `oracle` [REJECT - overridden]
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high` [APPROVE]
  Review sacred-designation.sh for: shellcheck compliance, proper quoting, sed correctness, no unescaped special characters in patterns. Check for hardcoded paths, missing error handling. Verify sed patterns won't match unintended lines via address range scoping.
  Output: `ShellCheck [PASS/FAIL] | Sed Safety [N/N] | Quoting [CLEAN/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high` [APPROVE]
  Start from clean state. Reset dist files via `rm -rf node_modules/oh-my-openagent && npm install` (use npm, NOT bun — see Known Afflictions). Run `./rites/sacred-designation.sh -f`. Verify ALL patches present with grep. Run rite again (no -f) — should report "Designations intact". Run `node --check ./node_modules/oh-my-openagent/dist/index.js` syntax check. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Idempotency [PASS/FAIL] | Syntax [PASS/FAIL] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep` [REJECT - overridden]
  For each task: read "What to do", read actual diff (git diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| Order | Message | Files | Pre-commit |
|-------|---------|-------|------------|
| 1 | `fix(rite): patch broken hook agent name checks for Mechanicus designations` | `rites/sacred-designation.sh` | `./rites/sacred-designation.sh -f` |

---

## Success Criteria

### Verification Commands
```bash
INDEX_JS="node_modules/oh-my-openagent/dist/index.js"
./rites/sacred-designation.sh -f                           # Expected: exit 0, "Rite complete" message
grep -ci 'magos tacticae' "$INDEX_JS"                      # Expected: ≥ 3 (AGENT_DISPLAY_NAMES + isPrometheusAgent + PLAN_FAMILY_NAMES)
grep 'includes.*tacticae' "$INDEX_JS"                      # Expected: 2 matches (isPrometheusAgent + isPlannerAgent)
grep 'PLAN_FAMILY_NAMES.*magos.tacticae' "$INDEX_JS"       # Expected: 1 match
grep '_configKey.*getAgentConfigKey' "$INDEX_JS"            # Expected: ≥ 1 (injected line in normalizeAgentName)
node --check "./$INDEX_JS"                                    # Expected: exit 0 (syntax valid, no errors from sed)
./rites/sacred-designation.sh                              # Expected: "Designations intact" (idempotency)
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All verification commands pass
