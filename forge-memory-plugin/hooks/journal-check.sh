#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  FORGE MEMORY — JOURNAL STATUS CHECK
#  ────────────────────────────────────
#  Utility: reports whether recent journal entries exist for a given cwd.
#  Previously used by forge-memory-plugin to inject compliance prompts;
#  journal enforcement is now handled entirely within index.js (auto-write).
#
#  Stdin: JSON { cwd? }
#  Env:   FORGE_TOOL_CALLS (unused, kept for compatibility)
#  Stdout: JSON { new_entries: N }
#  Exit 0: always
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

FORGE_SCRIPT="${HOME}/.config/opencode/rites/forge-memory.sh"

stdin_data="$(cat)"
cwd="$(printf '%s' "$stdin_data" | grep -o '"cwd":"[^"]*"' | head -1 | sed 's/"cwd":"//;s/"//')"

new_entries=0
if [[ -x "$FORGE_SCRIPT" ]]; then
  tasks_dir="$( cd "${cwd:-$HOME}" 2>/dev/null && "$FORGE_SCRIPT" path --tasks 2>/dev/null )" || tasks_dir=""
  if [[ -n "$tasks_dir" && -d "$tasks_dir" ]]; then
    new_entries="$(find "$tasks_dir" -name "*.md" -mmin -90 -type f 2>/dev/null | wc -l | tr -d ' ')" || new_entries=0
  fi
fi

printf '{"new_entries":%s}\n' "$new_entries"
exit 0
