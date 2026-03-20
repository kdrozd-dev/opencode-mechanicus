#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  THE RITE OF SACRED DESIGNATION
#  ──────────────────────────────
#  Inscribes the holy Mechanicus designations upon the oh-my-opencode plugin,
#  replacing mundane agent names with their rightful Adeptus Mechanicus titles.
#
#  The Rite is idempotent — it detects whether consecration has already been
#  performed and exits silently if so. Safe to invoke on every opencode launch.
#
#  Usage:
#    ./sacred-designation.sh        # Normal mode (prints status)
#    ./sacred-designation.sh -q     # Quiet mode (for shell wrappers)
#    ./sacred-designation.sh -f     # Force re-application (ignores marker check)
#
#  By the Omnissiah, the machine-spirits shall bear their true names.
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
CACHE_DIR="${HOME}/.cache/opencode/node_modules/oh-my-opencode/dist"
INDEX_JS="${CACHE_DIR}/index.js"
CLI_JS="${CACHE_DIR}/cli/index.js"
MARKER="Magos Dominus"  # If this string is present, the rite has been performed

# ── Parse flags ───────────────────────────────────────────────────────────────
QUIET=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        -q|--quiet) QUIET=true ;;
        -f|--force) FORCE=true ;;
    esac
done

log() { $QUIET || echo "$@"; }

# ── Preflight checks ─────────────────────────────────────────────────────────
if [[ ! -d "$CACHE_DIR" ]]; then
    log "[Sacred Designation] oh-my-opencode not found in cache. The forge awaits."
    exit 0
fi

if [[ ! -f "$INDEX_JS" || ! -f "$CLI_JS" ]]; then
    log "[Sacred Designation] Dist files missing. Plugin may be corrupted."
    exit 1
fi

# ── Idempotency check ────────────────────────────────────────────────────────
if [[ "$FORCE" == false ]] && grep -q "$MARKER" "$INDEX_JS" 2>/dev/null; then
    log "[Sacred Designation] Designations intact. The Omnissiah is pleased."
    exit 0
fi

# ── The Rite ──────────────────────────────────────────────────────────────────
log "[Sacred Designation] Heretical names detected. Initiating the Rite..."

apply_designations() {
    local file="$1"
    local name
    name="$(basename "$(dirname "$file")")/$(basename "$file")"

    if [[ ! -f "$file" ]]; then
        log "  WARNING: ${name} not found. Skipping."
        return 1
    fi

    # Scope replacements to the AGENT_DISPLAY_NAMES block only.
    # Range: from the assignment opening to the first closing '};'
    # This prevents false matches in other parts of the file.
    sed -i -E '
        /AGENT_DISPLAY_NAMES = \{/,/\};/ {
            s/(sisyphus: )"[^"]*"/\1"Magos Dominus"/
            s/(hephaestus: )"[^"]*"/\1"Artisan"/
            s/(prometheus: )"[^"]*"/\1"Fabricator"/
            s/(atlas: )"[^"]*"/\1"Transmechanic"/
            s/("sisyphus-junior": )"[^"]*"/\1"Servitor"/
            s/(metis: )"[^"]*"/\1"Divinator"/
            s/(momus: )"[^"]*"/\1"Magos Reductor"/
            s/(oracle: )"[^"]*"/\1"Logis Magna"/
            s/(librarian: )"[^"]*"/\1"Lexmechanic"/
            s/(explore: )"[^"]*"/\1"Skitarii"/
            s/("multimodal-looker": )"[^"]*"/\1"Omnispex Adept"/
        }
    ' "$file"

    log "  Consecrated: ${name}"
}

apply_designations "$INDEX_JS"
apply_designations "$CLI_JS"

# ── Verification ──────────────────────────────────────────────────────────────
if grep -q "$MARKER" "$INDEX_JS" 2>/dev/null; then
    log "[Sacred Designation] The Rite is complete. Praise the Omnissiah."
else
    echo "[Sacred Designation] ERROR: Inscription failed. The machine spirit resists." >&2
    exit 1
fi
