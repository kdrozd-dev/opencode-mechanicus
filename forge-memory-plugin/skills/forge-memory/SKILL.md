---
name: forge-memory
description: Manage the forge memory system — knowledge base + per-project task journal stored out-of-tree. Use when reviewing accumulated learnings, generating timespan reports of recent work, pruning expired journal entries, or checking where memory for the current project lives. Do NOT use for editing AGENTS.md or KNOWLEDGE.md directly.
---

# Forge Memory

The forge memory system consists of (1) Global knowledge at ~/.local/share/opencode-forge/_global/wiki/ — machine-local, manually curated cross-project wisdom, (2) Per-project memory at ~/.local/share/opencode-forge/{project-key}/ — out-of-tree, machine-local. All operations go through `bash ~/.config/opencode/rites/forge-memory.sh`.

## When to Use This Skill
- User asks for a report of recent work.
- User asks to prune or clean up the journal.
- Finding the path where project memory is stored.
- Creating a new journal entry stub after task completion.

## When NOT to Use
- Reading global knowledge scrolls (use Read tool directly).
- Editing AGENTS.md or project-specific configuration.
- Performing deep cross-project wisdom analysis.

## Subcommands
| Command | Purpose |
|---------|---------|
| `-h` | Display the sacred help text. |
| `path` | Reveal the out-of-tree memory path for the current project. |
| `new` | Generate a new task journal entry stub. Sets `started:` to real system clock — do NOT overwrite. |
| `complete` | Write real system clock into `completed:` and set `status: done`. Always use instead of hand-writing. |
| `prune` | Remove expired journal entries beyond the retention limit. |
| `report`| Generate a summary of work for a specific timespan (e.g., 7d). |
| `compile-prep` | Output structured manifest of new entries for AI compilation (per-project). |
| `generate-inject` | Build inject.md from topic wiki files for plugin auto-injection. Run after each compile pass. |
| `set-compiled` | Write real system clock to last-compiled marker in _index.md. Never hand-write this value. |
| `autostart` | Run maintenance: prune + count new entries + check compile status. |

## Examples
- **"Show me what I did the last 2 days"**
  `bash ~/.config/opencode/rites/forge-memory.sh report 2d`
- **"Generate a 1-week report"**
  `bash ~/.config/opencode/rites/forge-memory.sh report 7d`
- **"Clean up the journal"**
  `bash ~/.config/opencode/rites/forge-memory.sh prune --dry-run` then `prune`
- **"Where does my memory live?"**
  `bash ~/.config/opencode/rites/forge-memory.sh path`

## Output Conventions
- Reports are delivered as inline markdown in the data-link.
- Tasks are grouped by date with one-line summaries.
- If no records exist, reports return "No tasks recorded in this period."
- Isolation is guaranteed; no journal data is ever stored inside foreign repositories.

## Compile Pass Workflow (Karpathy Alignment)

Triggered automatically by AGENTS.md autonomous-trigger rules (session start, post-N-entries) OR manually when the user says "compile" or "recompile".

### Steps
1. **Run**: `bash ~/.config/opencode/rites/forge-memory.sh compile-prep [--since SPEC]`
2. **Read** the printed manifest. Note the `Since:`, `Entries-found:`, and the list of new journal entries.
3. **For each new journal entry**:
   - Read the entry file (path is in the manifest)
   - Identify the topical file(s) it should update: `gotchas.md`, `patterns.md`, `decisions.md`, `tools.md`, or none if not generalizable
   - **Synthesize**: do NOT copy raw bullets — distill the claim into a single dated entry under `## Entries`
   - **Source-reference**: append `(see <relative-path-to-journal-entry>)` to each compiled entry
   - **Confidence routing** — route `## Insights` lines by their `[confidence:X]` tag:
     - `confidence:high` or `confidence:verified` → any topical wiki file
     - `confidence:medium` → wiki file with inline note `*(needs verification)*`
     - `confidence:tentative` or `[heuristic]` → `open-questions.md` ONLY, never to patterns/gotchas/decisions
     - No confidence tag → treat as `medium`
   - **Supersession**: if this entry contradicts an existing wiki claim AND the new confidence ≥ existing: supersede with a note `*(supersedes prior entry YYYY-MM-DD)*`. If new confidence < existing: route to `open-questions.md` instead.
   - **Flag contradictions**: if this entry contradicts an earlier compiled entry without clear supersession, ALSO append a line to `open-questions.md` with both source refs
4. **Update last-compiled marker**: run `bash ~/.config/opencode/rites/forge-memory.sh set-compiled` — this writes the real system clock atomically, preventing AI clock-drift issues. Do NOT use the `Edit` tool to write this timestamp manually.
5. **Stop** when all new entries are processed. The manifest's `Synthesis Instructions for AI` section restates these steps.

