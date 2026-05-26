#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  FORGE MEMORY — JOURNAL COMPLIANCE CHECK (Stop Hook)
#  ────────────────────────────────────────────────────
#  Fires on every AI Stop event. Checks for compliance gap:
#    completed todos this session  > 0
#    AND journal entries written    = 0
#  → inject_prompt asking AI to write entries before closing.
#
#  Stdin: JSON { session_id, todo_path, cwd, hook_event_name, ... }
#  Stdout: JSON { decision?, inject_prompt? }
#  Exit 0: normal (allow/inject)
#  Exit 2: block (hard block — NOT used here)
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

FORGE_SCRIPT="${HOME}/.config/opencode/rites/forge-memory.sh"

# ── Read stdin ────────────────────────────────────────────────────────────────
stdin_data="$(cat)"

# ── Parse todo_path from stdin ────────────────────────────────────────────────
todo_path="$(printf '%s' "$stdin_data" | grep -o '"todo_path":"[^"]*"' | head -1 | sed 's/"todo_path":"//;s/"//')"

# ── Count completed todos ─────────────────────────────────────────────────────
completed_todos=0
if [[ -n "$todo_path" && -f "$todo_path" ]]; then
  # Count todos with status "completed" in the JSON array
  completed_todos="$(grep -o '"status":"completed"' "$todo_path" 2>/dev/null | wc -l | tr -d ' ')" || completed_todos=0
fi

# No completed todos → nothing to enforce
if [[ "$completed_todos" -eq 0 ]]; then
  printf '{}\n'
  exit 0
fi

# ── Count journal entries written in last 90 minutes ─────────────────────────
new_entries=0
if [[ -x "$FORGE_SCRIPT" ]]; then
  tasks_dir="$("$FORGE_SCRIPT" path --tasks 2>/dev/null)" || tasks_dir=""
  if [[ -n "$tasks_dir" && -d "$tasks_dir" ]]; then
    new_entries="$(find "$tasks_dir" -name "*.md" -newer /proc/1 -mmin -90 -type f 2>/dev/null | wc -l | tr -d ' ')" || new_entries=0
  fi
fi

# ── Compliance gap check ───────────────────────────────────────────────────────
# completed todos exist but zero journal entries written this session
if [[ "$new_entries" -eq 0 ]]; then
  msg="You completed ${completed_todos} task(s) this session but wrote no forge-memory journal entries."
  msg="${msg} Run \`bash ~/.config/opencode/rites/forge-memory.sh new <slug>\` for each non-trivial task"
  msg="${msg} and fill in Goal/Outcome/Notes before this session closes. Skip only if all completed tasks were trivial (<2 tool calls)."
  printf '{"decision":"block","inject_prompt":"%s"}\n' "$msg"
  exit 0
fi

# Entries exist → compliant
printf '{}\n'
exit 0
