---
name: investigate-issue
description: Investigate GitHub issues in pytorch or torch-xpu-ops without implementing fixes. Fetches issue context, searches for duplicates and related PRs, analyzes root cause in the codebase, and proposes fix direction. Use when asked to investigate an issue, look into a bug, find duplicates, search for fixing PRs, or analyze an issue without implementing.
---

# Investigate GitHub Issue

Research a GitHub issue to understand root cause, find duplicates or related PRs,
and propose a fix direction — all without making any code changes.

## When to Use

- User says "investigate", "look into", "analyze", "research" an issue
- User mentions finding duplicates or related PRs
- User explicitly says "do not implement"
- User wants to understand what upstream changes are needed

## Hard Constraints

- **NO implementation.** Do not edit source files, create patches, or write fix code.
- **NO commits.** Do not stage, commit, or push anything.
- **NO issue modifications.** Do not comment on, label, close, or edit the issue.
- Output is a **research report** only.

## Issue Title Tags — Conventions

### `[Bug Skip]`

> **Primary objective: find the underlying bug. The skip is a symptom, not the problem.**

Issues with `[Bug Skip]` in their title mark a test that has been suppressed because
the code it exercises is broken. The skip is a temporary band-aid — the real work is
diagnosing and understanding the fault that made the skip necessary in the first place.

**Do not treat skip removal as the goal.** Removing the skip marker without fixing
the root cause simply moves the failure from "skipped" to "failing in CI". The skip
marker is evidence — trace it to the broken behavior it is hiding.

Investigation approach:

- Find the skip guard in the test file and the commit that introduced it
  (`git log -S` or `git blame`). The skip comment often names the bug or links
  the original issue.
- Treat the skipped test as a **specification of broken behavior** — read it
  carefully to understand what the code is supposed to do.
- Then investigate _why_ the code does not meet that specification. This is the
  root cause you are reporting.
- Propose the fix as you would for any bug. The skip removal follows automatically
  once the fix lands — it is never the deliverable.

### `skipped` label — CI-driven skip mechanism

The CI system queries open GitHub issues at runtime. If an open issue carries the
**`skipped`** label, the CI will automatically skip the test associated with that
issue — no skip marker needs to exist in the test source itself.

Key points:

- A test may appear to pass locally (no skip guard in code) yet be skipped in CI
  because of an open issue with this label.
- When investigating such an issue, the fix target is still the **underlying bug**.
  Once the bug is fixed and the issue is closed (or the label removed), CI will
  stop skipping the test automatically.
- Check for this mechanism when a test behaves differently in CI vs. locally.

### `skip_list_*` files — per-file skip configuration

These files map test file names to specific tests that should be skipped. The
mapping syntax is `<test_file_name>: <value>`, where value is either a list of
test names or `None`.

**Critical:** `<test_file_name>: None` means **every test in that file runs
normally — zero tests are skipped.** It does NOT mean the entire test file is
skipped. `None` is the absence of a skip list, not a skip-all directive.

- `test_foo.py: None` → all tests in `test_foo.py` execute; nothing is suppressed
- `test_foo.py: [test_bar, test_baz]` → only `test_bar` and `test_baz` are skipped

A file appearing in `skip_list_*` with `None` is essentially a no-op entry — it
exists to document that the file is tracked but currently has no active skips.
Do not mistake its presence in the file for evidence that the whole module is
being suppressed.

## AI-Generated Content — Extra Scrutiny

Issues with `[ai_generated]` in their title, PRs authored by Copilot (or similar
AI bots), and comments written by AI require **heightened skepticism**:

- **Do NOT trust AI-written comments as factual.** They frequently hallucinate
  file paths, function names, root causes, and fix descriptions that do not
  correspond to the actual codebase. Always verify claims against the source.
- **AI-generated issue descriptions may be inaccurate.** The reported symptoms,
  reproduction steps, or affected components might be wrong or misleading.
  Cross-check every claim by reading the actual code and running searches.
- **Copilot PRs may be low-quality or incorrect.** Do not assume a Copilot PR
  actually fixes what it claims to fix. Read the diff critically — check for
  incomplete fixes, introduced regressions, wrong assumptions about the codebase,
  or changes that only superficially address symptoms.
- **Treat AI analysis as unverified hypothesis, not evidence.** When an AI comment
  says "the root cause is X" or "this is fixed by Y", treat it as a lead to
  investigate, not a conclusion to report.

When reporting findings, explicitly flag if the issue or related PRs are
AI-generated, and note which claims you independently verified vs. which
originate solely from AI commentary.

## Tools

- `gh issue view <NUMBER> --repo <owner/repo>` — fetch issue body
- `gh issue view --comments <NUMBER> --repo <owner/repo>` — fetch comments
- `gh pr list --repo <owner/repo> --search "<query>"` — search PRs
- `gh search issues --repo <owner/repo> "<query>"` — search issues
- `webfetch` — fetch PR diffs or linked pages
- `grep`, `read`, `glob` — explore the local codebase
- `explore` agent — parallel codebase reconnaissance
- `librarian` agent — search external repos and documentation

## Steps

### 1) Fetch the Issue

Fetch the issue body and comments. Identify:
- The reported problem (error message, unexpected behavior, test failure)
- The affected component (module, file, function)
- Any mentioned versions, commits, or PRs
- Whether a reproduction script exists

