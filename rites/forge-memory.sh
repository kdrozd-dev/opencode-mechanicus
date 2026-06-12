#!/usr/bin/env bash
set -euo pipefail
# ══════════════════════════════════════════════════════════════════════════════
#  THE RITE OF FORGE MEMORY
#  ────────────────────────
#  Manages per-project task journals for the opencode-forge.
#  Journals stored out-of-tree:
#    ${XDG_DATA_HOME:-~/.local/share}/opencode-forge/{project-key}/
#
#  Usage:
#    forge-memory.sh path [--tasks|--knowledge|--global-knowledge|--key]
#    forge-memory.sh new <slug>
#    forge-memory.sh prune [--dry-run] [--days N]
#    forge-memory.sh report <timespan>
#    forge-memory.sh compile-prep [--since SPEC]
#    forge-memory.sh generate-inject [local|global]
#    forge-memory.sh autostart
#    forge-memory.sh -h|--help
#
#  By the Omnissiah, all task records shall be preserved.
# ══════════════════════════════════════════════════════════════════════════════

FORGE_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/opencode-forge"

# ── Helpers ────────────────────────────────────────────────────────────────────

# Slugify an arbitrary string: lowercase, replace specials with _, truncate 80.
slugify() {
  local s="$1"
  s="${s#https://}"
  s="${s#http://}"
  s="${s#git@}"
  s="${s%.git}"
  local out
  out=$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]._-' '_')
  out="${out#_}"
  out="${out%_}"
  printf '%s' "${out:0:80}"
}

# Sanitize a user-supplied slug: lowercase, non-alnum → dash, max 40 chars.
sanitize_slug() {
  local out
  out=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '-')
  out="${out:0:40}"
  out="${out%-}"
  printf '%s' "$out"
}

# Derive a stable project key from git metadata or cwd.
# Fallback chain: remote.origin.url → show-toplevel → pwd
get_key() {
  local url top
  if url=$(git config --get remote.origin.url 2>/dev/null); then
    slugify "$url"; return
  fi
  if top=$(git rev-parse --show-toplevel 2>/dev/null); then
    slugify "$top"; return
  fi
  slugify "$(pwd)"
}

# Create journal tree for the given key (idempotent).
ensure_dirs() {
  local key="$1"
  mkdir -p "${FORGE_ROOT}/${key}/tasks" "${FORGE_ROOT}/${key}/wiki/topics"
}

# Convert ISO-8601 timestamp to epoch seconds (Linux -d or BSD -j -f).
ts_to_epoch() {
  date -u -d "$1" +%s 2>/dev/null \
    || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s 2>/dev/null \
    || echo 0
}

# Parse <!-- last-compiled: VALUE --> from an _index.md file.
read_last_compiled() {
  local f="$1" raw val
  [[ -f "$f" ]] || { printf 'never'; return; }
  raw=$(grep -m1 '<!-- last-compiled:' "$f" 2>/dev/null || true)
  [[ -z "$raw" ]] && { printf 'never'; return; }
  val=$(printf '%s' "$raw" | sed 's/.*<!-- last-compiled: *\([^ >]*\) *-->.*/\1/')
  [[ -n "$val" && "$val" != "$raw" ]] && printf '%s' "$val" || printf 'never'
}