### Discipline
- Be terse: each compiled entry is one bullet, ≤2 lines
- Preserve source fidelity: never claim something a journal entry doesn't support
- Do not delete journal entries — sources are immutable until pruned by the 14-day window
- Skip entries marked `status: abandoned` in frontmatter
- `status: auto-draft` entries are valid source material — the auto-extraction may be imprecise, apply extra skepticism

### Output to User
After compile pass: print a 1-line summary: "Compiled <N> entries → updated <M> wiki files. <K> contradictions flagged."

---

## Agent Protocol (Autonomous Behavior Rules)

### Autonomous Triggers (run without being asked)

- **On session start (first tool use)**: run `bash ~/.config/opencode/rites/forge-memory.sh autostart`. If output includes `needs-compile: yes` and no auto-compile toast appeared, dispatch Compile Pass as a **subtask** (fallback only — plugin normally handles this automatically): *"Run the forge-memory Compile Pass. First run `bash ~/.config/opencode/rites/forge-memory.sh path --key` to get the project key. Load skill forge-memory, follow the Compile Pass workflow steps exactly, write all wiki topic files, update _index.md last-compiled marker. Return: 'Compiled N entries → updated M wiki files. K contradictions flagged.' Nothing else."*
- **On session start**: Read `$(bash ~/.config/opencode/rites/forge-memory.sh path --global-knowledge)/_index.md` (global) AND the per-project `$(bash ~/.config/opencode/rites/forge-memory.sh path --knowledge)/_index.md` if it exists. Mandatory, not optional.
- **Compile Pass is automated**: The plugin triggers compile after journaling when ≥5 new entries exist. Manual dispatch is only needed as fallback if the plugin fails.

### Knowledge (proactive — load before acting)

- **Before any implementation task**: Read `patterns.md` and `gotchas.md` for the current project wiki. Check `decisions.md` for prior decisions.
- **Before debugging**: Read `gotchas.md` first — known pitfalls are recorded there.
- **Before using a tool/library**: Read `tools.md` for accumulated tool-specific knowledge.
- **When something seems surprising or wrong**: Read `open-questions.md` — contradictions are flagged there.
- Topical files: `$(forge-memory.sh path --knowledge)/topics/` (per-project) or `$(forge-memory.sh path --global-knowledge)/topics/` (global).
- Topical files are COMPILED OUTPUT — write only via Compile Pass, not raw appends.

### Knowledge Markers (emit at response end when relevant)

```
> 🔵 forge:decision: Chose X over Y because Z
> 🟡 forge:gotcha: BSD date lacks -d flag; use date -j -f instead
> 🟢 forge:pattern: Always wrap client.session.prompt() in try/catch — throws on timeout
> 🟣 forge:open_question: Why does session.abort() not clean up child session state?
> 🟠 forge:retract: the wrong claim from earlier, verbatim or close paraphrase
```

Rules: ≤3–5 markers per session, emit at END of response only. Plugin harvests automatically.

**If corrections occurred during session**, emit session-summary blockquote (supersedes all individual markers):
```
> forge:session-summary
> decision: final correct choice and why
> gotcha: confirmed pitfall (post-correction)
> pattern: confirmed reusable technique
> retracted: the earlier wrong claim
> confidence: high
```

### Task Journal (MANDATORY after ≥3 tool calls)

1. Run `bash ~/.config/opencode/rites/forge-memory.sh new <slug>` — prints stub path.
2. `Read` the stub, `Edit` to fill Goal / Outcome / Notes (≤25 lines total). Do NOT manually write `started:` or `completed:` timestamps.
3. Run `bash ~/.config/opencode/rites/forge-memory.sh complete <path>` — sets `completed:` and `status: done`. Never hand-write these values.
4. Slug format: `short-task-desc` (e.g. `fix-memory-hook`) — script auto-prepends date/time.

**Enforcement rules:**
- Plugin auto-drafts at ≥5 tool calls (fallback only) — manual journal for ≥3 tool calls yields richer entries.
- Skip manual write ONLY if <3 tool calls total.
- One entry per logical task — batch multiple small fixes into one entry.
- Per-project storage: `~/.local/share/opencode-forge/{project-key}/` — never inside foreign repos.
- If `XDG_DATA_HOME` non-default: update `opencode.json` permission `external_directory` to match.
- After every 5 new entries: plugin auto-compiles. Manual compile only needed as fallback if plugin fails.
- Reports/pruning: `bash ~/.config/opencode/rites/forge-memory.sh report 7d` or `prune --dry-run`.
