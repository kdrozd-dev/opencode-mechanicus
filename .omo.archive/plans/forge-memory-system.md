# Forge-Memory System (Karpathy Compiler-Aligned)

## TL;DR

> **Quick Summary**: Build a Karpathy-aligned memory system for OpenCode where raw task journal entries (the "source code") are compiled by the AI into structured topical wiki files (the "executable"). Hierarchical loading + per-project 14-day rolling source archive + autonomous compile pass + autonomous prune + on-demand reports. All per-project memory lives **out-of-tree** — never inside foreign repos.
>
> **Architecture mapping** (Karpathy compiler analogy):
> - **Source code** = raw journal entries in `tasks/`
> - **Compiler** = the AI, orchestrated by `forge-memory.sh compile-prep` + AGENTS.md instructions
> - **Executable** = topical wiki files in `knowledge/` (global) and `wiki/topics/` (per-project) with synthesis, last-compiled markers, and open-questions tracking
>
> **Deliverables**:
> - `~/.config/opencode/.forge/knowledge/` — global compiled wiki: `_index.md` + 5 topical files + `open-questions.md` (git-tracked in opencode-config)
> - `~/.local/share/opencode-forge/{project-key}/{tasks,wiki}/` — per-project source + executable, **out-of-tree**, never git-tracked
> - `~/.config/opencode/rites/forge-memory.sh` — bash tool with `path`, `new`, `prune`, `report`, `compile-prep`, `autostart`, `-h`
> - `~/.claude/skills/forge-memory/SKILL.md` — skill exposing workflow (incl. compile pass orchestration)
> - AGENTS.md "Forge Memory Protocol" section with **autonomous triggers** (session-start, post-N-entries) (≤28 lines added; total ≤281)
> - Migrated KNOWLEDGE.md → `_index.md` redirect
> - `.gitignore` defense-in-depth: `.forge/tasks/` (in opencode-config only)
>
> **Estimated Effort**: Medium-Large
> **Parallel Execution**: YES — 3 implementation waves + final review wave
> **Critical Path**: Plan Quality Gates (planning-phase, completed before `/start-work`) → T1 → T6 → T9 → F-wave (execution-phase) → user okay

---

## Plan Quality Gates (Planning-Phase — completed before `/start-work`)

> These gates ran **during plan generation** (Prometheus phase), not during execution. They are documented here for full traceability.
>
> | Gate | Agent | Purpose | Status |
> |---|---|---|---|
> | G1 — Gap analysis | Metis (Divinator) | Surface hidden variables, scope-creep risks, ambiguities | ✅ PASSED |
> | G2 — Phase-1 readiness | Oracle (Logis Magna) | Verify interview completeness | ✅ PASSED 5/5 |
> | G3 — Phase-2 plan compliance | Oracle (Logis Magna) | Verify TODOs, acceptance criteria, parallelism, scope | ✅ PASSED 12/12 |
> | G4 — Phase-3 readiness | Oracle (Logis Magna) | Verify plan ready for execution + handoff | ✅ PASSED |
> | G5 — High-accuracy review | **Momus (Magos Reductor)** | Rigorously verify every reference, criterion, deliverable | **REQUIRED — Iterate until VERDICT: OKAY** |
>
> **G5 Loop Protocol**: User elected "High Accuracy Review" mode. Plan must be submitted to Momus; on REJECT, all cited issues fixed, plan resubmitted; loop until VERDICT: OKAY. Only after OKAY does the plan transition to `/start-work` for execution.
>
> **Once all 5 gates pass, the plan is sealed. Execution gates (F1-F4) take over post-implementation.**

---

## Context

### Original Request
> "How to configure open code and omo to create a knowledge base while working. Consisting of .md files. Something like karpathy method for memory. It must be wellstructured and easy to work with for ai"
>
> "Plan out this method, make it token efficient, also prepare noting tasks done over the last 2 weeks with automatic pruning and skill to generate short report from those task over a given timespan eg 1 week, 2 days or whole 2 weeks etc."
>
> "The knowledge base should not be tracked in repos as it would interfere with work on those public repos"
>
> "Verify it is in spirit aligned with [Karpathy compiler analogy] and is fully automatic"

### Karpathy Compiler Analogy — Architectural Alignment

This plan is structured around Karpathy's compiler analogy ([source](https://www.mindstudio.ai/blog/karpathy-llm-knowledge-base-compiler-analogy)):

| Karpathy Concept | This System |
|---|---|
| **Source code** (raw, verbose, redundant) | Per-project journal entries in `tasks/*.md` |
| **Compiler** (resolves contradictions, structures, synthesizes) | The AI, orchestrated by `forge-memory.sh compile-prep` + Skill workflow |
| **Executable** (compiled, structured, queryable wiki) | Topical files in `knowledge/` (global) + `wiki/topics/` (per-project) |
| **Recompile on new sources** | Autonomous trigger: AI runs compile after N=5 new entries OR session-start |
| **Wiki structure** (topic pages, synthesis, open questions, source refs, last-updated markers) | All present — `open-questions.md` + last-compiled marker in `_index.md` + source refs in compiled entries |
| **Markdown format** | Yes |
| **Hierarchical / on-demand load** | Always-loaded TOC; topical files via Read on-demand |

### Full Automation Commitments

- ✅ **Path resolution**: scripted (`forge-memory.sh path`)
- ✅ **Stub creation**: scripted (`new <slug>`)
- ✅ **Journal entry writing**: AGENTS.md instructs AI to log on task completion (best-effort; accepted)
- ✅ **Pruning**: autonomous via `forge-memory.sh autostart` invoked by AI on session start
- ✅ **Compilation pass**: autonomous — AI invokes after N=5 journal entries or on session start
- ⚠️ **Reports**: on-demand only (user explicitly chose inline digest, not automatic)

### Interview Summary
**Key Decisions** (confirmed in order, with phase-3 Karpathy/full-automation refinements applied):
1. **Scope**: Hybrid — global cross-project + per-project memory
2. **Granularity**: One journal entry per user request
3. **Pruning**: Hard delete entries > 14 days
4. **Pruning trigger**: Autonomous via `autostart` (AI invokes on session start) AND on-demand via skill (refined from initial "on-demand only" choice during phase-3 full-automation alignment)
5. **Report**: Inline markdown digest (no file output by default)
6. **Path namespace**: `.forge/` (avoids `.opencode/` runtime collision flagged by Metis)
7. **KNOWLEDGE.md fate**: Migrate content → `.forge/knowledge/_index.md`
8. **Per-project memory location**: **Out-of-tree** at `~/.local/share/opencode-forge/{project-key}/` — corrected from earlier plan after user pointed out foreign-repo pollution risk
9. **Who writes journal entries**: AI assistant, instructed via AGENTS.md (compliance accepted as best-effort)
10. **Test strategy**: none + agent QA (no test framework, bash + markdown only)
11. **Karpathy alignment** (phase-3 user requirement): source/executable separation, compile pass with manifest-based AI synthesis, last-compiled markers, open-questions tracking
12. **Full automation** (phase-3 user requirement): autonomous triggers in AGENTS.md (session-start `autostart`, post-N-entries=5 compile)

### Research Findings
- AGENTS.md currently 253 lines — additions must stay ≤28 (hard ceiling 281, raised from initial 273 during phase-3 to accommodate autonomous triggers)
- KNOWLEDGE.md exists at 137 lines, generated 2026-04-20, never updated since
- `.opencode/` is OpenCode runtime dir (`node_modules/`, `package.json`) — DO NOT touch
- `.omo/` is NOT in root `.gitignore` (only `.sisyphus/`, `node_modules/`, `.venv/`, `.opencode/`, `logs/`, `*.bak`)
- 3 existing skills follow pattern `~/.claude/skills/{name}/SKILL.md` with frontmatter (`name:`, `description:`)
- Existing rite pattern: `rites/sacred-designation.sh` with idempotency markers + `-q`/`-f` flags
- DCP context compression triggers at 60% — protocol must survive compression (keep short)

### Metis Review (Hidden Variables Surfaced and Resolved)
- ✅ `.opencode/knowledge/` collision → `.forge/` namespace
- ✅ KNOWLEDGE.md migration path → migrate to `_index.md`
- ✅ AGENTS.md bloat → hard ceiling 281 lines (≤28 line additions; raised from 273 during Karpathy expansion)
- ✅ AI compliance imperfection → accepted; protocol kept ≤28 lines total
- ✅ Multi-project journal scope → per-project, out-of-tree (post-revision)
- ✅ Journal entry verbosity → hard cap 25 lines per entry
- ✅ Empty-state handling → required in skill + script
- ✅ Slug collision → mitigated by `YYYY-MM-DD-HHMMSS-slug` second-level granularity
- ✅ Foreign-repo pollution → out-of-tree storage at `~/.local/share/opencode-forge/`

---

## Work Objectives

### Core Objective
Build a token-efficient, markdown-based memory system for OpenCode consisting of (a) a hierarchical knowledge base loaded on-demand, (b) a per-project 14-day rolling task journal stored out-of-tree (never inside foreign repos) and written by the AI after each user request, and (c) a skill that prunes expired entries and generates short timespan-bounded report digests.

### Concrete Deliverables
1. `~/.config/opencode/.forge/knowledge/_index.md` (≤40 lines, always-loaded TOC + journal template + protocol summary + last-compiled marker)
2. `~/.config/opencode/.forge/knowledge/learnings.md` (compiled wiki seed: header + empty section)
3. `~/.config/opencode/.forge/knowledge/patterns.md` (compiled wiki seed)
4. `~/.config/opencode/.forge/knowledge/gotchas.md` (compiled wiki seed)
5. `~/.config/opencode/.forge/knowledge/decisions.md` (compiled wiki seed)
6. `~/.config/opencode/.forge/knowledge/tools.md` (compiled wiki seed)
7. `~/.config/opencode/.forge/knowledge/open-questions.md` (NEW: contradictions/unresolved items flagged by compile pass)
8. `~/.config/opencode/.gitignore` updated with `.forge/tasks/` rule (defense-in-depth)
9. `~/.config/opencode/AGENTS.md` with "Forge Memory Protocol" section (≤28 added lines, total ≤281) — includes autonomous triggers (session-start, post-N-entries)
10. `~/.config/opencode/rites/forge-memory.sh` (executable, ≤450 lines, supports `path`, `new`, `prune`, `report`, `compile-prep`, `autostart`, `-h`, `-q`)
11. `~/.claude/skills/forge-memory/SKILL.md` (≤130 lines; skill exposing workflow including compile pass orchestration)
12. `~/.config/opencode/KNOWLEDGE.md` replaced with one-line redirect to `.forge/knowledge/_index.md`

Per-project structure created lazily by script on first invocation:
- `~/.local/share/opencode-forge/{project-key}/tasks/` — SOURCE: raw journal
- `~/.local/share/opencode-forge/{project-key}/wiki/_index.md` — TOC + last-compiled
- `~/.local/share/opencode-forge/{project-key}/wiki/topics/` — compiled topic pages
- `~/.local/share/opencode-forge/{project-key}/wiki/open-questions.md`

### Definition of Done
- [ ] `bash rites/forge-memory.sh path` from any cwd prints absolute path under `~/.local/share/opencode-forge/`
- [ ] `bash rites/forge-memory.sh new "test slug"` creates a stub journal entry, prints its absolute path; the stub conforms to template
- [ ] `bash rites/forge-memory.sh report 14d` prints markdown digest (or "No tasks recorded in this period." on empty)
- [ ] `bash rites/forge-memory.sh prune --dry-run` lists candidate files; without flag, deletes them
- [ ] `bash rites/forge-memory.sh compile-prep` prints a structured manifest containing: scope, since-timestamp, last-compiled timestamp, list of new entries with paths and bullets, current wiki section index, and synthesis instructions
- [ ] `bash rites/forge-memory.sh autostart` runs prune (auto, days=14) and prints "needs-compile: yes/no" based on entry-count threshold (default 5)
- [ ] `bash rites/forge-memory.sh -h` prints usage including all 6 subcommands and exits 0
- [ ] AGENTS.md total line count ≤281 (`wc -l ~/.config/opencode/AGENTS.md`)
- [ ] `_index.md` ≤40 lines
- [ ] `open-questions.md` ≤5 lines (seed)
- [ ] Skill loads via `skill(name="forge-memory")` and includes a "Compile Pass" section
- [ ] Running script from a foreign repo creates ZERO files inside that repo

