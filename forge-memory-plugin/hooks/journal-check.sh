#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  FORGE MEMORY — JOURNAL COMPLIANCE CHECK (Stop Hook)
#  ────────────────────────────────────────────────────
#  Fires on every AI Stop event. Detects non-trivial work via session
#  transcript tool-call count (threshold: ≥3 tool_use entries).
#  Does NOT rely on todos — works even when Dominus skips todo creation.
#
#  Stdin: JSON { session_id, transcript_path, cwd, hook_event_name, ... }
#  Stdout: JSON { decision?, inject_prompt? }
#  Exit 0: allow / inject
#  Exit 2: hard block (not used)
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

FORGE_SCRIPT="${HOME}/.config/opencode/rites/forge-memory.sh"
TRANSCRIPT_DIR="${HOME}/.claude/transcripts"
TOOL_CALL_THRESHOLD=10

# ── Parse stdin ───────────────────────────────────────────────────────────────
stdin_data="$(cat)"

session_id="$(printf '%s' "$stdin_data" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"//')"
cwd="$(printf '%s' "$stdin_data" | grep -o '"cwd":"[^"]*"' | head -1 | sed 's/"cwd":"//;s/"//')"

# ── Count tool calls in session transcript ────────────────────────────────────
tool_calls=0
if [[ -n "$session_id" ]]; then
  transcript="${TRANSCRIPT_DIR}/${session_id}.jsonl"
  if [[ -f "$transcript" ]]; then
    tool_calls="$(grep -c '"type":"tool_use"' "$transcript" 2>/dev/null)" || tool_calls=0
  fi
fi

# Below threshold → trivial session, no enforcement
if [[ "$tool_calls" -lt "$TOOL_CALL_THRESHOLD" ]]; then
  printf '{}\n'
  exit 0
fi

# ── Count journal entries written in last 90 minutes ─────────────────────────
new_entries=0
if [[ -x "$FORGE_SCRIPT" ]]; then
  tasks_dir="$( cd "${cwd:-$HOME}" 2>/dev/null && "$FORGE_SCRIPT" path --tasks 2>/dev/null )" || tasks_dir=""
  if [[ -n "$tasks_dir" && -d "$tasks_dir" ]]; then
    new_entries="$(find "$tasks_dir" -name "*.md" -mmin -90 -type f 2>/dev/null | wc -l | tr -d ' ')" || new_entries=0
  fi
fi

# Entries exist → compliant
if [[ "$new_entries" -gt 0 ]]; then
  printf '{}\n'
  exit 0
fi

# ── Gap detected: inject reminder ─────────────────────────────────────────────
msg="You used ${tool_calls} tools this session but wrote no forge-memory journal entries."
msg="${msg} Run \`bash ~/.config/opencode/rites/forge-memory.sh new <slug>\` for each non-trivial task"
msg="${msg} and fill in Goal/Outcome/Notes before this session closes."
msg="${msg} Skip only if all work was trivial (<3 tool calls total per task)."
printf '{"decision":"block","inject_prompt":"%s"}\n' "$msg"
exit 0
