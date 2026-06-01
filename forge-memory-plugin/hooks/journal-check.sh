#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  FORGE MEMORY — JOURNAL COMPLIANCE CHECK (session.idle hook)
#  ────────────────────────────────────────────────────
#  Fires on every opencode `session.idle` event (agent-finished equivalent of
#  Claude Code's Stop hook). Detects non-trivial work via tool-call count
#  (threshold: ≥10 tool calls). Does NOT rely on todos.
#
#  Driven by index.js (opencode ESM plugin), which derives the tool-call count
#  from the opencode client and passes it in. opencode does NOT write Claude
#  Code transcripts (~/.claude/transcripts), so the count is supplied via the
#  FORGE_TOOL_CALLS env var (preferred) or the "tool_calls" stdin field.
#
#  Stdin: JSON { session_id, cwd, tool_calls?, hook_event_name, ... }
#  Env:   FORGE_TOOL_CALLS (overrides stdin tool_calls when set)
#  Stdout: JSON { decision?, inject_prompt? }
#  Exit 0: allow / inject
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

FORGE_SCRIPT="${HOME}/.config/opencode/rites/forge-memory.sh"
TOOL_CALL_THRESHOLD=10

# ── Parse stdin ───────────────────────────────────────────────────────────────
stdin_data="$(cat)"

session_id="$(printf '%s' "$stdin_data" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"//')"
cwd="$(printf '%s' "$stdin_data" | grep -o '"cwd":"[^"]*"' | head -1 | sed 's/"cwd":"//;s/"//')"

# ── Resolve tool-call count ───────────────────────────────────────────────────
# Preferred source: FORGE_TOOL_CALLS env (set by the opencode plugin, derived
# from the live session via the opencode client). Fallback: stdin "tool_calls".
tool_calls=0
if [[ -n "${FORGE_TOOL_CALLS:-}" ]]; then
  tool_calls="${FORGE_TOOL_CALLS}"
else
  stdin_tc="$(printf '%s' "$stdin_data" | grep -o '"tool_calls":[0-9]*' | head -1 | sed 's/"tool_calls"://')"
  [[ -n "$stdin_tc" ]] && tool_calls="$stdin_tc"
fi
# Guard against non-numeric input
[[ "$tool_calls" =~ ^[0-9]+$ ]] || tool_calls=0

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