### Must Have
- Hierarchical loading: only `_index.md` always-loaded; topical files on-demand via Read tool
- **Per-project memory ONLY out-of-tree** at `~/.local/share/opencode-forge/{project-key}/`
- **Source/Executable separation**: `tasks/` is the source code; `wiki/` (per-project) and `knowledge/` (global) are the compiled output
- Project-key derivation: (1) git remote URL slugified, (2) git toplevel path slugified, (3) cwd slugified — fallback chain
- **Compile-prep subcommand** outputs a deterministic manifest the AI consumes to perform synthesis
- **Autonomous triggers** in AGENTS.md: session-start runs `autostart`; AI invokes compile workflow when `autostart` reports needs-compile=yes
- Bash-only tooling (no node/python deps, no external libs beyond coreutils + `find` + `date` + `git`)
- Idempotent setup: re-running creation tasks does not corrupt existing content
- Empty-state graceful: "No tasks recorded in this period." for 0 results; no error if dir absent; compile-prep prints "no new entries" on empty
- Hard cap journal entries at 25 lines (enforced by template, AI discipline)
- AGENTS.md additions ≤28 new lines (hard ceiling: total ≤281)
- `.forge/knowledge/_index.md` ≤40 lines
- POSIX-portable bash with documented BSD/GNU branches where required
- ShellCheck-clean
- Script is single source of truth for path resolution — AI never hard-codes paths
- Compile pass writes a `last-compiled: <ISO-timestamp>` marker into `_index.md` after each successful compile

### Must NOT Have (Guardrails)
- ❌ NO files inside `.opencode/`
- ❌ NO files inside foreign repos — out-of-tree only
- ❌ NO test framework (no jest/vitest/bun test/pytest — none + agent QA only)
- ❌ NO node/python/external deps (bash + coreutils + git only)
- ❌ NO LLM API calls inside the bash script — synthesis is performed by the AI agent that consumes the manifest
- ❌ NO backfill automation, NO session-scanning beyond `autostart`'s explicit threshold check
- ❌ NO tagging/categorization metadata beyond defined frontmatter fields
- ❌ NO embedding-based search, NO indexing daemon
- ❌ NO automatic report generation (reports remain on-demand per user choice)
- ❌ NO `--out FILE` flag for compile-prep beyond stdout (keep deterministic)
- ❌ NO cross-referencing system that requires graph data structures
- ❌ NO "knowledge write" skill — knowledge writes are AGENTS.md-instructed during compile pass
- ❌ NO `.forge/` (whole namespace) gitignore rule — must be `.forge/tasks/` exactly
- ❌ NO modifications to foreign repos' `.gitignore`
- ❌ NO commit footer attribution (per AGENTS.md rule)
- ❌ NO Wave-1 task may exceed 50 lines of bash, NO single AGENTS.md edit may exceed 28 added lines
- ❌ NO storage outside `~/.local/share/opencode-forge/` (respect XDG_DATA_HOME if set)
- ❌ NO compile pass that mutates raw journal entries — sources are immutable until pruned

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO (no test runner in this repo, no test scripts in package.json)
- **Automated tests**: NONE — explicit "none + agent QA"
- **Framework**: none
- **TDD**: not applicable

### QA Policy
Every task includes agent-executed QA scenarios. Evidence saved to `.omo/evidence/task-{N}-{scenario-slug}.{ext}`.

- **CLI/Bash tooling** (T6): Use `Bash` tool to invoke `rites/forge-memory.sh` with each subcommand and flag. Capture stdout/stderr.
- **Markdown files** (T1, T2, T4, T5): Use `Read` tool to verify content; use `wc -l` for line-count caps.
- **Skill loading** (T7): Verify frontmatter validity; verify file presence with `ls`.
- **Git behavior** (T3): Use `git status --ignored` to confirm `.forge/tasks/` is ignored, `git ls-files .forge/knowledge/` to confirm knowledge is tracked.
- **AGENTS.md compliance** (T4): Use `wc -l AGENTS.md` to verify ≤281; use `grep -c "Forge Memory"` to verify section presence.
- **Foreign-repo non-pollution** (F3): cd into a temp git repo, run script, run `git status` — must show no new files in that repo.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — 4 tasks parallel, no inter-deps):
├── T1: Migrate KNOWLEDGE.md content → .forge/knowledge/_index.md      [quick]
├── T2: Create 5 topical knowledge seed files                          [quick]
├── T3: Update .gitignore (defense-in-depth `.forge/tasks/`)           [quick]
└── T4: Add AGENTS.md "Forge Memory Protocol" section (≤28 lines,     [quick]
     includes autonomous triggers)

Wave 2 (Core Tooling — 3 tasks parallel, all gated on T1):
├── T5: Replace KNOWLEDGE.md content with redirect note                [quick]
├── T6: Create rites/forge-memory.sh — base subcommands               [unspecified-high]
│       (path/new/prune/report/-h)
└── T7: Create ~/.claude/skills/forge-memory/SKILL.md (base workflow)  [writing]

Wave 3 (Karpathy Compile Pass + Auto Triggers — 3 tasks parallel):
├── T8: Add open-questions.md seed file (global)                       [quick]
├── T9: Extend forge-memory.sh with compile-prep + autostart           [unspecified-high]
└── T10: Update SKILL.md with compile workflow + AGENTS.md autotrigger [writing]
       wiring (extends T4 + T7)

Wave FINAL (4 parallel reviewers, then user okay):
├── F1: Plan compliance audit                                          [oracle]
├── F2: Code quality review (bash + markdown)                          [unspecified-high]
├── F3: Real manual QA (run all subcommands, validate evidence,        [unspecified-high]
│       create sample entry, verify foreign-repo non-pollution,
│       exercise compile-prep + autostart end-to-end)
└── F4: Scope fidelity check                                           [deep]
→ Present results → Get explicit user okay

Critical Path: T1 → T6 → T9 → F1-F4 → user okay
Parallel Speedup: ~55% faster than sequential
Max Concurrent: 4 (Wave 1)
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|---|---|---|
| T1 | none | T5, T6, T8, F3 |
| T2 | none | — |
| T3 | none | F3 (foreign-repo non-pollution check) |
| T4 | none | T10 (extends AGENTS.md), F3 (verify AI sees protocol) |
| T5 | T1 (redirect references _index.md created in T1) | — |
| T6 | T1 (script's `new` produces template defined in T1) | T7 contract, T9 (extends script), F3 |
| T7 | None at execution time — T7 implements interface defined in T6 spec section | T10 (extends skill), F3 (skill loading test) |
| T8 | T1 (sits alongside _index.md in same dir) | F3 (compile pass references it) |
| T9 | T6 (extends script with new subcommands) | F3 (autostart + compile-prep tests) |
| T10 | T4 (extends AGENTS.md protocol), T7 (extends skill) | F3 (autonomous trigger verification) |
| F1-F4 | All implementation tasks (T1-T10) | — |

### Agent Dispatch Summary

| Wave | Tasks | Agent Categories |
|---|---|---|
| 1 | 4 | T1 → `quick`, T2 → `quick`, T3 → `quick`, T4 → `quick` |
| 2 | 3 | T5 → `quick`, T6 → `unspecified-high`, T7 → `writing` |
| 3 | 3 | T8 → `quick`, T9 → `unspecified-high`, T10 → `writing` |
| FINAL | 4 | F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep` |

---

## TODOs

- [x] 1. **Migrate KNOWLEDGE.md content → `.forge/knowledge/_index.md`**

  **What to do**:
  - Create directory `~/.config/opencode/.forge/knowledge/`
  - Create file `~/.config/opencode/.forge/knowledge/_index.md` (≤40 lines total)
  - Content structure:
    - H1: `# Forge Memory — Index (Compiled Wiki TOC)`
    - 1-line "what this is" intro mentioning Karpathy compiler model: raw `tasks/` source → AI compiler → these wiki files (executable)
    - **Last-compiled marker** (literal text the compile pass updates): `<!-- last-compiled: never -->`
    - "## Topics (compiled output)" section: bullet list of 6 topical files (5 + open-questions.md) with 1-line descriptions each
    - "## Source vs. Executable" section: 3-bullet explanation that `tasks/` is raw source, these files are compiled output (mention `last-compiled` marker, mention that AI compiler synthesizes via the compile workflow)
    - "## Journal Entry Template" section: fenced markdown block showing exact frontmatter + body skeleton
    - "## How to Use" section: 3 bullets — "Read this first", "Load topical files on demand via Read", "Run `bash ~/.config/opencode/rites/forge-memory.sh -h` for tooling"
  - Use information from current `KNOWLEDGE.md` as inspiration but STRICTLY constrain to ≤40 lines total
  - The `last-compiled` HTML comment is the canonical marker the compile pass mutates — do not embed it inside any other element

  **Must NOT do**:
  - Do not exceed 40 lines (`wc -l` enforced)
  - Do not duplicate content from current AGENTS.md
  - Do not reference paths inside foreign repos
  - Do not include any code beyond the journal entry template fence
  - Do not omit the `<!-- last-compiled: ... -->` marker — it is required for the compile pass to function

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Trivial single-file creation with strict size constraint
  - **Skills**: []
    - Reason: No skill applies — pure markdown authoring
  - **Skills Evaluated but Omitted**:
    - `customize-opencode`: Does not apply — this is content authoring, not opencode JSON config

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T2, T3, T4)
  - **Blocks**: T5 (redirect targets _index.md), T6 (script template format reference), F3 (sample entry validates against template)
  - **Blocked By**: None — can start immediately

  **References**:

  **Pattern References**:
  - `~/.config/opencode/KNOWLEDGE.md:1-50` — Existing structure to draw from (sections "Overview", "Structure", "Where to Look")
  - `~/.config/opencode/.omo/notepads/sacred-designation-hooks/learnings.md:1-30` — Format example for entry-style markdown blocks

  **API/Type References**: None (markdown only)

  **Test References**: None

  **External References**: None

  **Journal Entry Template** (must be embedded verbatim in `_index.md`):
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
  (Total entry: ≤25 lines including frontmatter and body)

  **Acceptance Criteria**:
  - [ ] File exists: `~/.config/opencode/.forge/knowledge/_index.md`
  - [ ] `wc -l ~/.config/opencode/.forge/knowledge/_index.md` returns ≤40
  - [ ] `grep -c "Journal Entry Template" ~/.config/opencode/.forge/knowledge/_index.md` returns 1
  - [ ] `grep -c "## Topics" ~/.config/opencode/.forge/knowledge/_index.md` returns 1
  - [ ] `grep -c "## Source vs. Executable" ~/.config/opencode/.forge/knowledge/_index.md` returns 1
  - [ ] `grep -cE "<!-- last-compiled:" ~/.config/opencode/.forge/knowledge/_index.md` returns 1
  - [ ] First line is `# Forge Memory — Index (Compiled Wiki TOC)`

  **QA Scenarios**:

  ```
  Scenario: File created with correct structure (happy path)
    Tool: Bash
    Preconditions: ~/.config/opencode/.forge/knowledge/ does not exist initially
    Steps:
      1. Run: ls ~/.config/opencode/.forge/knowledge/_index.md
         Expected: file path printed, exit 0
      2. Run: wc -l ~/.config/opencode/.forge/knowledge/_index.md
         Expected: line count ≤40
      3. Run: head -1 ~/.config/opencode/.forge/knowledge/_index.md
         Expected: "# Forge Memory — Index (Compiled Wiki TOC)"
      4. Run: grep -c "## Journal Entry Template" ~/.config/opencode/.forge/knowledge/_index.md
         Expected: 1
      5. Run: grep -c "## Source vs. Executable" ~/.config/opencode/.forge/knowledge/_index.md
         Expected: 1
      6. Run: grep -cE "<!-- last-compiled:" ~/.config/opencode/.forge/knowledge/_index.md
         Expected: 1
    Expected Result: Index file exists, ≤40 lines, contains all required sections
    Failure Indicators: file missing, line count >40, missing required sections, missing last-compiled marker
    Evidence: .omo/evidence/task-1-index-structure.txt

  Scenario: Line cap edge case (failure path — proves enforcement)
    Tool: Bash
    Preconditions: index file exists
    Steps:
      1. Run: lines=$(wc -l < ~/.config/opencode/.forge/knowledge/_index.md); test "$lines" -le 40 && echo OK || echo FAIL
         Expected: "OK"
    Expected Result: line count gate passes
    Evidence: .omo/evidence/task-1-line-cap.txt
  ```

  **Commit**: YES (groups with T2, T3, T4, T5 in Commit 1)
  - Message: `feat(memory): scaffold .forge/knowledge + AGENTS.md protocol`
  - Files: `.forge/knowledge/_index.md`
  - Pre-commit: `wc -l .forge/knowledge/_index.md` ≤40

