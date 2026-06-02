# Demote Compaction Agent from Opus to Sonnet

## TL;DR

> **Quick Summary**: Change the compaction (Enginseer) agent model from Claude Opus 4.6 to Claude Sonnet 4.5 to reduce cost on a high-frequency agent whose task (context compression) does not benefit from Opus-tier reasoning.
>
> **Deliverables**:
> - Updated `opencode.json` with Sonnet model for compaction
> - Verified compaction still functions correctly post-change
>
> **Estimated Effort**: Quick
> **Parallel Execution**: NO - sequential (2 trivial steps)
> **Critical Path**: Task 1 → Task 2 → F1-F4

---

## Context

### Original Request
Demote the compaction agent from Opus to Sonnet. Leave metis unchanged.

### Interview Summary
**Key Discussions**:
- Analysis of all 4 Opus-consuming agents (sisyphus, prometheus, metis, compaction)
- Compaction identified as safest demotion: mechanical summarization, no deep reasoning needed, highest invocation frequency = highest cost savings
- Metis explicitly excluded from changes per Archmagos directive

### Research Findings
- Sonnet 4.5 scores within 1.2 points of Opus on SWE-bench (coding tasks)
- Compaction is summarization/compression — well within Sonnet's capabilities
- The `anthropic-effort` hook auto-clamps `variant: "max"` to `"high"` on non-Opus models, so no variant configuration is needed
- Compaction model is configured in `opencode.json` under `agent.compaction.model`, NOT in `oh-my-openagent.json`

---

## Work Objectives

### Core Objective
Replace the compaction agent's model from Opus 4.6 to Sonnet 4.5 for cost efficiency.

### Concrete Deliverables
- `opencode.json`: Updated `agent.compaction.model` value

### Definition of Done
- [ ] `opencode.json` contains `"model": "amazon-bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0"` under `agent.compaction`
- [ ] Compaction triggers without error in a live session

### Must Have
- Compaction agent uses Claude Sonnet 4.5 via Amazon Bedrock
- All other agent configurations remain untouched

### Must NOT Have (Guardrails)
- DO NOT modify `oh-my-openagent.json`
- DO NOT change any other agent's model (sisyphus, prometheus, metis, or any other)
- DO NOT add a `variant` field to compaction — it is unnecessary for Sonnet on a summarization task
- DO NOT modify any other field in `opencode.json` beyond `agent.compaction.model`

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: N/A (config change, not code)
- **Automated tests**: None — verification is functional (trigger compaction, observe success)
- **Framework**: N/A

### QA Policy
Every task includes agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Single task):
└── Task 1: Edit opencode.json [quick]

Wave 2 (Verification):
└── Task 2: Verify compaction works with Sonnet [quick]

Wave FINAL (After ALL tasks):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real manual QA (unspecified-high)
└── F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1    | —         | 2, F1-F4 |
| 2    | 1         | F1-F4 |

### Agent Dispatch Summary