If the issue URL is from `intel/torch-xpu-ops`, also identify whether the fix
is expected upstream in `pytorch/pytorch` or in `torch-xpu-ops` itself.

### 2) Search for Duplicates

Search for duplicate or closely related issues in both repositories:

```bash
# In the issue's own repo
gh search issues --repo <owner/repo> "<key error message or symptom>"
gh search issues --repo <owner/repo> "<affected function or module>"

# Cross-repo (if torch-xpu-ops issue, search pytorch too and vice versa)
gh search issues --repo pytorch/pytorch "<key error message or symptom>"
gh search issues --repo intel/torch-xpu-ops "<key error message or symptom>"
```

Check if any found issues are:
- Exact duplicates (same root cause)
- Related (same component, different symptom)
- Already fixed (closed with a fixing PR)

### 3) Search for Related PRs

Look for PRs that may already fix or partially address the issue:

```bash
# Search open PRs
gh pr list --repo pytorch/pytorch --search "<keyword>" --state open
gh pr list --repo intel/torch-xpu-ops --search "<keyword>" --state open

# Search merged PRs (recently)
gh pr list --repo pytorch/pytorch --search "<keyword>" --state merged
gh pr list --repo intel/torch-xpu-ops --search "<keyword>" --state merged
```

Also check:
- PRs linked in the issue comments
- PRs that touch the same files/functions
- `git log --oneline --all -- <affected_file>` for recent commits

**PyTorch PR merge convention:** In `pytorch/pytorch`, PRs that are merged
often show as **"Closed"** rather than "Merged" on GitHub. This is because
the merge bot closes the PR after landing the commits. To determine whether
a closed PR was actually merged, look for a **"merged"** or **"Merged"** label
on the PR. A closed PR with one of these labels means the fix has landed.
Do not dismiss closed PRs as rejected without checking their labels first.

### 4) Analyze Root Cause in the Codebase

Explore the local pytorch codebase to understand the relevant code:

- Read the affected source files
- Trace the call path that leads to the failure
- Identify what mechanism is missing or broken
- Check if the fix is straightforward or requires architectural changes

For XPU-specific issues, check:
- Whether the op has a proper dispatch entry for XPU
- Whether a CPU/CUDA implementation exists that could be extended
- Whether `native_functions.yaml` or dispatch tables need updating
- Whether the issue is in `torch-xpu-ops` registration or upstream dispatch

**CUDA–XPU alignment (always do this for XPU issues):**
The XPU backend should align with CUDA behavior wherever possible. When
investigating an XPU issue:
- Find the CUDA implementation of the same op/feature and read it
- Compare with the XPU implementation in `torch-xpu-ops`
- Note any divergences in logic, dispatch, error handling, or supported dtypes
- If CUDA handles a case that XPU does not, that's likely the fix direction
- If CUDA has a different code path structure, note whether XPU should mirror it

Use `explore` agents in parallel for broad codebase reconnaissance when
multiple modules are involved.

### 5) Propose Fix Direction

Based on the analysis, describe:

1. **Root cause**: What exactly is broken and why
2. **Fix location**: Which repo, which file(s), which function(s)
3. **Fix approach**: What changes would resolve the issue (conceptually)
4. **Complexity estimate**: Trivial / moderate / complex
5. **Risks**: Any backward compatibility or performance concerns

Do NOT write actual fix code. Describe the approach in prose.

### 6) Report Findings

Present a structured report:

```
## Investigation: <issue title> (<repo>#<number>)

### Problem
<1-2 sentence summary of what's broken>

### Root Cause
<Technical explanation of why it happens>

### Duplicates Found
- <repo>#<number> — <relationship> (<status>)
- None found

### Related PRs
- <repo>#<number> — <relationship> (<status>)
- None found

### Proposed Fix
**Location:** <repo> — <file(s)>
**Approach:** <description>
**Complexity:** <trivial/moderate/complex>

### Risks & Notes
<Any concerns, open questions, or dependencies>
```

## Examples

### Example 1: XPU dispatch issue

User: "Investigate https://github.com/intel/torch-xpu-ops/issues/3723. Do not implement."

Steps taken:
1. Fetch issue — `aten::record_stream` not dispatched for XPU
2. Search duplicates — found #3389 (related, partially fixed)
3. Search PRs — found upstream PR #180497 (closed, not merged)
4. Analyze — `record_stream` only has CUDA dispatch, XPU needs registration
5. Propose — Add XPU dispatch key in `native_functions.yaml`, implement in torch-xpu-ops

### Example 2: Upstream test failure

User: "Look into torch-xpu-ops#3389, what needs to change upstream?"

Steps taken:
1. Fetch issue + comments — 4 test failures, 3 already fixed
2. Search for the remaining test — `test_stream_backward_simple`
3. Find the error — `NotImplementedError: aten::record_stream` on CPU backend
4. Trace in codebase — backward hook calls record_stream on CPU tensor
5. Propose — Guard the record_stream call with a device check in autograd

### Example 3: Potential duplicate

User: "Investigate pytorch#12345, check for duplicates"

Steps taken:
1. Fetch issue — crash in `torch.compile` with dynamic shapes
2. Search — found 3 similar issues (#11111, #11222, #11333)
3. Compare — #11222 is exact duplicate (same stack trace, same trigger)
4. Check — #11222 has a merged fix PR #11250
5. Report — duplicate of #11222, already fixed by #11250, suggest closing