- [x] 2. **Create 5 topical knowledge seed files**

  **What to do**:
  - Create the following files, each with ONLY a header + one-line "purpose" comment + empty section header:
    - `~/.config/opencode/.forge/knowledge/learnings.md` — "General accumulated wisdom across sessions."
    - `~/.config/opencode/.forge/knowledge/patterns.md` — "Code patterns, conventions, idioms worth remembering."
    - `~/.config/opencode/.forge/knowledge/gotchas.md` — "Pitfalls, edge cases, things that don't work as expected."
    - `~/.config/opencode/.forge/knowledge/decisions.md` — "Architectural decisions with rationale."
    - `~/.config/opencode/.forge/knowledge/tools.md` — "Tool/library specific knowledge."
  - Each file: 5 lines max (H1 title, blank, italic 1-line purpose, blank, H2 "## Entries" placeholder)
  - Format example for `learnings.md`:
    ```markdown
    # Learnings

    *General accumulated wisdom across sessions. Append entries with date headers.*

    ## Entries
    ```

  **Must NOT do**:
  - Do not exceed 5 lines per file
  - Do not write actual learnings/patterns/etc. yet (these grow organically)
  - Do not add frontmatter (these are flat reference files, not structured entries)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 5 trivially identical file creations
  - **Skills**: []
    - Reason: Pure file creation
  - **Skills Evaluated but Omitted**: None applicable

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T3, T4)
  - **Blocks**: None
  - **Blocked By**: None — can start immediately

  **References**:

  **Pattern References**:
  - `~/.config/opencode/.omo/notepads/sacred-designation-hooks/decisions.md` — Existing 5-line stub pattern (similar simplicity)

  **External References**: None

  **Acceptance Criteria**:
  - [ ] All 5 files exist under `~/.config/opencode/.forge/knowledge/`
  - [ ] Each file ≤5 lines (`for f in ~/.config/opencode/.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md; do wc -l "$f"; done`)
  - [ ] Each file's first line matches `# {Title}` pattern
  - [ ] Each file contains `## Entries` section header

  **QA Scenarios**:

  ```
  Scenario: All 5 seed files exist with correct structure (happy path)
    Tool: Bash
    Preconditions: T1 may or may not have run yet (independent)
    Steps:
      1. Run: ls ~/.config/opencode/.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md
         Expected: all 5 paths printed, exit 0
      2. Run: for f in ~/.config/opencode/.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md; do n=$(wc -l < "$f"); echo "$f $n"; done
         Expected: each line shows count ≤5
      3. Run: for f in ~/.config/opencode/.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md; do head -1 "$f"; done
         Expected: 5 H1 headers
      4. Run: grep -l "## Entries" ~/.config/opencode/.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md | wc -l
         Expected: 5
    Expected Result: 5 files exist, each ≤5 lines, each has H1 + ## Entries
    Failure Indicators: missing file, line count >5, no ## Entries section
    Evidence: .omo/evidence/task-2-seed-files.txt

  Scenario: No content beyond seed (anti-bloat check)
    Tool: Bash
    Preconditions: seed files created
    Steps:
      1. Run: total=$(cat ~/.config/opencode/.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md | wc -l); test "$total" -le 25 && echo OK || echo FAIL
         Expected: "OK" (5 files × 5 lines = 25 max)
    Expected Result: combined seed content stays minimal
    Evidence: .omo/evidence/task-2-no-bloat.txt
  ```

  **Commit**: YES (groups with T1, T3, T4, T5 in Commit 1)
  - Files: `.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md`
  - Pre-commit: each file ≤5 lines

- [x] 3. **Update `.gitignore` (defense-in-depth `.forge/tasks/` rule)**

  **What to do**:
  - Read current `~/.config/opencode/.gitignore`
  - Append a new rule `.forge/tasks/` (with a preceding section comment `# Forge memory — defense-in-depth: tasks should never be in this repo, but ignore them if accidentally created here`)
  - Verify `.forge/knowledge/` remains TRACKED (not accidentally ignored)

  **Must NOT do**:
  - Do not add `.forge/` (whole namespace) — would break knowledge/ tracking
  - Do not add `.forge/knowledge/` to ignore list
  - Do not edit any OTHER repo's `.gitignore`
  - Do not remove existing rules

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single-line append to one file
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T2, T4)
  - **Blocks**: F3 (foreign-repo non-pollution check requires `.gitignore` correctness here)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `~/.config/opencode/.gitignore` — current ignore rules (`node_modules/`, `bun.lock`, `.venv/`, `.opencode/`, `.sisyphus/`, `logs/`, `*.bak`)

  **Acceptance Criteria**:
  - [ ] `~/.config/opencode/.gitignore` contains exact line `.forge/tasks/`
  - [ ] `~/.config/opencode/.gitignore` does NOT contain `.forge/` or `.forge/knowledge/`
  - [ ] `cd ~/.config/opencode && git check-ignore .forge/tasks/probe.md` returns `.forge/tasks/probe.md`
  - [ ] `cd ~/.config/opencode && git check-ignore .forge/knowledge/probe.md` returns nothing (exit 1) — knowledge stays tracked

  **QA Scenarios**:

  ```
  Scenario: gitignore contains correct rule (happy path)
    Tool: Bash
    Preconditions: .gitignore exists in opencode-config repo
    Steps:
      1. Run: grep -c "^\.forge/tasks/$" ~/.config/opencode/.gitignore
         Expected: 1
      2. Run: grep -cE "^\.forge/?$|^\.forge/knowledge/?$" ~/.config/opencode/.gitignore
         Expected: 0
    Expected Result: tasks/ ignored, knowledge/ NOT ignored
    Evidence: .omo/evidence/task-3-gitignore-rule.txt

  Scenario: git check-ignore behavior matches intent
    Tool: Bash
    Preconditions: .gitignore updated
    Steps:
      1. Run: cd ~/.config/opencode && git check-ignore -v .forge/tasks/test-probe.md
         Expected: line including ".forge/tasks/test-probe.md"
      2. Run: cd ~/.config/opencode && git check-ignore -v .forge/knowledge/learnings.md; echo "exit=$?"
         Expected: empty stdout, exit code 1 (not ignored)
    Expected Result: tasks ignored, knowledge tracked
    Failure Indicators: knowledge appears in check-ignore output (would be a critical bug)
    Evidence: .omo/evidence/task-3-check-ignore.txt
  ```

  **Commit**: YES (groups with T1, T2, T4, T5 in Commit 1)
  - Files: `.gitignore`

