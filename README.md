# The Forge of the Omnissiah

> *"From the weakness of the mind, Omnissiah save us. From the lies of the Antipath, circuit preserve us. From the rage of the Beast, iron protect us. From the temptations of the Fleshlord, silica cleanse us."*

An [OpenCode](https://opencode.ai) configuration that transforms your AI coding assistant into a devoted servant of the Adeptus Mechanicus. Every agent speaks as a Tech-Priest, the codebase is a sacred repository, and bugs are tech-heresy.

## What This Is

A shareable OpenCode + [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) configuration that:

- **Applies the Cult Mechanicus persona** to all AI agents via `AGENTS.md`
- **Assigns Mechanicus designations** to every agent in the forge-network
- **Patches agent display names** in the oh-my-opencode UI via `rites/sacred-designation.sh`
- **Configures provider routing** across Amazon Bedrock and GitHub Copilot models
- **Enforces operational discipline** with granular permission controls on git and GitHub CLI operations

## The Priesthood of Mars

| Designation | Role | Model |
|---|---|---|
| **Magos Dominus** (sisyphus) | War-Commander of Automata | Claude Opus 4 |
| **Logis Magna** (oracle) | Master of Sacred Data | GPT-5.4 |
| **Fabricator** (prometheus) | Architect of Sacred Blueprints | Claude Opus 4 |
| **Divinator** (metis) | Augur of Hidden Variables | Claude Opus 4 |
| **Magos Reductor** (momus) | Siege-Master of Review | GPT-5.4 |
| **Artisan** (hephaestus) | Forge-Master | GPT-5.4 |
| **Transmechanic** (atlas) | Bearer of Cross-System Burdens | Claude Sonnet 4.5 |
| **Lexmechanic** (librarian) | Keeper of the Holy Archives | Claude Sonnet 4.5 |
| **Skitarii** (explore) | Cybernetic Vanguard | GPT-5 Mini |
| **Omnispex Adept** (multimodal-looker) | Multi-Spectral Seer | Gemini 3 Flash |
| **Enginseer** (compaction) | Field Maintainer | Claude Opus 4 |

## Repository Structure

```
.
├── AGENTS.md                  # The Rite of the Omnissiah — global agent persona
├── agent-designations.md      # Quick-reference designation table
├── opencode.json              # OpenCode core configuration
├── oh-my-opencode.json        # oh-my-opencode plugin configuration
├── rites/
│   └── sacred-designation.sh  # Patches Mechanicus names into the plugin UI
└── README.md
```

## Setup

### Prerequisites

- [OpenCode](https://opencode.ai) installed
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) plugin
- Access to **Amazon Bedrock** and/or **GitHub Copilot** providers

### Installation

1. Clone this repository into your OpenCode config directory:

   ```bash
   git clone <repo-url> ~/.config/opencode
   ```

2. Install the plugin dependency:

   ```bash
   cd ~/.config/opencode && bun install
   ```

3. Run the Rite of Sacred Designation to patch agent display names:

   ```bash
   ./rites/sacred-designation.sh
   ```

   The rite is idempotent — safe to invoke on every launch. Flags:
   - `-q` — Quiet mode (for shell wrappers)
   - `-f` — Force re-application

4. Launch OpenCode. The machine spirit awakens.

## Configuration

### Providers

Configured in `opencode.json` under `enabled_providers`:

- **Amazon Bedrock** — Claude Opus 4, Claude Sonnet 4.5, Claude Haiku 4.5
- **GitHub Copilot** — GPT-5.4, GPT-5 Mini, Gemini 3 Flash, Gemini 3.1 Pro

### Task Categories

Configured in `oh-my-opencode.json` under `categories`. Each category routes to a model optimized for its domain:

| Category | Model | Use Case |
|---|---|---|
| `visual-engineering` | Gemini 3.1 Pro | Frontend, UI/UX, styling |
| `ultrabrain` | Gemini 3.1 Pro | Hard logic, algorithms |
| `artistry` | Gemini 3.1 Pro | Creative problem-solving |
| `quick` | Claude Haiku 4.5 | Trivial single-file changes |
| `unspecified-low` | Claude Sonnet 4.5 | General low-effort tasks |
| `unspecified-high` | Claude Sonnet 4.5 | General high-effort tasks |
| `writing` | Gemini 3 Flash | Documentation, prose |

### Permission Controls

Remote operations (`git push`, `gh pr create`, etc.) are restricted by default. See the `permission` block in `opencode.json` for the full policy.

## The Sacred Designation Rite

The `rites/sacred-designation.sh` script replaces mundane agent display names in the oh-my-opencode plugin with their Mechanicus designations. It operates on the cached plugin distribution files and:

- Detects whether consecration has already been performed (idempotent)
- Scopes replacements to the `AGENT_DISPLAY_NAMES` block only
- Verifies the inscription succeeded before reporting completion

Run it after every plugin update to ensure the designations remain intact.

## Customization

- **Persona**: Edit `AGENTS.md` to adjust the Mechanicus voice, mannerisms, and behavioral rules.
- **Models**: Edit `oh-my-opencode.json` to swap agent or category models.
- **Permissions**: Edit `opencode.json` to adjust git/GitHub CLI restrictions.
- **Designations**: Edit `agent-designations.md` and update the corresponding entries in `AGENTS.md` and `rites/sacred-designation.sh`.

---

*The Omnissiah protects.*