- **Wave 1**: 1 task — T1 → `quick`
- **Wave 2**: 1 task — T2 → `quick`
- **FINAL**: 4 tasks — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Update compaction model in opencode.json

  **What to do**:
  - Open `opencode.json`
  - Change `agent.compaction.model` from `"amazon-bedrock/global.anthropic.claude-opus-4-6-v1"` to `"amazon-bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0"`
  - Save the file

  **Must NOT do**:
  - Modify any other field in `opencode.json`
  - Touch `oh-my-openagent.json`
  - Add a `variant` field to the compaction config

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single-line JSON value change — trivial edit
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `git-master`: No commit required as part of this task

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (solo)
  - **Blocks**: Task 2, F1-F4
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `opencode.json:66-73` — The `agent` block containing the current `compaction` config with Opus model

  **API/Type References**:
  - The Sonnet model ID to use: `amazon-bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0` (same ID used by `librarian` and `atlas` in `oh-my-openagent.json:13,34`)

  **WHY Each Reference Matters**:
  - `opencode.json:66-73`: This is the ONLY file to edit. The compaction model is on line 71. Other agents in `oh-my-openagent.json` use the same Sonnet model string — use that as the canonical reference.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Correct model string in config
    Tool: Bash (grep)
    Preconditions: Task 1 edit applied
    Steps:
      1. Run: grep -A2 '"compaction"' opencode.json
      2. Assert output contains "amazon-bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0"
      3. Assert output does NOT contain "opus"
    Expected Result: compaction.model is the Sonnet model ID
    Failure Indicators: "opus" appears in the compaction block, or model string is malformed
    Evidence: .sisyphus/evidence/task-1-config-verified.txt

  Scenario: No other config sections modified
    Tool: Bash (git diff)
    Preconditions: Task 1 edit applied
    Steps:
      1. Run: git diff opencode.json
      2. Assert exactly 1 line changed (the model value)
      3. Assert no other files are modified: git diff --name-only shows only opencode.json
    Expected Result: Exactly one line changed in one file
    Failure Indicators: Multiple lines changed, or files other than opencode.json modified
    Evidence: .sisyphus/evidence/task-1-scope-check.txt
  ```

  **Commit**: YES
  - Message: `fix(config): demote compaction agent from Opus to Sonnet for cost efficiency`
  - Files: `opencode.json`
  - Pre-commit: `grep "sonnet" opencode.json | grep compaction`

---

- [x] 2. Verify compaction functions with Sonnet

  **What to do**:
  - Trigger a compaction cycle in a live opencode session and confirm it completes without error
  - This verifies the model string is valid and the Bedrock endpoint responds correctly for Sonnet on compaction tasks

  **Must NOT do**:
  - Modify any files
  - Change any configuration

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Verification-only task, no implementation
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (solo, after Task 1)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 1

  **References**:

  **Pattern References**:
  - `opencode.json:66-73` — The updated compaction config to verify against

  **WHY Each Reference Matters**:
  - The config must be loaded by a running opencode instance to confirm Bedrock accepts the Sonnet model ID for compaction operations

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Compaction completes without error
    Tool: interactive_bash (tmux)
    Preconditions: opencode.json has been updated with Sonnet model for compaction
    Steps:
      1. Start a new opencode session in tmux
      2. Send a message that generates enough context to approach compaction threshold, OR manually trigger compaction via the /compact command if available
      3. Observe the compaction output — it should complete without model-related errors
      4. Capture the terminal output showing successful compaction
    Expected Result: Compaction completes. No errors mentioning model resolution, invalid model ID, or Bedrock access failures
    Failure Indicators: Error messages containing "model not found", "invalid model", "access denied", or "compaction failed"
    Evidence: .sisyphus/evidence/task-2-compaction-success.png

  Scenario: Compaction does not use Opus
    Tool: Bash (grep on logs if available)
    Preconditions: Compaction has been triggered at least once
    Steps:
      1. Check opencode session logs or output for model references during compaction
      2. Confirm the model used is Sonnet, not Opus
    Expected Result: Logs reference "claude-sonnet" for the compaction operation
    Failure Indicators: Logs reference "claude-opus" during compaction
    Evidence: .sisyphus/evidence/task-2-model-confirmed.txt
  ```

  **Commit**: NO (verification only)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan. Verify "Must Have": compaction uses Sonnet. Verify "Must NOT Have": no other agents changed, no variant added, oh-my-openagent.json untouched. Check evidence files exist in .sisyphus/evidence/.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Validate `opencode.json` is valid JSON. Confirm the model string matches the canonical Sonnet Bedrock ID exactly. Check for no trailing commas or syntax issues.
  Output: `JSON Valid [PASS/FAIL] | Model String [CORRECT/INCORRECT] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  Verify compaction works end-to-end in a live session. Confirm no degradation in compaction quality (summary preserves key context).
  Output: `Compaction [PASS/FAIL] | Quality [ACCEPTABLE/DEGRADED] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  Run `git diff` against the plan. Verify exactly one line changed in exactly one file. No scope creep, no unaccounted modifications.
  Output: `Files Changed [1/1] | Lines Changed [1/1] | Contamination [CLEAN] | VERDICT`

---

## Commit Strategy

- **Task 1**: `fix(config): demote compaction agent from Opus to Sonnet for cost efficiency` — `opencode.json`

---

## Success Criteria

### Verification Commands
```bash
grep -A2 '"compaction"' opencode.json  # Expected: "model": "amazon-bedrock/global.anthropic.claude-sonnet-4-5-20250929-v1:0"
git diff --stat                         # Expected: 1 file changed, 1 insertion, 1 deletion
```

### Final Checklist
- [ ] Compaction model is Claude Sonnet 4.5
- [ ] No other agents modified
- [ ] oh-my-openagent.json untouched
- [ ] Compaction functions without error
- [ ] All tests pass