- [x] 4. **Add AGENTS.md "Forge Memory Protocol" section (≤28 lines, includes autonomous triggers)**

  **What to do**:
  - Read current `~/.config/opencode/AGENTS.md` to find a stable insertion point (after "Forge-World Characteristics" section, before any final closing marker)
  - Append a new section `## Forge Memory Protocol` containing exactly:
    ```markdown
    ## Forge Memory Protocol

    Persistent memory follows Karpathy's compiler model: raw `tasks/*.md` (source) → AI compiler → topical wiki files (executable). All managed by `bash ~/.config/opencode/rites/forge-memory.sh`.

    ### Autonomous Triggers (run without being asked)
    - **On session start (first tool use)**: run `bash ~/.config/opencode/rites/forge-memory.sh autostart`. If output line `needs-compile: yes` appears, immediately invoke skill `forge-memory` and follow the Compile Pass workflow.
    - **After every 5 new journal entries** in current project: same — invoke skill `forge-memory` Compile Pass.

    ### Knowledge (read on demand)
    - Always-loaded TOC: `~/.config/opencode/.forge/knowledge/_index.md` (global) and `<project-wiki>/_index.md` (per-project)
    - Topical files (load via Read when relevant): `learnings.md`, `patterns.md`, `gotchas.md`, `decisions.md`, `tools.md`, `open-questions.md`
    - Topical files are COMPILED OUTPUT — write only via Compile Pass workflow, not raw appends

    ### Task Journal (write on completion)
    - On non-trivial task completion: run `bash ~/.config/opencode/rites/forge-memory.sh new <slug>` — it prints stub path
    - Edit that stub to follow template in `_index.md` (≤25 lines, frontmatter + Goal/Outcome/Notes bullets)
    - Skip if task was trivial (<2 tool calls)
    - Per-project storage is out-of-tree at `~/.local/share/opencode-forge/{project-key}/` — never inside foreign repos
    - Reports/pruning: `bash ~/.config/opencode/rites/forge-memory.sh report 7d` or `prune --dry-run`
    ```
  - That block is ~24 lines. With 1 leading blank line for separation, total addition is ≤25 lines (well under the ≤28 ceiling).

  **Must NOT do**:
  - Do not exceed 28 added lines
  - Do not include implementation details (path resolution, project-key derivation) — those live in the script's `-h`
  - Do not add examples beyond the bullet structure
  - Do not modify any other section of AGENTS.md
  - Do not add commit-attribution language

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single-section markdown append with strict size constraint
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T2, T3)
  - **Blocks**: T10 (extends SKILL.md to mirror autonomous triggers), F3 (verify protocol visible in new session)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `~/.config/opencode/AGENTS.md` — existing structure; locate "Forge-World Characteristics" section as insertion anchor
  - `~/.config/opencode/AGENTS.md` "Tool Usage Constraints" section — example of brief imperative-bullet protocol section

  **Acceptance Criteria**:
  - [ ] `wc -l ~/.config/opencode/AGENTS.md` returns ≤281 (was 253; +28 max)
  - [ ] `grep -c "^## Forge Memory Protocol" ~/.config/opencode/AGENTS.md` returns 1
  - [ ] `grep -c "rites/forge-memory.sh" ~/.config/opencode/AGENTS.md` returns ≥4 (autostart, path/new, report references)
  - [ ] `grep -c "Autonomous Triggers" ~/.config/opencode/AGENTS.md` returns 1
  - [ ] `grep -c "Compile Pass" ~/.config/opencode/AGENTS.md` returns ≥1
  - [ ] `grep -c "session start" ~/.config/opencode/AGENTS.md` returns ≥1
  - [ ] No other section of AGENTS.md modified (verify with `git diff --stat`)

  **QA Scenarios**:

  ```
  Scenario: AGENTS.md size cap respected (happy path)
    Tool: Bash
    Preconditions: AGENTS.md was 253 lines pre-change (verify with git diff)
    Steps:
      1. Run: wc -l ~/.config/opencode/AGENTS.md
         Expected: count ≤281
      2. Run: grep -c "^## Forge Memory Protocol" ~/.config/opencode/AGENTS.md
         Expected: 1
      3. Run: cd ~/.config/opencode && git diff --stat AGENTS.md | tail -1
         Expected: shows "+N" with N ≤28
    Expected Result: section added, total ≤281, addition ≤28 lines
    Failure Indicators: total >281, multiple "Forge Memory Protocol" headers, edits to other sections
    Evidence: .omo/evidence/task-4-agents-size.txt

  Scenario: Section content matches spec
    Tool: Bash
    Preconditions: AGENTS.md updated
    Steps:
      1. Run: awk '/^## Forge Memory Protocol/,/^## /' ~/.config/opencode/AGENTS.md | grep -c "rites/forge-memory.sh"
         Expected: ≥4
      2. Run: awk '/^## Forge Memory Protocol/,/^## /' ~/.config/opencode/AGENTS.md | grep -c "Autonomous Triggers"
         Expected: 1
      3. Run: awk '/^## Forge Memory Protocol/,/^## /' ~/.config/opencode/AGENTS.md | grep -c "autostart"
         Expected: ≥1
      4. Run: awk '/^## Forge Memory Protocol/,/^## /' ~/.config/opencode/AGENTS.md | grep -c "Task Journal"
         Expected: 1
      5. Run: awk '/^## Forge Memory Protocol/,/^## /' ~/.config/opencode/AGENTS.md | grep -c "Compile Pass"
         Expected: ≥1
    Expected Result: section contains autonomous triggers, Knowledge, Task Journal, references the script ≥4 times, mentions Compile Pass ≥1
    Evidence: .omo/evidence/task-4-section-content.txt
  ```

  **Commit**: YES (groups with T1, T2, T3, T5 in Commit 1)
  - Files: `AGENTS.md`
  - Pre-commit: `wc -l AGENTS.md` ≤281

- [x] 5. **Replace `KNOWLEDGE.md` content with redirect note**

  **What to do**:
  - Overwrite `~/.config/opencode/KNOWLEDGE.md` with a minimal redirect:
    ```markdown
    # FORGE KNOWLEDGE BASE

    > This file has been migrated to a hierarchical structure under `.forge/knowledge/`.
    > See `.forge/knowledge/_index.md` for the entry point and topical files.
    >
    > Original generated: 2026-04-20 (preserved in git history).
    ```
  - File must be ≤6 lines total
  - Preserves git history; anyone who looks for `KNOWLEDGE.md` is pointed to the new location

  **Must NOT do**:
  - Do not delete the file (would lose git-blame chain for anyone referencing it externally)
  - Do not exceed 6 lines
  - Do not duplicate content from `_index.md`
  - Do not add a "deprecation date" or any policy beyond the redirect

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T6, T7 — Wave 2 — once T1 completes)
  - **Parallel Group**: Wave 2 (with T6, T7); strictly sequenced after T1 completes
  - **Blocks**: None
  - **Blocked By**: T1

  **References**:

  **Pattern References**:
  - `~/.config/opencode/KNOWLEDGE.md` (current 137-line content) — content to replace, not preserve

  **Acceptance Criteria**:
  - [ ] `wc -l ~/.config/opencode/KNOWLEDGE.md` returns ≤6
  - [ ] `grep -c ".forge/knowledge/_index.md" ~/.config/opencode/KNOWLEDGE.md` returns ≥1
  - [ ] First line is `# FORGE KNOWLEDGE BASE`

  **QA Scenarios**:

  ```
  Scenario: KNOWLEDGE.md is now redirect (happy path)
    Tool: Bash
    Preconditions: T1 has created _index.md
    Steps:
      1. Run: wc -l ~/.config/opencode/KNOWLEDGE.md
         Expected: ≤6
      2. Run: grep -c "_index.md" ~/.config/opencode/KNOWLEDGE.md
         Expected: ≥1
      3. Run: head -1 ~/.config/opencode/KNOWLEDGE.md
         Expected: "# FORGE KNOWLEDGE BASE"
    Expected Result: File reduced to redirect, points to new location
    Failure Indicators: file >6 lines, missing redirect target, file deleted entirely
    Evidence: .omo/evidence/task-5-redirect.txt

  Scenario: Redirect target actually exists
    Tool: Bash
    Preconditions: T1 + T5 done
    Steps:
      1. Run: target=$(grep -oE '\.forge/knowledge/_index\.md' ~/.config/opencode/KNOWLEDGE.md | head -1); test -f ~/.config/opencode/$target && echo OK || echo FAIL
         Expected: "OK"
    Expected Result: redirect points to a real file
    Evidence: .omo/evidence/task-5-target-exists.txt
  ```

  **Commit**: YES (groups with T1, T2, T3, T4 in Commit 1)
  - Files: `KNOWLEDGE.md`

- [x] 6. **Create `rites/forge-memory.sh` with subcommands**

  **What to do**:
  Create executable bash script `~/.config/opencode/rites/forge-memory.sh` with the following subcommands and behavior:

  **Subcommands**:
  - `path` (default subcommand for AI use)
    - Resolves project-key for cwd
    - Prints absolute path to `~/.local/share/opencode-forge/{project-key}/`
    - Creates the directory tree (`knowledge/`, `tasks/`) if missing (`mkdir -p`)
    - Optional flag: `--tasks` (print tasks subdir), `--knowledge` (print per-project knowledge subdir), `--key` (just print resolved key)
  - `new <slug>`
    - Creates a stub journal entry at `<resolved-tasks-dir>/YYYY-MM-DD-HHMMSS-<slug>.md`
    - Stub content: frontmatter (project, started=now, completed=, agents=[], files_touched=[], status=in_progress) + body skeleton (Goal/Outcome/Notes headers)
    - Stub total: ≤25 lines
    - Prints the absolute path of the created stub (so AI knows where to edit)
    - Slug input is sanitized (lowercase, replace non-alphanumeric with `-`, max 40 chars)
  - `prune [--dry-run] [--days N] [--cwd PATH]`
    - Deletes journal entries older than N days (default 14) from the resolved tasks dir
    - With `--dry-run`: lists candidates without deleting
    - Empty/missing dir: prints "0 entries to prune", exits 0
    - Uses `find -mtime` for portability (with macOS/Linux compatibility)
  - `report <timespan> [--cwd PATH]`
    - Timespan formats: `Nd` (e.g., `1d`, `7d`, `14d`), or aliases `today`, `week`, `2weeks`
    - Walks tasks dir, parses frontmatter from each entry within window
    - Output: markdown digest grouped by date, one line per task: `- HH:MM <slug> — <Goal first bullet>` (truncate to 80 chars)
    - Empty: prints "No tasks recorded in this period." and exits 0
  - `-h` / `--help` / no args: prints usage and exits 0

  **Project-Key Derivation**:
  ```bash
  # In order (first match wins):
  # 1. If `git config --get remote.origin.url` succeeds: slugify URL
  #    e.g., "https://github.com/pytorch/pytorch.git" → "github.com_pytorch_pytorch"
  # 2. If `git rev-parse --show-toplevel` succeeds: slugify path
  #    e.g., "/home/u/proj" → "_home_u_proj"
  # 3. Else: slugify pwd
  ```
  Slugify rule: replace `/`, `:`, `@`, `?`, `=`, `&`, whitespace with `_`; strip `https?://`, `.git$`; truncate to 80 chars.

  **Storage Root**:
  Honor `XDG_DATA_HOME` if set: `${XDG_DATA_HOME:-$HOME/.local/share}/opencode-forge/`

  **Script Header**:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```

  **Total Script Size**: Target ≤250 lines, hard cap 300 lines.

  **Must NOT do**:
  - Do not require any tool other than: bash, coreutils (`find`, `date`, `mkdir`, `cat`, `sed`, `awk`, `grep`, `cut`), `git` (optional, with fallback)
  - Do not write to any path outside `${XDG_DATA_HOME:-$HOME/.local/share}/opencode-forge/`
  - Do not install or curl anything
  - Do not echo to stderr unless on `--help` or actual error
  - Do not exit non-zero on empty-state (no-op success)
  - Do not exceed 300 lines
  - Do not use `eval`, do not use unquoted variable expansions in command substitutions
  - Do not use GNU-only flags (`stat -c`, `date -d`) without BSD/macOS branches

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Bash quality matters substantially — security, portability, error handling. Higher-effort domain.
  - **Skills**: []
    - Reason: No skill specifically applies to bash authoring; general bash competence required
  - **Skills Evaluated but Omitted**:
    - `customize-opencode`: applies to opencode JSON config, not bash scripts

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T5, T7 in Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: F3 (manual QA invokes script). T7 implements an interface that mirrors T6's spec — both implement same contract, no runtime block.
  - **Blocked By**: T1 (script needs to know template format from `_index.md`)

  **References**:

  **Pattern References**:
  - `~/.config/opencode/rites/sacred-designation.sh` — existing rite for: shebang, `set -euo pipefail`, idempotency markers, `-q`/`-f` flags, exit-code conventions, structured output
  - `~/.config/opencode/.forge/knowledge/_index.md` (created in T1) — journal entry template format the script's `new` subcommand must produce

  **API/Type References**: None

  **Test References**: None

  **External References**:
  - `find -mtime`: portable across BSD (macOS) and GNU (Linux). Avoid `-mmin` if possible.
  - `date -u +%Y-%m-%dT%H:%M:%SZ`: portable ISO-8601 UTC timestamp
  - `stat -f%m` (BSD) vs `stat -c%Y` (GNU): use `find` to avoid stat entirely if possible
  - XDG Base Directory Spec: `https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html`

  **Acceptance Criteria**:
  - [ ] File exists: `~/.config/opencode/rites/forge-memory.sh` and is executable (`chmod +x`)
  - [ ] `bash rites/forge-memory.sh -h` exits 0 with usage text covering all subcommands
  - [ ] `bash rites/forge-memory.sh path` from `~/.config/opencode/` exits 0 with path under `~/.local/share/opencode-forge/`
  - [ ] `bash rites/forge-memory.sh path --tasks` prints tasks subdir
  - [ ] `bash rites/forge-memory.sh path --knowledge` prints per-project knowledge subdir
  - [ ] `bash rites/forge-memory.sh new test-stub` creates a stub (≤25 lines), prints its path
  - [ ] `bash rites/forge-memory.sh prune --dry-run` exits 0 (empty list when no old entries)
  - [ ] `bash rites/forge-memory.sh report 14d` exits 0 (digest or "No tasks recorded in this period.")
  - [ ] `wc -l rites/forge-memory.sh` returns ≤300
  - [ ] `shellcheck rites/forge-memory.sh` exits 0 (or only warnings, no errors)

  **QA Scenarios**:

  ```
  Scenario: Help and usage (happy path)
    Tool: Bash
    Preconditions: script created, executable
    Steps:
      1. Run: bash ~/.config/opencode/rites/forge-memory.sh -h
         Expected: exit 0, stdout contains "path", "new", "prune", "report"
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh
         Expected: exit 0, prints usage (same as -h)
    Expected Result: usage discoverable
    Evidence: .omo/evidence/task-6-help.txt

  Scenario: Path resolution from a git repo with remote
    Tool: Bash
    Preconditions: invoked from within ~/.config/opencode (a git repo with remote)
    Steps:
      1. Run: bash ~/.config/opencode/rites/forge-memory.sh path
         Expected: prints absolute path under "$HOME/.local/share/opencode-forge/", exit 0
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh path --key
         Expected: prints non-empty slug (the project-key), exit 0
      3. Run: ls -d "$(bash ~/.config/opencode/rites/forge-memory.sh path)"
         Expected: directory exists (mkdir -p worked)
    Expected Result: project-key resolved, dir created
    Evidence: .omo/evidence/task-6-path-resolve.txt

  Scenario: Path resolution outside any git repo (fallback)
    Tool: Bash
    Preconditions: tmp dir without git
    Steps:
      1. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh path --key
         Expected: prints non-empty slug derived from /tmp, exit 0
    Expected Result: graceful fallback to cwd-based key
    Evidence: .omo/evidence/task-6-path-fallback.txt

  Scenario: New stub creation
    Tool: Bash
    Preconditions: script works, path resolves
    Steps:
      1. Run: stub=$(bash ~/.config/opencode/rites/forge-memory.sh new "smoke test 6"); echo "$stub"
         Expected: prints absolute path, exit 0
      2. Run: test -f "$stub" && wc -l "$stub"
         Expected: file exists, ≤25 lines
      3. Run: head -1 "$stub"
         Expected: "---" (frontmatter start)
      4. Run: grep -c "^project:" "$stub"
         Expected: 1
    Expected Result: stub created at correct path, valid frontmatter, ≤25 lines
    Evidence: .omo/evidence/task-6-new-stub.txt

  Scenario: Prune empty/no-op (edge case)
    Tool: Bash
    Preconditions: tasks dir exists with no old entries
    Steps:
      1. Run: bash ~/.config/opencode/rites/forge-memory.sh prune --dry-run
         Expected: exit 0, output indicates 0 candidates
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh prune
         Expected: exit 0, no error
    Expected Result: empty-state graceful
    Evidence: .omo/evidence/task-6-prune-empty.txt

  Scenario: Prune with old fake entry
    Tool: Bash
    Preconditions: a fake old entry exists
    Steps:
      1. Run: tasks=$(bash ~/.config/opencode/rites/forge-memory.sh path --tasks); touch -d "2026-01-01" "$tasks/old-fake.md"
         Expected: file created with old timestamp
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh prune --dry-run | grep -c "old-fake.md"
         Expected: 1
      3. Run: bash ~/.config/opencode/rites/forge-memory.sh prune
         Expected: exit 0
      4. Run: test ! -f "$tasks/old-fake.md" && echo OK
         Expected: "OK" (deleted)
    Expected Result: prune actually removes old entries
    Evidence: .omo/evidence/task-6-prune-real.txt

  Scenario: Report empty timespan (edge case)
    Tool: Bash
    Preconditions: empty tasks dir
    Steps:
      1. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh report 7d
         Expected: exit 0, output contains "No tasks recorded in this period."
    Expected Result: graceful empty digest
    Evidence: .omo/evidence/task-6-report-empty.txt

  Scenario: Report with one entry
    Tool: Bash
    Preconditions: at least one journal entry exists from earlier scenarios
    Steps:
      1. Run: bash ~/.config/opencode/rites/forge-memory.sh report 14d
         Expected: exit 0, output contains markdown headers and at least one task line
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh report 14d | head -1
         Expected: starts with "#" (a markdown header)
    Expected Result: digest format is valid markdown
    Evidence: .omo/evidence/task-6-report-content.txt

  Scenario: Foreign-repo non-pollution (THE critical test)
    Tool: Bash
    Preconditions: clean tmp dir
    Steps:
      1. Run: rm -rf /tmp/forge-foreign-test && mkdir -p /tmp/forge-foreign-test && cd /tmp/forge-foreign-test && git init -q && git config user.email x@x && git config user.name x
         Expected: empty git repo
      2. Run: cd /tmp/forge-foreign-test && bash ~/.config/opencode/rites/forge-memory.sh new probe-foreign
         Expected: prints path under ~/.local/share/opencode-forge/, exit 0
      3. Run: cd /tmp/forge-foreign-test && git status --porcelain | wc -l
         Expected: 0 (NO new files in this repo)
      4. Run: ls /tmp/forge-foreign-test/.forge 2>&1 | grep -c "No such"
         Expected: 1 (no .forge dir created)
    Expected Result: ZERO files in foreign repo, entry stored out-of-tree
    Failure Indicators: any file appears in /tmp/forge-foreign-test/, especially `.forge/` directory — this would be a critical bug
    Evidence: .omo/evidence/task-6-foreign-isolation.txt

  Scenario: ShellCheck passes (quality)
    Tool: Bash
    Preconditions: shellcheck installed (try `which shellcheck`)
    Steps:
      1. Run: command -v shellcheck && shellcheck ~/.config/opencode/rites/forge-memory.sh; exit_code=$?; echo "exit=$exit_code"
         Expected: exit 0 (or skip if shellcheck not installed — note in evidence)
    Expected Result: ShellCheck-clean
    Evidence: .omo/evidence/task-6-shellcheck.txt
  ```

  **Commit**: YES (groups with T7 in Commit 2)
  - Message: `feat(memory): add forge-memory rite + skill`
  - Files: `rites/forge-memory.sh`
  - Pre-commit: `bash rites/forge-memory.sh -h` exits 0; `wc -l rites/forge-memory.sh` ≤300

- [x] 7. **Create `~/.claude/skills/forge-memory/SKILL.md`**

  **What to do**:
  - Create directory: `~/.claude/skills/forge-memory/`
  - Create file: `~/.claude/skills/forge-memory/SKILL.md` with frontmatter and content:

    ```markdown
    ---
    name: forge-memory
    description: Manage the forge memory system — knowledge base + per-project task journal stored out-of-tree. Use when reviewing accumulated learnings, generating timespan reports of recent work, pruning expired journal entries, or checking where memory for the current project lives. Do NOT use for editing AGENTS.md or KNOWLEDGE.md directly.
    ---

    # Forge Memory

    The forge memory system consists of:

    1. **Global knowledge** at `~/.config/opencode/.forge/knowledge/` — git-tracked cross-project wisdom
    2. **Per-project memory** at `~/.local/share/opencode-forge/{project-key}/` — out-of-tree, machine-local

    All operations go through `bash ~/.config/opencode/rites/forge-memory.sh`.

    ## When to Use This Skill

    - User asks for a report of recent work ("what did I do this week", "summarize the last 2 days")
    - User asks to clean up / prune old journal entries
    - You need to find where the current project's memory lives
    - You are about to write a journal entry and need a stub created

    ## When NOT to Use

    - You are reading global knowledge — just `Read` the file directly
    - You are editing AGENTS.md or KNOWLEDGE.md — that's manual config
    - The user wants a deep cross-project analysis — this skill is short digests only

    ## Subcommands

    | Command | Purpose |
    |---|---|
    | `bash rites/forge-memory.sh -h` | Print full usage |
    | `bash rites/forge-memory.sh path [--tasks\|--knowledge\|--key]` | Resolve current project's memory path |
    | `bash rites/forge-memory.sh new <slug>` | Create a journal stub, print its path (then edit it) |
    | `bash rites/forge-memory.sh prune [--dry-run] [--days N]` | Delete entries older than N days (default 14) |
    | `bash rites/forge-memory.sh report <timespan>` | Print markdown digest. `<timespan>` examples: `1d`, `7d`, `14d`, `today`, `week`, `2weeks` |

    ## Examples

    ### "Show me what I did the last 2 days"
    ```bash
    bash ~/.config/opencode/rites/forge-memory.sh report 2d
    ```

    ### "Generate a 1-week report"
    ```bash
    bash ~/.config/opencode/rites/forge-memory.sh report 7d
    ```

    ### "Clean up the journal"
    ```bash
    bash ~/.config/opencode/rites/forge-memory.sh prune --dry-run   # preview
    bash ~/.config/opencode/rites/forge-memory.sh prune              # actually delete
    ```

    ### "Where does my memory live for this project?"
    ```bash
    bash ~/.config/opencode/rites/forge-memory.sh path
    ```

    ## Output Conventions

    - Reports are inline markdown — return them directly to the user
    - The `report` subcommand always returns markdown grouped by date, one line per task
    - Empty timespans return: "No tasks recorded in this period."
    - Foreign-repo isolation: this system NEVER writes inside the current cwd if it's a foreign repo. All writes go to `~/.local/share/opencode-forge/`.
    ```

  - Total file: target ≤80 lines, hard cap 100 lines

  **Must NOT do**:
  - Do not exceed 100 lines
  - Do not duplicate full subcommand documentation from script's `-h` (link to it instead)
  - Do not add executable code beyond bash invocations
  - Do not include the journal entry template — that lives in `_index.md`
  - Do not add a `read more` link to anywhere external

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Markdown documentation authoring with concrete structure
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `customize-opencode`: applies to opencode JSON config, not skill markdown
    - `playwright`: not relevant
    - `frontend-ui-ux`: not relevant

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T5, T6 in Wave 2)
  - **Parallel Group**: Wave 2
  - **Blocks**: F3 (skill loading test)
  - **Blocked By**: None at execution time. T7 documents T6's interface as specified in the **T6 spec section above**, which is the contract both tasks honor — no runtime dependency. Script presence verified at F3.

  **References**:

  **Pattern References**:
  - `~/.claude/skills/investigate-issue/SKILL.md` — frontmatter format (`name:`, `description:`), markdown structure, "When to Use" / "When NOT to Use" / "Tools" sections
  - `~/.claude/skills/xpu-remote-host/SKILL.md` — example of skill with bash-invocation patterns

  **API/Type References**:
  - Script subcommands defined in T6 (above) — skill must accurately reflect those

  **Acceptance Criteria**:
  - [ ] File exists: `~/.claude/skills/forge-memory/SKILL.md`
  - [ ] First 5 lines contain valid frontmatter (`---`, `name: forge-memory`, `description: ...`, `---`)
  - [ ] `wc -l ~/.claude/skills/forge-memory/SKILL.md` returns ≤100
  - [ ] Section headers exist: `## When to Use This Skill`, `## When NOT to Use`, `## Subcommands`, `## Examples`
  - [ ] All 5 subcommands (`-h`, `path`, `new`, `prune`, `report`) referenced
  - [ ] Skill loads via `skill(name="forge-memory")` invocation

  **QA Scenarios**:

  ```
  Scenario: Skill file structure (happy path)
    Tool: Bash
    Preconditions: skill file created
    Steps:
      1. Run: ls ~/.claude/skills/forge-memory/SKILL.md
         Expected: file path printed, exit 0
      2. Run: head -5 ~/.claude/skills/forge-memory/SKILL.md
         Expected: line 1 = "---", line 2 contains "name: forge-memory", line 3 contains "description:", line ≥5 = "---"
      3. Run: wc -l ~/.claude/skills/forge-memory/SKILL.md
         Expected: ≤100
      4. Run: grep -c "## When to Use" ~/.claude/skills/forge-memory/SKILL.md
         Expected: 1
      5. Run: grep -c "## When NOT to Use" ~/.claude/skills/forge-memory/SKILL.md
         Expected: 1
      6. Run: grep -c "## Subcommands" ~/.claude/skills/forge-memory/SKILL.md
         Expected: 1
    Expected Result: file exists, valid frontmatter, all required sections, ≤100 lines
    Failure Indicators: missing file, invalid frontmatter, line count >100, missing sections
    Evidence: .omo/evidence/task-7-skill-structure.txt

  Scenario: Skill references all subcommands
    Tool: Bash
    Preconditions: skill file created
    Steps:
      1. Run: for sub in path new prune report; do grep -c "$sub" ~/.claude/skills/forge-memory/SKILL.md; done
         Expected: each grep returns ≥1
      2. Run: grep -c "rites/forge-memory.sh" ~/.claude/skills/forge-memory/SKILL.md
         Expected: ≥3
    Expected Result: skill content covers all subcommands, references the script ≥3 times
    Evidence: .omo/evidence/task-7-skill-coverage.txt

  Scenario: Skill loads via skill() invocation
    Tool: skill(name="forge-memory")
    Preconditions: skill file present in user-skill registry
    Steps:
      1. Invoke skill: skill(name="forge-memory")
         Expected: skill content returned with `<skill_content name="forge-memory">` block
    Expected Result: skill loadable from agent runtime
    Evidence: .omo/evidence/task-7-skill-load.txt
  ```

  **Commit**: NO (skill lives outside this repo at `~/.claude/skills/`, not committed here)
  - The script (T6) is the only file added in Commit 2 from THIS repo's perspective.

- [x] 8. **Add `open-questions.md` seed file (global compiled-wiki)**

  **What to do**:
  - Create file `~/.config/opencode/.forge/knowledge/open-questions.md` (≤5 lines):
    ```markdown
    # Open Questions

    *Contradictions, unresolved trade-offs, and gaps flagged by the AI compile pass. Each entry should cite source journal entries.*

    ## Entries
    ```
  - This file is appended to by the Compile Pass workflow (T9 + T10) when the AI detects contradictions across journal entries

  **Must NOT do**:
  - Do not exceed 5 lines
  - Do not seed with example entries — file grows organically via compile pass
  - Do not add frontmatter — the file is a flat compiled-output document

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T9, T10 in Wave 3)
  - **Parallel Group**: Wave 3
  - **Blocks**: F3 (compile pass references this file)
  - **Blocked By**: T1 (must exist alongside `_index.md`)

  **References**:

  **Pattern References**:
  - `~/.config/opencode/.forge/knowledge/learnings.md` (created in T2) — same 5-line stub pattern; just a different topic

  **External References**:
  - Karpathy compiler analogy: "open questions" section flags contradictions the compiler couldn't resolve

  **Acceptance Criteria**:
  - [ ] File exists: `~/.config/opencode/.forge/knowledge/open-questions.md`
  - [ ] `wc -l ~/.config/opencode/.forge/knowledge/open-questions.md` returns ≤5
  - [ ] First line is `# Open Questions`
  - [ ] Contains `## Entries` section header
  - [ ] Contains an italicized purpose line mentioning "compile pass" or "compiler"

  **QA Scenarios**:

  ```
  Scenario: open-questions.md exists with correct structure (happy path)
    Tool: Bash
    Preconditions: T1 has run (sibling _index.md exists)
    Steps:
      1. Run: ls ~/.config/opencode/.forge/knowledge/open-questions.md
         Expected: file path printed, exit 0
      2. Run: wc -l ~/.config/opencode/.forge/knowledge/open-questions.md
         Expected: ≤5
      3. Run: head -1 ~/.config/opencode/.forge/knowledge/open-questions.md
         Expected: "# Open Questions"
      4. Run: grep -c "^## Entries" ~/.config/opencode/.forge/knowledge/open-questions.md
         Expected: 1
      5. Run: grep -ciE "compile pass|compiler" ~/.config/opencode/.forge/knowledge/open-questions.md
         Expected: ≥1
    Expected Result: file exists, ≤5 lines, has H1 + ## Entries + compiler reference
    Failure Indicators: missing file, line count >5, missing ## Entries
    Evidence: .omo/evidence/task-8-open-questions.txt
  ```

  **Commit**: YES (groups with T9 in Commit 3 — Karpathy alignment)
  - Message: `feat(memory): add Karpathy compile pass + open-questions tracking`
  - Files: `.forge/knowledge/open-questions.md`

- [x] 9. **Extend `rites/forge-memory.sh` with `compile-prep` and `autostart` subcommands**

  **What to do**:
  Extend the existing `~/.config/opencode/rites/forge-memory.sh` (created in T6) with two new subcommands. Total script size after this task: ≤450 lines.

  **`compile-prep [--scope local|global] [--since SPEC]`**:
  - Resolves cwd's project-key (or global scope if `--scope global`)
  - Reads `<wiki>/_index.md`'s `<!-- last-compiled: TIMESTAMP -->` marker (where `<wiki>` is `~/.local/share/opencode-forge/{key}/wiki/` for local, or `~/.config/opencode/.forge/knowledge/` for global). If marker missing or "never", uses epoch 0.
  - Determines effective `since` time (CLI flag overrides marker)
  - Walks `tasks/*.md` selecting entries with `started:` frontmatter ≥ since
  - For each selected entry: extracts title (first H1 after frontmatter), goal bullet, outcome bullets, file path
  - Lists current topical wiki files with line counts and section headers
  - Outputs to stdout a structured manifest in this exact format:
    ```markdown
    # Compile Manifest

    Scope: local|global
    Project-key: <key or "global">
    Since: <ISO-8601-timestamp>
    Last-compiled: <ISO-8601-timestamp or "never">
    Entries-found: <N>

    ## New Journal Entries

    ### <relative-path-to-entry>
    Title: <H1 text>
    Goal: <first goal bullet, ≤80 chars>
    Outcome: <first outcome bullet, ≤80 chars>

    ### ... (one per entry)

    ## Current Wiki State

    - <topical-file>: <line-count> lines, sections: [<list of H2 headers>]
    - ... (one per topical file)

    ## Synthesis Instructions for AI

    For each new journal entry:
      1. Identify which topical file (if any) it should update
      2. Synthesize claims into the appropriate ## Entries section
      3. Source-reference back to the journal: `(see <relative-path>)`
      4. Flag contradictions to open-questions.md with cited sources
    Update the `<!-- last-compiled: ISO-TIMESTAMP -->` marker in <wiki>/_index.md to current time when done.
    ```
  - Empty case: if no new entries, prints `Entries-found: 0` and exits 0

  **`autostart`**:
  - Runs `prune --auto` (silent unless errors) — uses 14-day default with `find -mtime`
  - Counts journal entries created since last-compile timestamp (read from current scope's `_index.md`)
  - Prints to stdout exactly:
    ```
    pruned: <N>
    new-entries: <N>
    needs-compile: yes|no
    ```
  - `needs-compile: yes` iff `new-entries ≥ 5` OR `last-compiled` marker is missing/"never" AND there is ≥1 entry
  - Exits 0 even on empty state

  **Must also**:
  - Update `path` subcommand: extend `--knowledge` to mean "per-project wiki dir" (`<key>/wiki/`); add `--global-knowledge` for `~/.config/opencode/.forge/knowledge/`
  - Update `path` subcommand: ensure `mkdir -p` covers `<key>/wiki/topics/` and seeds `<key>/wiki/_index.md` with the literal stub `# {project-key} Wiki — Index\n\n<!-- last-compiled: never -->\n` if missing (this is one-time scaffolding, not ongoing wiki content writes)
  - Update `-h` to document `compile-prep` and `autostart`
  - Acceptance for size: `wc -l rites/forge-memory.sh` ≤450 (T6 base ≤300 + ≤150 for these two subcommands and helpers)

  **Must NOT do**:
  - Do not invoke any LLM API from bash — synthesis is the AI's job, the script only provides the manifest
  - Do not modify wiki content from bash beyond the one-time `_index.md` scaffold described above (no synthesis writes, no topic-page mutations, no marker updates from bash — all of those are AI work)
  - Do not auto-trigger compile from autostart — autostart only reports "needs-compile: yes/no"
  - Do not exceed 450 total lines
  - Do not change behavior of existing `path`/`new`/`prune`/`report` beyond the documented `path` extensions

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Bash quality matters; new subcommands include manifest formatting + frontmatter parsing
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None applicable

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T8, T10 in Wave 3)
  - **Parallel Group**: Wave 3
  - **Blocks**: F3 (compile-prep + autostart e2e tests)
  - **Blocked By**: T6 (extends T6's script)

  **References**:

  **Pattern References**:
  - T6 spec section above — current subcommand structure, error handling, project-key resolution
  - `~/.config/opencode/rites/sacred-designation.sh` — idempotency markers, exit codes

  **API/Type References**: None

  **Test References**: None

  **External References**:
  - HTML comment marker pattern (e.g., `<!-- last-compiled: 2026-05-26T10:00:00Z -->`) — standard in static-site generators

  **Acceptance Criteria**:
  - [ ] `bash rites/forge-memory.sh -h` lists `compile-prep` and `autostart`
  - [ ] `bash rites/forge-memory.sh compile-prep` exits 0 (with `Entries-found: N` for some N≥0)
  - [ ] `bash rites/forge-memory.sh compile-prep` outputs sections: `# Compile Manifest`, `## New Journal Entries`, `## Current Wiki State`, `## Synthesis Instructions for AI`
  - [ ] `bash rites/forge-memory.sh autostart` exits 0 with output containing `pruned:`, `new-entries:`, `needs-compile:`
  - [ ] On empty journal: `compile-prep` prints `Entries-found: 0` and `## New Journal Entries` is empty
  - [ ] On empty journal: `autostart` prints `needs-compile: no`
  - [ ] `wc -l rites/forge-memory.sh` returns ≤450
  - [ ] `shellcheck rites/forge-memory.sh` exits 0 (or only warnings, no errors)

  **QA Scenarios**:

  ```
  Scenario: compile-prep on empty journal (edge case)
    Tool: Bash
    Preconditions: clean tasks dir, no entries
    Steps:
      1. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh compile-prep
         Expected: exit 0, output contains "Entries-found: 0"
      2. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh compile-prep | grep -c "^# Compile Manifest"
         Expected: 1
    Expected Result: structured manifest even when empty
    Evidence: .omo/evidence/task-9-compile-empty.txt

  Scenario: compile-prep with one entry (happy path)
    Tool: Bash
    Preconditions: at least one journal entry exists
    Steps:
      1. Run: bash ~/.config/opencode/rites/forge-memory.sh new compile-test-9
         Expected: stub created, path printed
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh compile-prep | grep -c "compile-test-9"
         Expected: ≥1
      3. Run: bash ~/.config/opencode/rites/forge-memory.sh compile-prep | grep -c "## Synthesis Instructions for AI"
         Expected: 1
    Expected Result: manifest includes the new entry and synthesis instructions
    Evidence: .omo/evidence/task-9-compile-with-entry.txt

  Scenario: autostart on empty state (edge case)
    Tool: Bash
    Preconditions: clean tasks dir
    Steps:
      1. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh autostart
         Expected: exit 0
      2. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -c "^needs-compile: no$"
         Expected: 1
      3. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -c "^pruned: 0$"
         Expected: 1
      4. Run: cd /tmp && bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -c "^new-entries: 0$"
         Expected: 1
    Expected Result: autostart reports clean empty state
    Evidence: .omo/evidence/task-9-autostart-empty.txt

  Scenario: autostart triggers compile after 5 entries
    Tool: Bash
    Preconditions: working tasks dir with last-compiled marker = "never"
    Steps:
      1. Run: for i in 1 2 3 4 5; do bash ~/.config/opencode/rites/forge-memory.sh new "trigger-test-$i"; done
         Expected: 5 stubs created
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -c "^needs-compile: yes$"
         Expected: 1
      3. Run: bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -E "^new-entries: [0-9]+" | awk '{print $2}'
         Expected: ≥5
    Expected Result: autostart correctly identifies compile threshold
    Evidence: .omo/evidence/task-9-autostart-trigger.txt

  Scenario: autostart respects last-compiled marker
    Tool: Bash
    Preconditions: tasks dir with entries, per-project wiki/_index.md has recent last-compiled (default autostart scope is local)
    Steps:
      1. Run: wiki=$(bash ~/.config/opencode/rites/forge-memory.sh path --knowledge); now=$(date -u +%Y-%m-%dT%H:%M:%SZ); sed -i.bak "s/<!-- last-compiled: .* -->/<!-- last-compiled: $now -->/" "$wiki/_index.md"
         Expected: per-project marker updated
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -c "^needs-compile: no$"
         Expected: 1
    Expected Result: marker reset prevents premature recompile (autostart's default scope reads same per-project marker)
    Evidence: .omo/evidence/task-9-autostart-marker.txt

  Scenario: compile-prep manifest format (structural)
    Tool: Bash
    Preconditions: any state
    Steps:
      1. Run: out=$(bash ~/.config/opencode/rites/forge-memory.sh compile-prep); echo "$out" | grep -c "^# Compile Manifest"
         Expected: 1
      2. Run: echo "$out" | grep -c "^Scope:"
         Expected: 1
      3. Run: echo "$out" | grep -c "^Project-key:"
         Expected: 1
      4. Run: echo "$out" | grep -c "^Since:"
         Expected: 1
      5. Run: echo "$out" | grep -c "^Last-compiled:"
         Expected: 1
      6. Run: echo "$out" | grep -c "^Entries-found:"
         Expected: 1
      7. Run: echo "$out" | grep -c "^## New Journal Entries"
         Expected: 1
      8. Run: echo "$out" | grep -c "^## Current Wiki State"
         Expected: 1
      9. Run: echo "$out" | grep -c "^## Synthesis Instructions for AI"
         Expected: 1
    Expected Result: all 9 required headers/fields present in manifest
    Evidence: .omo/evidence/task-9-manifest-structure.txt

  Scenario: --scope global flag
    Tool: Bash
    Preconditions: working
    Steps:
      1. Run: bash ~/.config/opencode/rites/forge-memory.sh compile-prep --scope global | grep -c "^Scope: global$"
         Expected: 1
      2. Run: bash ~/.config/opencode/rites/forge-memory.sh compile-prep --scope global | grep -c "^Project-key: global$"
         Expected: 1
    Expected Result: scope flag honored
    Evidence: .omo/evidence/task-9-scope-global.txt
  ```

  **Commit**: YES (groups with T8 in Commit 3)
  - Message: `feat(memory): add Karpathy compile pass + open-questions tracking`
  - Files: `rites/forge-memory.sh`
  - Pre-commit: `bash rites/forge-memory.sh -h` exits 0; `wc -l rites/forge-memory.sh` ≤450; `shellcheck rites/forge-memory.sh` clean

- [x] 10. **Extend `~/.claude/skills/forge-memory/SKILL.md` with Compile Pass workflow**

  **What to do**:
  Extend the SKILL.md (created in T7) with a new section `## Compile Pass Workflow` after `## Subcommands`. Total skill file size after this task: ≤130 lines.

  Add this section verbatim:

  ```markdown
  ## Compile Pass Workflow (Karpathy Alignment)

  Triggered automatically by AGENTS.md autonomous-trigger rules (session start, post-N-entries) OR manually when the user says "compile" or "recompile".

  ### Steps
  1. **Run**: `bash ~/.config/opencode/rites/forge-memory.sh compile-prep [--scope local|global]`
  2. **Read** the printed manifest. Note the `Since:`, `Entries-found:`, and the list of new journal entries.
  3. **For each new journal entry**:
     - Read the entry file (path is in the manifest)
     - Identify the topical file(s) it should update: `learnings.md`, `patterns.md`, `gotchas.md`, `decisions.md`, `tools.md`, or none if not generalizable
     - **Synthesize**: do NOT copy raw bullets — distill the claim into a single dated entry under `## Entries`
     - **Source-reference**: append `(see <relative-path-to-journal-entry>)` to each compiled entry
     - **Flag contradictions**: if this entry contradicts an earlier compiled entry, ALSO append a line to `open-questions.md` with both source refs
  4. **Update last-compiled marker**: replace `<!-- last-compiled: ... -->` in the appropriate `_index.md` (global or per-project) with current ISO-8601 UTC timestamp via `Edit` tool
  5. **Stop** when all new entries are processed. The manifest's `Synthesis Instructions for AI` section restates these steps.

  ### Discipline
  - Be terse: each compiled entry is one bullet, ≤2 lines
  - Preserve source fidelity: never claim something a journal entry doesn't support
  - Do not delete journal entries — sources are immutable until pruned by the 14-day window
  - Skip entries marked `status: abandoned` in frontmatter

  ### Output to User
  After compile pass: print a 1-line summary: "Compiled <N> entries → updated <M> wiki files. <K> contradictions flagged."
  ```

  This adds ~25-30 lines to SKILL.md, pushing total to ~125-130 (within ≤130 cap).

  **Must NOT do**:
  - Do not exceed 130 total lines in SKILL.md
  - Do not duplicate the synthesis instructions verbatim from the bash manifest — link to it via the steps reference
  - Do not introduce new bash invocations beyond `compile-prep` (autostart is described in AGENTS.md, not the skill)
  - Do not modify any other section of SKILL.md beyond appending the new section
  - Do not include code that the AI shouldn't run (bash blocks beyond the documented `compile-prep` invocation)

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Markdown documentation extension with strict structure
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T8, T9 in Wave 3)
  - **Parallel Group**: Wave 3
  - **Blocks**: F3 (compile workflow loadable + executable)
  - **Blocked By**: T7 (extends T7's SKILL.md)

  **References**:

  **Pattern References**:
  - `~/.claude/skills/forge-memory/SKILL.md` (T7 output) — section structure to extend
  - `~/.claude/skills/investigate-issue/SKILL.md` — multi-step workflow section pattern
  - T9 spec section above — manifest format the workflow consumes

  **External References**:
  - Karpathy compiler analogy article (cited in the plan's "Karpathy Compiler Analogy" section)

  **Acceptance Criteria**:
  - [ ] `wc -l ~/.claude/skills/forge-memory/SKILL.md` returns ≤130
  - [ ] `grep -c "^## Compile Pass Workflow" ~/.claude/skills/forge-memory/SKILL.md` returns 1
  - [ ] `grep -c "compile-prep" ~/.claude/skills/forge-memory/SKILL.md` returns ≥2
  - [ ] `grep -c "last-compiled" ~/.claude/skills/forge-memory/SKILL.md` returns ≥1
  - [ ] `grep -c "open-questions" ~/.claude/skills/forge-memory/SKILL.md` returns ≥1
  - [ ] `grep -c "Karpathy" ~/.claude/skills/forge-memory/SKILL.md` returns ≥1
  - [ ] All sections from T7 still present (no accidental deletions)

  **QA Scenarios**:

  ```
  Scenario: Compile Pass section appended (happy path)
    Tool: Bash
    Preconditions: T7 created the base skill file
    Steps:
      1. Run: wc -l ~/.claude/skills/forge-memory/SKILL.md
         Expected: ≤130
      2. Run: grep -c "^## Compile Pass Workflow" ~/.claude/skills/forge-memory/SKILL.md
         Expected: 1
      3. Run: awk '/^## Compile Pass Workflow/,/^## /' ~/.claude/skills/forge-memory/SKILL.md | grep -c "compile-prep"
         Expected: ≥2
      4. Run: awk '/^## Compile Pass Workflow/,/^## /' ~/.claude/skills/forge-memory/SKILL.md | grep -c "Karpathy"
         Expected: ≥1
    Expected Result: section present, ≤130 total lines, references compile-prep + Karpathy
    Evidence: .omo/evidence/task-10-compile-section.txt

  Scenario: T7 sections preserved (regression check)
    Tool: Bash
    Preconditions: T10 done
    Steps:
      1. Run: for header in "## When to Use This Skill" "## When NOT to Use" "## Subcommands"; do grep -c "^$header" ~/.claude/skills/forge-memory/SKILL.md; done
         Expected: each prints 1
    Expected Result: T7 sections still present
    Failure Indicators: any T7 section missing means T10 deleted it accidentally
    Evidence: .omo/evidence/task-10-t7-preserved.txt

  Scenario: Skill loadable
    Tool: skill(name="forge-memory")
    Preconditions: T10 done
    Steps:
      1. Invoke: skill(name="forge-memory")
         Expected: skill content returned, contains "Compile Pass Workflow"
    Expected Result: skill loads successfully and includes compile pass section
    Evidence: .omo/evidence/task-10-skill-load.txt
  ```

  **Commit**: NO (skill lives outside this repo)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`

  **Recommended Agent Profile**:
  - **Subagent Type**: `oracle` (Logis Magna — read-only consultant for plan/spec verification)
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None applicable

  Read this plan end-to-end. For each "Must Have": verify implementation exists. For each "Must NOT Have": search codebase for forbidden patterns — REJECT with file:line if found.

  Verify:
  - All 12 deliverables exist at correct paths (incl. `open-questions.md`)
  - AGENTS.md ≤281 lines
  - `.forge/knowledge/_index.md` ≤40 lines and contains `<!-- last-compiled:` marker
  - `.forge/knowledge/open-questions.md` ≤5 lines
  - `rites/forge-memory.sh` ≤450 lines
  - SKILL.md ≤130 lines
  - All journal entries (if any) ≤25 lines
  - No files placed inside `.opencode/`
  - No node/python deps introduced
  - No LLM API calls inside the bash script
  - `.gitignore` contains exactly `.forge/tasks/` (not `.forge/`)
  - Storage path resolved by script falls under `~/.local/share/opencode-forge/`
  - Compile pass writes do not mutate `tasks/*.md` files
  - Evidence files exist in `.omo/evidence/`

  **Acceptance Criteria** (Bash-verifiable):
  - [ ] `wc -l ~/.config/opencode/AGENTS.md` outputs ≤281
  - [ ] `wc -l ~/.config/opencode/.forge/knowledge/_index.md` outputs ≤40
  - [ ] `grep -cE "<!-- last-compiled:" ~/.config/opencode/.forge/knowledge/_index.md` outputs 1
  - [ ] `wc -l ~/.config/opencode/.forge/knowledge/open-questions.md` outputs ≤5
  - [ ] `wc -l ~/.config/opencode/rites/forge-memory.sh` outputs ≤450
  - [ ] `wc -l ~/.claude/skills/forge-memory/SKILL.md` outputs ≤130
  - [ ] `find ~/.config/opencode/.opencode -newer ~/.config/opencode/.forge/knowledge/_index.md -type f 2>/dev/null | wc -l` outputs 0
  - [ ] `grep -c "^\.forge/tasks/$" ~/.config/opencode/.gitignore` outputs 1
  - [ ] `grep -cE "^\.forge/?$|^\.forge/knowledge/?$" ~/.config/opencode/.gitignore` outputs 0
  - [ ] `grep -cE "(curl |wget |api_key|API_KEY|Authorization:|Bearer )" ~/.config/opencode/rites/forge-memory.sh` outputs 0 (no LLM API calls — narrow pattern won't false-positive on `api.` substrings in comments)
  - [ ] All 12 deliverables present
  - [ ] `find ~/.config/opencode/.omo/evidence -type f -name "task-*.txt" | wc -l` outputs ≥10

  **Output Verdict Format**:
  `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/10] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: bash + markdown quality review requires non-trivial domain expertise across both
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `customize-opencode`: applies to opencode JSON config, not the bash + skill markdown under review

  Review `rites/forge-memory.sh` for:
  - `set -euo pipefail` at top
  - POSIX-compatible `find`, `date`, `stat` usage (or documented GNU/BSD branches)
  - Empty-state handling (compile-prep on 0 entries, autostart on 0 entries)
  - Idempotency (running prune twice = same result; running same `new <slug>` twice = unique filenames via timestamp; running `compile-prep` twice = same manifest if no entries added)
  - Help text on `-h`/`--help` or invalid args; help mentions all 6 subcommands
  - No `eval`, no unquoted variable expansions where injection possible, ShellCheck-clean
  - Project-key fallback chain works
  - **No LLM API calls** in script (no curl/wget/api keys)
  - All 7 markdown files (`_index.md` + 5 topical + open-questions.md): valid syntax, proper structure
  - SKILL.md valid frontmatter, all sections from T7 + T10 present

  **Acceptance Criteria** (Bash-verifiable):
  - [ ] `head -2 ~/.config/opencode/rites/forge-memory.sh | grep -c "set -euo pipefail"` outputs 1
  - [ ] `command -v shellcheck >/dev/null && shellcheck ~/.config/opencode/rites/forge-memory.sh; echo "exit=$?"` outputs `exit=0`
  - [ ] `grep -cE "(^|[^#]).*(eval |\$\([^\"']*\$[^\"']*\))" ~/.config/opencode/rites/forge-memory.sh` outputs 0
  - [ ] `grep -cE "(curl |wget |https?://[^[:space:]\"']*\\?|api_key|API_KEY|Authorization:|Bearer )" ~/.config/opencode/rites/forge-memory.sh` outputs 0 (network/API call detection — narrow enough to allow `https://...` strings appearing inside slugify regexes for git remote URLs)
  - [ ] `wc -l ~/.config/opencode/rites/forge-memory.sh` outputs ≤450
  - [ ] `bash ~/.config/opencode/rites/forge-memory.sh -h | grep -cE "(path|new|prune|report|compile-prep|autostart)"` outputs ≥6
  - [ ] For each topical knowledge file: `for f in ~/.config/opencode/.forge/knowledge/{learnings,patterns,gotchas,decisions,tools,open-questions}.md; do head -1 "$f" | grep -qE "^# "; done; echo "ok"` outputs `ok`
  - [ ] `head -5 ~/.claude/skills/forge-memory/SKILL.md | grep -cE "^name: forge-memory$"` outputs 1

  **Output Verdict Format**:
  `Bash quality [PASS/FAIL] | Markdown quality [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: end-to-end manual execution of every QA scenario including compile pass walkthrough
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `playwright`: not applicable
    - `customize-opencode`: not applicable

  Execute every QA scenario from every task. Cross-task integration tests:
  1. From `~/.config/opencode/`: run `path` — expect path under `~/.local/share/opencode-forge/`
  2. From `~/.config/opencode/`: run `new test-bootstrap` — expect stub created, ≤25 lines, valid frontmatter
  3. Run `report 14d` and `report 1d` — expect digests
  4. Create fake old entry, run `prune --dry-run` and `prune` — verify deletion
  5. **Foreign-repo non-pollution test**: clean tmp, init git, run `new from-foreign` — expect 0 new files in `/tmp/...` repo via `git status --porcelain`
  6. From `/tmp` (no git) → run `path` → expect graceful fallback
  7. Verify skill loads via `skill(name="forge-memory")`
  8. Verify AGENTS.md autonomous triggers visible: open new session, AI references "Forge Memory Protocol" + "autostart"
  9. **Compile pass end-to-end**:
     a. **Record source-immutability checkpoint**: `touch /tmp/forge-before-compile-marker`
     b. Create 5 fake journal entries via `new` (each with goal/outcome bullets)
     c. **Snapshot source hashes**: `tasks_dir=$(bash ~/.config/opencode/rites/forge-memory.sh path --tasks); find "$tasks_dir" -name "*.md" -type f -exec sha256sum {} + | sort > /tmp/forge-tasks-snapshot-before.txt`
     d. Run `autostart` — expect `needs-compile: yes`
     e. Run `compile-prep` — verify manifest contains all 5 entries + synthesis instructions
     f. Manually update `_index.md` last-compiled marker to current time (simulating AI compile completion)
     g. Run `autostart` — expect `needs-compile: no`
     h. **Verify sources unchanged**: `find "$tasks_dir" -name "*.md" -type f -exec sha256sum {} + | sort > /tmp/forge-tasks-snapshot-after.txt && diff /tmp/forge-tasks-snapshot-before.txt /tmp/forge-tasks-snapshot-after.txt && echo IMMUTABLE` — must print `IMMUTABLE` (no diff)
  10. **Compile-prep on empty**: from a fresh project-key (e.g., `/tmp/empty-test`), run `compile-prep` — expect `Entries-found: 0`, structured manifest still present

  Save evidence to `.omo/evidence/final-qa/`.

  **Acceptance Criteria** (Bash-verifiable):
  - [ ] All 10 scenarios pass with PASS verdict in evidence file
  - [ ] `bash ~/.config/opencode/rites/forge-memory.sh path | grep -q "^$HOME/.local/share/opencode-forge/"` exits 0
  - [ ] After scenario 5: `cd /tmp/forge-foreign-test && git status --porcelain | wc -l` outputs 0
  - [ ] After scenario 5: `test ! -d /tmp/forge-foreign-test/.forge` exits 0
  - [ ] After scenario 4: the fake old entry no longer exists
  - [ ] After scenario 9d: `bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -c "^needs-compile: yes$"` outputs 1
  - [ ] After scenario 9g: `bash ~/.config/opencode/rites/forge-memory.sh autostart | grep -c "^needs-compile: no$"` outputs 1
  - [ ] After scenario 9e: `compile-prep` output contains 5 distinct `### ` entry headers
  - [ ] After scenario 9a: `test -e /tmp/forge-before-compile-marker` exits 0 (mtime checkpoint exists)
  - [ ] After scenario 9h: `diff /tmp/forge-tasks-snapshot-before.txt /tmp/forge-tasks-snapshot-after.txt` exits 0 (sources immutable)
  - [ ] `ls ~/.config/opencode/.omo/evidence/final-qa/ | wc -l` outputs ≥10

  **Output Verdict Format**:
  `Scenarios [N/10 pass] | Foreign-repo isolation [PASS/FAIL] | Compile pass [PASS/FAIL] | Edge Cases [N tested] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: scope-creep / unaccounted-changes audit across 10 tasks requires goal-oriented investigative diff analysis
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `git-master`: useful but plain `git diff/log` is sufficient via Bash

  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1:
  - Everything in spec was built (no missing)
  - Nothing beyond spec was built (no creep)
  - "Must NOT do" compliance per task
  - No cross-task contamination
  - No accidental edits to `.opencode/`, `.sisyphus/`, `.omo/notepads/`
  - All "Token Efficiency Strategies" honored (line counts within caps)
  - Out-of-tree storage actually used (no `.forge/` directories created in foreign repos during testing)
  - Compile pass does NOT mutate raw `tasks/*.md` files (sources immutable)

  **Acceptance Criteria** (Bash-verifiable):
  - [ ] `cd ~/.config/opencode && git diff --name-only HEAD~3..HEAD | grep -E "^\.opencode/|^\.sisyphus/|^\.omo/notepads/"` outputs nothing (no accidental edits)
  - [ ] `cd ~/.config/opencode && git diff --name-only HEAD~3..HEAD | wc -l` outputs ≤11 (the 11 expected files: `_index.md` + 5 topical seed files + `open-questions.md` + `.gitignore` + `AGENTS.md` + `KNOWLEDGE.md` + `rites/forge-memory.sh` — skill is outside repo)
  - [ ] `find /tmp/forge-foreign-test -name ".forge" -type d 2>/dev/null | wc -l` outputs 0 (after F3 scenarios)
  - [ ] Token caps verified: AGENTS.md ≤281, _index.md ≤40, each seed file ≤5, open-questions.md ≤5, script ≤450, skill ≤130
  - [ ] No NEW node/python deps: `git diff HEAD~3..HEAD package.json package-lock.json bun.lock 2>/dev/null | grep -cE "^\+\s+\""` outputs 0
  - [ ] After F3 scenario 9h: `diff /tmp/forge-tasks-snapshot-before.txt /tmp/forge-tasks-snapshot-after.txt; echo "exit=$?"` outputs `exit=0` — journal sources hash-identical pre/post compile pass (true source immutability)

  **Output Verdict Format**:
  `Tasks [N/10 compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | Token caps [N/6 met] | Source immutability [PASS/FAIL] | VERDICT`

---

## Commit Strategy

Group commits by wave for atomic rollback:

- **Commit 1** (post-Wave-1 + T5): `feat(memory): scaffold .forge/knowledge + AGENTS.md protocol`
  Files: `.forge/knowledge/_index.md`, `.forge/knowledge/{learnings,patterns,gotchas,decisions,tools}.md`, `.gitignore`, `AGENTS.md`, `KNOWLEDGE.md`
  Pre-commit: `wc -l AGENTS.md` ≤281, `wc -l .forge/knowledge/_index.md` ≤40

- **Commit 2** (post-Wave-2 — T6 only; T7 skill is outside this repo): `feat(memory): add forge-memory rite (base subcommands)`
  Files: `rites/forge-memory.sh` (initial version)
  Pre-commit: `bash rites/forge-memory.sh -h` (must exit 0), `shellcheck rites/forge-memory.sh` clean

- **Commit 3** (post-Wave-3 — T8 + T9; T10 skill extension is outside this repo): `feat(memory): add Karpathy compile pass + open-questions tracking`
  Files: `.forge/knowledge/open-questions.md`, `rites/forge-memory.sh` (extended with `compile-prep` + `autostart`)
  Pre-commit: `wc -l rites/forge-memory.sh` ≤450, `bash rites/forge-memory.sh compile-prep` exits 0, `bash rites/forge-memory.sh autostart` exits 0

- **Commit 4** (post-Final-Wave + user okay, optional): `chore(memory): update README pointer`

Each commit must NOT include AI attribution per AGENTS.md rule.

---

## Success Criteria

### Verification Commands
```bash
# Line-count caps
wc -l ~/.config/opencode/AGENTS.md                              # Expected: ≤281
wc -l ~/.config/opencode/.forge/knowledge/_index.md             # Expected: ≤40
wc -l ~/.config/opencode/.forge/knowledge/open-questions.md     # Expected: ≤5
wc -l ~/.config/opencode/rites/forge-memory.sh                  # Expected: ≤450
wc -l ~/.claude/skills/forge-memory/SKILL.md                    # Expected: ≤130

# Git behavior
cd ~/.config/opencode && git check-ignore .forge/tasks/foo.md   # Expected: .forge/tasks/foo.md
cd ~/.config/opencode && git ls-files .forge/knowledge/         # Expected: 7 files (_index + 5 topical + open-questions)

# Tooling — base subcommands
bash ~/.config/opencode/rites/forge-memory.sh -h                # Expected: usage text covering all 6 subcommands, exit 0
bash ~/.config/opencode/rites/forge-memory.sh path              # Expected: absolute path under ~/.local/share/opencode-forge/
bash ~/.config/opencode/rites/forge-memory.sh new smoke-test    # Expected: stub path, exit 0
bash ~/.config/opencode/rites/forge-memory.sh prune --dry-run   # Expected: list or "0 entries", exit 0
bash ~/.config/opencode/rites/forge-memory.sh report 14d        # Expected: markdown digest or "No tasks", exit 0

# Tooling — Karpathy compile pass (NEW)
bash ~/.config/opencode/rites/forge-memory.sh compile-prep                  # Expected: structured manifest with all required headers, exit 0
bash ~/.config/opencode/rites/forge-memory.sh compile-prep --scope global   # Expected: Scope: global, exit 0
bash ~/.config/opencode/rites/forge-memory.sh autostart                     # Expected: pruned: N / new-entries: N / needs-compile: yes|no, exit 0

# Foreign-repo non-pollution (THE critical test)
mkdir -p /tmp/forge-foreign-test && cd /tmp/forge-foreign-test && git init -q
bash ~/.config/opencode/rites/forge-memory.sh new probe
git status --porcelain                                          # Expected: empty (no new files in this repo)

# No-LLM-API guard (compile pass logic stays in AI, not bash; narrow pattern allows https:// inside slugify regexes for git remotes)
grep -cE "(curl |wget |api_key|API_KEY|Authorization:|Bearer )" ~/.config/opencode/rites/forge-memory.sh  # Expected: 0

# Skill
ls ~/.claude/skills/forge-memory/SKILL.md                       # Expected: file exists
head -5 ~/.claude/skills/forge-memory/SKILL.md                  # Expected: valid frontmatter
grep -c "^## Compile Pass Workflow" ~/.claude/skills/forge-memory/SKILL.md  # Expected: 1
```

### Final Checklist
- [ ] All Plan Quality Gates passed (G1-G5; G5 = Momus VERDICT: OKAY before execution started)
- [ ] All "Must Have" present (verified via commands above)
- [ ] All "Must NOT Have" absent (no `.opencode/` writes, no node/python/LLM-API deps, no test framework, no foreign-repo files, no source mutation)
- [ ] Karpathy compiler-analogy alignment achieved: source/executable separation, compile pass exists, last-compiled markers present
- [ ] Full automation: AI invokes autostart on session start; AI invokes compile pass after threshold (5 entries) or on session start when needed
- [ ] All 4 final-wave reviewers APPROVE
- [ ] User explicitly says "okay" / "approved" / "ship it"