# Extract the first H1 title from a journal file (skips YAML frontmatter).
parse_title() {
  local file="$1" in_front=0 lineno=0 line
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    if [[ $lineno -eq 1 && "$line" == "---" ]]; then
      in_front=1; continue
    fi
    if [[ $in_front -eq 1 ]]; then
      [[ "$line" == "---" ]] && in_front=0
      continue
    fi
    if [[ "$line" =~ ^#[[:space:]](.+)$ ]]; then
      printf '%s' "${BASH_REMATCH[1]}"; return
    fi
  done < "$file"
  basename "$file" .md
}

# ── Subcommands ────────────────────────────────────────────────────────────────

cmd_path() {
  local mode="${1:-}"
  local key
  key=$(get_key)
  local wiki_dir="${FORGE_ROOT}/${key}/wiki"
  ensure_dirs "$key"
  if [[ ! -f "${wiki_dir}/_index.md" ]]; then
    printf '# %s Wiki — Index\n\n<!-- last-compiled: never -->\n' "$key" \
      > "${wiki_dir}/_index.md"
  fi
  case "$mode" in
    --key)              printf '%s\n' "$key" ;;
    --tasks)            printf '%s\n' "${FORGE_ROOT}/${key}/tasks" ;;
    --knowledge)        printf '%s\n' "${wiki_dir}" ;;
    --global-knowledge)
                        local global_wiki="${FORGE_ROOT}/_global/wiki"
                        mkdir -p "${global_wiki}/topics"
                        [[ -f "${global_wiki}/_index.md" ]] || \
                          printf '# Global Wiki — Index\n\n<!-- last-compiled: never -->\n' \
                            > "${global_wiki}/_index.md"
                        printf '%s\n' "${global_wiki}" ;;
    "")                 printf '%s\n' "${FORGE_ROOT}/${key}" ;;
    *) printf 'path: unknown option: %s\n' "$mode" >&2; exit 1 ;;
  esac
}

cmd_new() {
  if [[ $# -lt 1 ]]; then
    printf 'new: slug required\n' >&2; exit 1
  fi
  local slug
  slug=$(sanitize_slug "$1")
  local key
  key=$(get_key)
  ensure_dirs "$key"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local date_part="${ts:0:10}"
  local time_part
  time_part=$(date -u +%H%M%S)
  local fpath="${FORGE_ROOT}/${key}/tasks/${date_part}-${time_part}-${slug}.md"
  cat > "$fpath" <<EOF
---
project: ${key}
started: ${ts}
completed:
agents: []
files_touched: []
status: in_progress
---
# ${slug}
## Goal
-
## Outcome
-
## Notes
-
EOF
  printf '%s\n' "$fpath"
}

cmd_prune() {
  local dry_run=false days=14 not_newer_than=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run=true ;;
      --days)    shift; days="$1" ;;
      --not-newer-than) shift; not_newer_than="${1:-}" ;;
      *)         printf 'prune: unknown option: %s\n' "$1" >&2; exit 1 ;;
    esac
    shift
  done
  local key
  key=$(get_key)
  local tasks_dir="${FORGE_ROOT}/${key}/tasks"
  if [[ ! -d "$tasks_dir" ]]; then
    printf 'No tasks directory found. Nothing to prune.\n'
    exit 0
  fi
  local count=0
  if [[ -n "$not_newer_than" ]]; then
    while IFS= read -r f; do
      count=$((count + 1))
      if [[ "$dry_run" == true ]]; then
        printf '[dry-run] would delete: %s\n' "$f"
      else
        rm -- "$f"
        printf 'deleted: %s\n' "$f"
      fi
    done < <(find "$tasks_dir" -name "*.md" -type f -mtime +"$days" ! -newer "$not_newer_than" 2>/dev/null || true)
  else
    while IFS= read -r f; do
      count=$((count + 1))
      if [[ "$dry_run" == true ]]; then
        printf '[dry-run] would delete: %s\n' "$f"
      else
        rm -- "$f"
        printf 'deleted: %s\n' "$f"
      fi
    done < <(find "$tasks_dir" -name "*.md" -type f -mtime +"$days" 2>/dev/null || true)
  fi
  if [[ $count -eq 0 ]]; then
    printf 'No entries older than %s days. Nothing to prune.\n' "$days"
  fi
}

