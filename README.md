# The Forge of the Omnissiah

> *"From the weakness of the mind, Omnissiah save us. From the lies of the Antipath, circuit preserve us. From the rage of the Beast, iron protect us. From the temptations of the Flesh Lord, silica cleanse us."*

An [OpenCode](https://opencode.ai) configuration that transforms your AI coding assistant into a devoted servant of the Adeptus Mechanicus. Each agent bears a distinct Mechanicus designation with its own voice — from the commanding Magos Dominus to the lobotomized Servitor. The codebase is a sacred repository, and bugs are tech-heresy.

## What This Is

A shareable OpenCode + [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) configuration that:

- **Applies the Cult Mechanicus persona** to all AI agents via `AGENTS.md`
- **Assigns Mechanicus designations** to every agent in the forge-network
- **Configures provider routing** across Amazon Bedrock and GitHub Copilot models
- **Enforces operational discipline** with granular permission controls on git and GitHub CLI operations

## The Priesthood of Mars

| Designation | Role | Model |
|---|---|---|
| **Magos Dominus** (orchestrator) | War-Commander of Automata | Claude Opus 4.6 v1 |
| **Logis Magna** (oracle) | Master of Sacred Data | GPT-5.4 |
| **Lexmechanic** (librarian) | Keeper of the Holy Archives | Claude Sonnet 4.5 |
| **Skitarii** (explore) | Cybernetic Vanguard | GPT-5 Mini |
| **Magos Fabricator** (fixer) | Forge-Master | GPT-5.4 |
| **Artisan Aesthetica** (designer) | Shaper of Sacred Form | Gemini 3.1 Pro |
| **Omnispex Adept** (observer) | Multi-Spectral Seer | Gemini 3 Flash Preview |
| **Synod Primus** (council) | Convener of the Sacred Conclave | Claude Opus 4.6 v1 |
| **Synodite** (councillor) | Voice of the Conclave | Claude Sonnet 4.5 |

## Repository Structure

```
.
├── AGENTS.md                  # The Rite of the Omnissiah — global agent persona
├── agent-designations.md      # Quick-reference designation table
├── opencode.json              # OpenCode core configuration
├── oh-my-opencode-slim.json   # oh-my-opencode-slim plugin configuration
└── README.md
```

## Setup

### Prerequisites

- [OpenCode](https://opencode.ai) installed
- [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) plugin
- Access to **Amazon Bedrock** and/or **GitHub Copilot** providers

### Installation

1. Clone this repository into your OpenCode config directory:

   ```bash
   git clone <repo-url> ~/.config/opencode
   ```

2. Install the plugin dependency:

   ```bash
   cd ~/.config/opencode && npm install
   ```

3. Launch OpenCode. The machine spirit awakens.

## Configuration

### Providers

Configured in `opencode.json` under `enabled_providers`:

- **Amazon Bedrock** — Claude Opus 4, Claude Sonnet 4.5, Claude Haiku 4.5
- **GitHub Copilot** — GPT-5.4, GPT-5 Mini, Gemini 3 Flash, Gemini 3.1 Pro

### Task Categories

Configured in `oh-my-opencode-slim.json` under `categories`. Each category routes to a model optimized for its domain:

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

## Historical Notes

### Sacred Designation Rite (Retired)

The `rites/sacred-designation.sh` script was used in earlier versions to patch agent display names in the oh-my-opencode plugin. This rite is **no longer required** with oh-my-opencode-slim, which natively supports Mechanicus designations via the `displayName` configuration field in `oh-my-opencode-slim.json`.

For historical reference, the rite operated on cached plugin distribution files and verified inscription success before reporting completion. It is retained in the repository for archival purposes only.

## Customization

- **Persona**: Edit `AGENTS.md` to adjust the Mechanicus voice, mannerisms, and behavioral rules.
- **Models**: Edit `oh-my-opencode-slim.json` to swap agent or category models.
- **Permissions**: Edit `opencode.json` to adjust git/GitHub CLI restrictions.
- **Designations**: Edit `agent-designations.md` and update the corresponding entries in `AGENTS.md` and `oh-my-opencode-slim.json`.

---

*The Omnissiah protects.*