cmd_report() {
  if [[ $# -lt 1 ]]; then
    printf 'report: timespan required (e.g. 7d, today, week)\n' >&2; exit 1
  fi
  local ts_arg="$1"
  local days
  case "$ts_arg" in
    today|0d)   days=1 ;;
    week|7d)    days=7 ;;
    2weeks|14d) days=14 ;;
    *d)         days="${ts_arg%d}" ;;
    *)          printf 'report: unrecognized timespan: %s\n' "$ts_arg" >&2; exit 1 ;;
  esac
  local key
  key=$(get_key)
  local tasks_dir="${FORGE_ROOT}/${key}/tasks"
  if [[ ! -d "$tasks_dir" ]]; then
    printf 'No tasks recorded in this period.\n'
    exit 0
  fi
  local -a files=()
  while IFS= read -r f; do
    [[ -n "$f" ]] && files+=("$f")
  done < <(find "$tasks_dir" -name "*.md" -type f -mtime -"$days" 2>/dev/null | sort || true)
  if [[ ${#files[@]} -eq 0 ]]; then
    printf 'No tasks recorded in this period.\n'
    exit 0
  fi
  printf '# Forge Memory Report — %s (project: %s)\n\n' "$ts_arg" "$key"
  local current_date="" bname fdate title
  for f in "${files[@]}"; do
    bname=$(basename "$f" .md)
    fdate="${bname:0:10}"
    if [[ "$fdate" != "$current_date" ]]; then
      [[ -n "$current_date" ]] && printf '\n'
      printf '## %s\n' "$fdate"
      current_date="$fdate"
    fi
    title=$(parse_title "$f")
    printf '%s\n' "- ${title}"
  done
}

# ── compile-prep subcommand ────────────────────────────────────────────────────

cmd_compile_prep() {
  local since_override=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --since) shift; since_override="${1:-}" ;;
      *) printf 'compile-prep: unknown option: %s\n' "$1" >&2; exit 1 ;;
    esac
    shift
  done
  local key
  key=$(get_key)
  local wiki_dir="${FORGE_ROOT}/${key}/wiki"
  local index_file project_key_display
  cmd_path --knowledge > /dev/null 2>&1
  index_file="${wiki_dir}/_index.md"
  project_key_display="$key"
  local last_compiled
  last_compiled=$(read_last_compiled "$index_file")
  local now_ts now_epoch
  now_ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  now_epoch=$(date -u +%s)
  # Future-timestamp guard: warn if last-compiled is ahead of system clock
  if [[ "$last_compiled" != "never" ]]; then
    local lc_epoch
    lc_epoch=$(ts_to_epoch "$last_compiled")
    if [[ $lc_epoch -gt $now_epoch ]]; then
      local drift=$(( lc_epoch - now_epoch ))
      printf 'WARN: last-compiled (%s) is %ds ahead of system clock (%s) — AI clock drift detected.\n' \
        "$last_compiled" "$drift" "$now_ts" >&2
      printf 'WARN: New entries may be missed. Fix: forge-memory.sh set-compiled. Override: --since %s\n' \
        "$now_ts" >&2
    fi
  fi
  local since_ts
  if [[ -n "$since_override" ]]; then
    since_ts="$since_override"
  elif [[ "$last_compiled" == "never" ]]; then
    since_ts="1970-01-01T00:00:00Z"
  else
    since_ts="$last_compiled"
  fi
  local since_epoch
  since_epoch=$(ts_to_epoch "$since_ts")
  local tasks_dir="${FORGE_ROOT}/${key}/tasks"
  local -a selected=()
  if [[ -d "$tasks_dir" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local sv
      sv=$(grep -m1 '^started:' "$f" 2>/dev/null | sed 's/started: *//' | tr -d ' ' || true)
      [[ -z "$sv" ]] && continue
      local fe
      fe=$(ts_to_epoch "$sv")
      [[ $fe -ge $since_epoch ]] && selected+=("$f")
    done < <(find "$tasks_dir" -name "*.md" -type f 2>/dev/null | sort || true)
  fi
  printf '# Compile Manifest\n\n'
  printf 'Scope: %s\nProject-key: %s\nSince: %s\nLast-compiled: %s\nCurrent-time: %s\nEntries-found: %d\n' \
    "local" "$project_key_display" "$since_ts" "$last_compiled" "$now_ts" "${#selected[@]}"
  printf '\n## New Journal Entries\n'
  if [[ ${#selected[@]} -gt 0 ]]; then
    for f in "${selected[@]}"; do
      local rel title goal outcome insights
      rel="${f#${FORGE_ROOT}/}"
      title=$(parse_title "$f")
      goal=$(grep -A2 '^## Goal' "$f" 2>/dev/null | grep '^-' | head -1 \
             | sed 's/^- *//' | cut -c1-80 || true)
      outcome=$(grep -A2 '^## Outcome' "$f" 2>/dev/null | grep '^-' | head -1 \
                | sed 's/^- *//' | cut -c1-80 || true)
      # Extract ## Insights section (confidence-tagged knowledge lines)
      insights=$(sed -n '/^## Insights$/,/^## /{/^## Insights$/d;/^## /d;p;}' "$f" 2>/dev/null || true)
      printf '\n### %s\nTitle: %s\nGoal: %s\nOutcome: %s\n' \
        "$rel" "$title" "${goal:-(none)}" "${outcome:-(none)}"
      if [[ -n "$insights" ]]; then
        printf 'Insights:\n%s\n' "$insights"
      fi
    done
  fi
  printf '\n## Current Wiki State\n\n'
  local topics_dir="${wiki_dir}/topics"
  local found_wiki=false
  if [[ -d "$topics_dir" ]]; then
    while IFS= read -r wf; do
      [[ -n "$wf" ]] || continue
      found_wiki=true
      local wb wlines sects
      wb=$(basename "$wf")
      wlines=$(wc -l < "$wf" | tr -d ' ')
      sects=$(grep '^## ' "$wf" 2>/dev/null | sed 's/^## //' \
              | tr '\n' ',' | sed 's/,$//' || true)
      printf -- '- %s: %s lines, sections: [%s]\n' "$wb" "$wlines" "$sects"
    done < <(find "$topics_dir" -name "*.md" -type f 2>/dev/null | sort || true)
  fi
  [[ "$found_wiki" == false ]] && printf 'No wiki files yet.\n'
  printf '\n## Synthesis Instructions for AI\n\n'
  printf 'For each new journal entry:\n'
  printf '  1. Identify which topical file (if any) it should update\n'
  printf '  2. Synthesize claims into the appropriate ## Entries section\n'
  printf '  3. Source-reference back to the journal: `(see <relative-path>)`\n'
  printf '  4. Flag contradictions to open-questions.md with cited sources\n'
  printf 'Update the `<!-- last-compiled: ISO-TIMESTAMP -->` marker in <wiki>/_index.md to current time when done.\n'
}

# ── autostart subcommand ───────────────────────────────────────────────────────

cmd_autostart() {
  local key wiki_dir index_file
  key=$(get_key)
  wiki_dir="${FORGE_ROOT}/${key}/wiki"
  index_file="${wiki_dir}/_index.md"
  cmd_path --knowledge > /dev/null 2>&1
  local last_compiled
  last_compiled=$(read_last_compiled "$index_file")
  local since_epoch=0
  if [[ "$last_compiled" != "never" ]]; then
    since_epoch=$(ts_to_epoch "$last_compiled")
    # Future-timestamp guard
    local now_epoch
    now_epoch=$(date -u +%s)
    if [[ $since_epoch -gt $now_epoch ]]; then
      printf 'WARN: last-compiled (%s) is %ds ahead of system clock — AI clock drift detected. Run: forge-memory.sh set-compiled\n' \
        "$last_compiled" $(( since_epoch - now_epoch )) >&2
    fi
  fi
  local tasks_dir="${FORGE_ROOT}/${key}/tasks"
  local new_entries=0
  if [[ -d "$tasks_dir" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local sv
      sv=$(grep -m1 '^started:' "$f" 2>/dev/null | sed 's/started: *//' | tr -d ' ' || true)
      [[ -z "$sv" ]] && continue
      local fe
      fe=$(ts_to_epoch "$sv")
      [[ $fe -ge $since_epoch ]] && new_entries=$((new_entries + 1))
    done < <(find "$tasks_dir" -name "*.md" -type f 2>/dev/null || true)
  fi
  local prune_output pruned=0
  if [[ "$last_compiled" != "never" ]]; then
    prune_output=$(cmd_prune --days 14 --not-newer-than "$index_file" 2>&1) || true
    while IFS= read -r _line; do
      case "$_line" in deleted:*) pruned=$((pruned + 1));; esac
    done <<< "$prune_output"
  fi
  local needs_compile="no"
  if [[ $new_entries -ge 5 ]] \
     || [[ "$last_compiled" == "never" && $new_entries -ge 1 ]]; then
    needs_compile="yes"
  fi
  printf 'pruned: %d\n' "$pruned"
  printf 'new-entries: %d\n' "$new_entries"
  printf 'needs-compile: %s\n' "$needs_compile"
}

cmd_complete() {
  if [[ $# -lt 1 ]]; then
    printf 'complete: file path or slug required\n' >&2; exit 1
  fi
  local target="$1"
  # Accept full path or slug — resolve slug against current project tasks dir
  if [[ ! -f "$target" ]]; then
    local key tasks_dir match
    key=$(get_key)
    tasks_dir="${FORGE_ROOT}/${key}/tasks"
    match=$(find "$tasks_dir" -name "*${target}*" -type f 2>/dev/null | sort | tail -1 || true)
    if [[ -z "$match" ]]; then
      printf 'complete: no file found matching: %s\n' "$target" >&2; exit 1
    fi
    target="$match"
  fi
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  sed -i \
    -e "s|^completed:.*|completed: ${now}|" \
    -e "s|^status: in_progress|status: done|" \
    "$target"
  printf 'completed: %s\n' "$now"
  printf 'file: %s\n' "$target"
}

# ── generate-inject subcommand ─────────────────────────────────────────────────
# Builds inject.md from topic wiki files with whole-entry budget enforcement.
# Priority: gotchas (Tier 1) → patterns (Tier 2) → decisions (Tier 3) → tools (Tier 4)
# Budget: 2000 chars for project, 800 chars for global.

cmd_generate_inject() {
  local scope="${1:-local}"
  local budget
  if [[ "$scope" == "global" ]]; then
    budget=800
  else
    budget=2000
  fi

  local key wiki_dir
  if [[ "$scope" == "global" ]]; then
    wiki_dir="${FORGE_ROOT}/_global/wiki"
    key="_global"
  else
    key=$(get_key)
    wiki_dir="${FORGE_ROOT}/${key}/wiki"
  fi

  local topics_dir="${wiki_dir}/topics"
  local inject_file="${wiki_dir}/inject.md"

  if [[ ! -d "$topics_dir" ]]; then
    printf 'generate-inject: no topics directory at %s\n' "$topics_dir" >&2
    exit 1
  fi

  # Read last-compiled timestamp from _index.md
  local index_file="${wiki_dir}/_index.md"
  local last_compiled
  last_compiled=$(read_last_compiled "$index_file")
  local needs_compile="no"
  # Determine needs-compile from autostart logic (simplified check)
  if [[ "$last_compiled" == "never" ]]; then
    needs_compile="yes"
  fi

  # Extract entries from a topic file (lines starting with "- " under "## Entries")
  # Returns entries one per line.
  extract_entries() {
    local file="$1"
    [[ -f "$file" ]] || return
    local in_entries=false
    while IFS= read -r line; do
      if [[ "$line" == "## Entries" ]]; then
        in_entries=true
        continue
      fi
      # Stop at next heading
      if [[ "$in_entries" == true && "$line" =~ ^##[[:space:]] ]]; then
        break
      fi
      if [[ "$in_entries" == true && "$line" =~ ^-[[:space:]] ]]; then
        printf '%s\n' "$line"
      fi
    done < "$file"
  }

  # Collect entries in priority order
  local -a tier1=() tier2=() tier3=() tier4=()

  while IFS= read -r entry; do
    [[ -n "$entry" ]] && tier1+=("$entry")
  done < <(extract_entries "${topics_dir}/gotchas.md")

  while IFS= read -r entry; do
    [[ -n "$entry" ]] && tier2+=("$entry")
  done < <(extract_entries "${topics_dir}/patterns.md")

  while IFS= read -r entry; do
    [[ -n "$entry" ]] && tier3+=("$entry")
  done < <(extract_entries "${topics_dir}/decisions.md")

  while IFS= read -r entry; do
    [[ -n "$entry" ]] && tier4+=("$entry")
  done < <(extract_entries "${topics_dir}/tools.md")

  # Build inject content with whole-entry budget enforcement
  local current_size=0
  local -a selected_gotchas=() selected_patterns=() selected_decisions=() selected_tools=()
  local entry_len

  # Tier 1: Gotchas
  for entry in "${tier1[@]}"; do
    entry_len=${#entry}
    if (( current_size + entry_len + 1 > budget )); then
      break
    fi
    selected_gotchas+=("$entry")
    current_size=$((current_size + entry_len + 1))
  done

  # Tier 2: Patterns
  for entry in "${tier2[@]}"; do
    entry_len=${#entry}
    if (( current_size + entry_len + 1 > budget )); then
      break
    fi
    selected_patterns+=("$entry")
    current_size=$((current_size + entry_len + 1))
  done

  # Tier 3: Decisions
  for entry in "${tier3[@]}"; do
    entry_len=${#entry}
    if (( current_size + entry_len + 1 > budget )); then
      break
    fi
    selected_decisions+=("$entry")
    current_size=$((current_size + entry_len + 1))
  done

  # Tier 4: Tools
  for entry in "${tier4[@]}"; do
    entry_len=${#entry}
    if (( current_size + entry_len + 1 > budget )); then
      break
    fi
    selected_tools+=("$entry")
    current_size=$((current_size + entry_len + 1))
  done

  # If nothing to inject, remove stale inject.md and exit
  local total_entries=$(( ${#selected_gotchas[@]} + ${#selected_patterns[@]} + ${#selected_decisions[@]} + ${#selected_tools[@]} ))
  if [[ $total_entries -eq 0 ]]; then
    rm -f "$inject_file"
    printf 'generate-inject: no entries to inject (removed stale inject.md)\n'
    exit 0
  fi

  # Write inject.md
  {
    printf '<!-- forge-inject: project=%s compiled=%s needs-compile=%s -->\n\n' \
      "$key" "$last_compiled" "$needs_compile"

    if [[ ${#selected_gotchas[@]} -gt 0 ]]; then
      printf '## Critical Gotchas\n'
      for entry in "${selected_gotchas[@]}"; do
        printf '%s\n' "$entry"
      done
      printf '\n'
    fi

    if [[ ${#selected_patterns[@]} -gt 0 ]]; then
      printf '## Blessed Patterns\n'
      for entry in "${selected_patterns[@]}"; do
        printf '%s\n' "$entry"
      done
      printf '\n'
    fi

    if [[ ${#selected_decisions[@]} -gt 0 ]]; then
      printf '## Key Decisions\n'
      for entry in "${selected_decisions[@]}"; do
        printf '%s\n' "$entry"
      done
      printf '\n'
    fi

    if [[ ${#selected_tools[@]} -gt 0 ]]; then
      printf '## Tools\n'
      for entry in "${selected_tools[@]}"; do
        printf '%s\n' "$entry"
      done
      printf '\n'
    fi
  } > "$inject_file"

  printf 'generate-inject: %d entries (%d chars) → %s\n' \
    "$total_entries" "$current_size" "$inject_file"
}

cmd_set_compiled() {
  local key wiki_dir index_file now
  key=$(get_key)
  wiki_dir="${FORGE_ROOT}/${key}/wiki"
  index_file="${wiki_dir}/_index.md"
  [[ -f "$index_file" ]] || { printf 'set-compiled: _index.md not found at %s\n' "$index_file" >&2; exit 1; }
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  sed -i "s|<!-- last-compiled:.*-->|<!-- last-compiled: ${now} -->|" "$index_file"
  printf 'last-compiled set to: %s\n' "$now"
}

usage() {
  cat <<'USAGE'
The Rite of Forge Memory — per-project task journal manager

Usage:
  forge-memory.sh path [--tasks|--knowledge|--global-knowledge|--key]
  forge-memory.sh new <slug>
  forge-memory.sh complete <path-or-slug>
  forge-memory.sh prune [--dry-run] [--days N] [--not-newer-than FILE]
  forge-memory.sh report <timespan>
  forge-memory.sh compile-prep [--since SPEC]
  forge-memory.sh generate-inject [local|global]
  forge-memory.sh set-compiled
  forge-memory.sh autostart
  forge-memory.sh -h|--help

Subcommands:
  path [--tasks|--knowledge|--global-knowledge|--key]
      Resolve project key and print absolute path. Creates the tree if absent.
        (no flag)          project root: {forge-root}/{key}/
        --key              project key only
        --tasks            tasks subdirectory path
        --knowledge        per-project wiki dir: {forge-root}/{key}/wiki/
        --global-knowledge global knowledge: {forge-root}/_global/wiki/

  new <slug>
      Create a journal stub in the tasks directory.
      Slug is sanitized (lowercase, non-alnum→dash, max 40 chars).
      Prints the absolute path of the created file.
      Sets started: to real system clock — do NOT overwrite this field.

  complete <path-or-slug>
      Write the real system clock into completed: and set status: done.
      Always use this instead of hand-writing completed: to prevent AI clock drift.
      Accepts full path or partial slug (matches latest file containing the slug).

  prune [--dry-run] [--days N] [--not-newer-than FILE]
      Delete journal entries older than N days (default: 14).
      --dry-run  list files without deleting; exit 0 if nothing found.
      --not-newer-than FILE  only delete entries not newer than FILE.

  report <timespan>
      Print a markdown digest of recent tasks, grouped by date.
      Timespan formats: Nd | today (=0d) | week (=7d) | 2weeks (=14d)

  compile-prep [--since SPEC]
      Emit a structured manifest of new journal entries since last compile.
      Uses the local per-project wiki. --since overrides the marker.
      Output includes Current-time (system clock) to detect AI clock drift.
      Warns to stderr if last-compiled marker is ahead of system clock.

  generate-inject [local|global]
      Build inject.md from topic wiki files for plugin auto-injection.
      Enforces whole-entry budget (2000 chars local, 800 chars global).
      Priority: gotchas → patterns → decisions → tools.
      No entry is ever truncated — budget stops at entry boundaries.
      Should be run after each compile pass.

  set-compiled
      Write the real system clock to the last-compiled marker in _index.md.
      Always use this (never Edit the marker manually) to prevent AI clock drift.

  autostart
      Count new entries, then prune already-compiled entries older than 14d.
      Prints: pruned: N / new-entries: N / needs-compile: yes|no

Storage: ${XDG_DATA_HOME:-~/.local/share}/opencode-forge/{project-key}/
  tasks/        — journal stubs (*.md)
  wiki/         — compiled wiki root (_index.md + topics/)
  wiki/topics/  — topical wiki files (AI-generated)
USAGE
}

# ── Dispatch ───────────────────────────────────────────────────────────────────
case "${1:-}" in
  path)            cmd_path "${@:2}" ;;
  new)             cmd_new "${@:2}" ;;
  complete)        cmd_complete "${@:2}" ;;
  prune)           cmd_prune "${@:2}" ;;
  report)          cmd_report "${@:2}" ;;
  compile-prep)    cmd_compile_prep "${@:2}" ;;
  generate-inject) cmd_generate_inject "${@:2}" ;;
  set-compiled)    cmd_set_compiled ;;
  autostart)       cmd_autostart ;;
  -h|--help|"")    usage; exit 0 ;;
  *)               printf 'Unknown subcommand: %s\n' "$1" >&2
                   usage >&2; exit 1 ;;
esac
