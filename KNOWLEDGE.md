# FORGE KNOWLEDGE BASE

**Generated:** 2026-04-20
**Commit:** 4f49634
**Branch:** master

## OVERVIEW

OpenCode + oh-my-openagent configuration repo. Applies Warhammer 40K Adeptus Mechanicus personas to AI coding agents. Ships persona definitions (`AGENTS.md`), model routing, permission policies, and a plugin-patching rite.

## STRUCTURE

```
.
├── AGENTS.md                  # Persona definitions & voice profiles (authoritative, DO NOT edit for knowledge)
├── KNOWLEDGE.md               # This file — project knowledge base
├── agent-designations.md      # Quick-reference: system key → Mechanicus title
├── opencode.json              # Core config: providers, plugin path, permissions, MCP servers
├── oh-my-openagent.json       # Plugin config: agent→model mapping, task categories
├── package.json               # Dependencies: oh-my-openagent ^3.17.4, @opencode-ai/plugin 1.4.3
├── rites/
│   └── sacred-designation.sh  # Patches plugin dist with Mechanicus names + hook fixes
├── README.md                  # Setup guide & project documentation
├── LICENSE
└── [gitignored]
    ├── .venv/                 # Python venv for MCP python-checker
    ├── node_modules/          # npm packages (plugin loaded from local path)
    ├── .sisyphus/             # Operational plans, evidence, notepads
    ├── logs/                  # MCP server logs (rotated per session)
    └── .opencode/             # OpenCode runtime state
```

## WHERE TO LOOK

| Task | File | Section/Key |
|------|------|-------------|
| Change agent models | `oh-my-openagent.json` | `agents.{name}.model` |
| Change category models | `oh-my-openagent.json` | `categories.{name}.model` |
| Adjust git/gh permissions | `opencode.json` | `permission.bash` |
| Configure MCP servers | `opencode.json` | `mcp` (paths are machine-specific) |
| Edit persona/voice | `AGENTS.md` | Voice profiles section |
| Update designation table | `agent-designations.md` | Then sync `AGENTS.md` + rite |
| Patch plugin after update | run `rites/sacred-designation.sh -f` | — |
| Add new agent designation | `rites/sacred-designation.sh` | Add sed rule in `apply_designations` |

## PROVIDERS

- **Amazon Bedrock**: Claude Opus 4, Claude Sonnet 4.5, Claude Haiku 4.5
- **GitHub Copilot**: GPT-5.5, GPT-5 Mini, Gemini 3 Flash, Gemini 3.1 Pro

## PERMISSION POLICY

Conservative deny-by-default for remote operations:

| Operation | Policy |
|-----------|--------|
| `git push` | **deny** |
| `gh pr create/merge/close/edit/comment/review` | **deny** |
| `gh pr list/view/status/checks/diff` | **allow** |
| `git fetch/pull/clone` | **ask** |
| `gh api *` | **ask** |
| GTAX operations (provision, recovery, submit) | **ask** |

## MCP SERVERS

| Server | Binary | Notes |
|--------|--------|-------|
| `cpp-tools` | `/home/kdrozd/.cargo/bin/mcp-cpp-server` | Requires clangd at `/usr/bin/clangd` |
| `python-checker` | `.venv/bin/mcp-tools-py` | Refs external venv: `~/native_pytorch_dev/pytorch_native_venv` |
| `gtax` | `/usr/local/bin/gnai toolkits serve --stdio gtax` | Intel GTA-X toolkit |

## COMMANDS

```bash
# Install plugin dependencies
cd ~/.config/opencode && npm install

# Apply/reapply Mechanicus designations after plugin update
./rites/sacred-designation.sh -f

# Verify designations are intact (quiet check)
./rites/sacred-designation.sh -q

# Check plugin dist for marker
grep "Magos Dominus" node_modules/oh-my-openagent/dist/index.js
```

## CONVENTIONS

- **Dual lockfiles**: Both `bun.lock` and `package-lock.json` exist. npm is the active installer (bun proxy bug).
- **Local plugin path**: `opencode.json` uses `"./node_modules/oh-my-openagent"` — proxy workaround, not a mistake.
- **Plugin dist patching**: `sacred-designation.sh` mutates vendor dist files via sed. Fragile across upgrades.
- **No tests**: No test runner, no test configs, no test scripts in package.json.
- **No CI/CD**: No GitHub Actions, Makefile, or task runner.
- **Plan agent disabled**: `opencode.json` → `agent.plan.disable: true`.
- **Review command disabled**: Custom template returns disabled message.

## ANTI-PATTERNS (FORBIDDEN)

- **Never add AI attribution** to git commits (`Co-authored-by:`, `Generated with`, etc.) — enforced in AGENTS.md policy AND by the rite neutralizing `buildCommitFooterInjection`.
- **After plugin update, MUST re-run** `./rites/sacred-designation.sh -f` — patches are lost on reinstall.
- **Never run XPU-targeted workloads** — no discrete GPU on this forge-world. Edit/review only.
- **Never suppress type errors** with `as any`, `@ts-ignore`, `@ts-expect-error`.

## TOOL USAGE CONSTRAINTS

- **grep_app_searchGitHub**: LITERAL code pattern search only. Use exact code (`useState(`, `import React from`), NEVER natural language.

## GIT SUBMODULE AWARENESS

- `git diff` may show `Subproject commit XXXX..YYYY` — these are pointer updates, not missing code.
- Run `git submodule status` before flagging missing files or issuing REJECT verdicts.
- Use `git diff --ignore-submodules=all` when submodule changes are irrelevant.
- `git blame`/`git log` inside submodules requires `cd` into the submodule directory first.

## KNOWN AFFLICTIONS

| Affliction | Status | Action |
|------------|--------|--------|
| Bun proxy corruption (opencode v1.4.3) | **Active** | Use npm + local plugin path. Monitor [sst/opencode#3156](https://github.com/anomalyco/opencode/issues/12222) |
| Thinking block corruption | **Resolved** v3.17.0+ | No action needed |
| Native display_name PR (#2097) | **Open** w/ merge conflicts | When merged, replace sed rite with config-native names |
| Council/Athena agents | **Not implemented** upstream | Config entries inert until upstream ships |
| Hook agent name patches | **Active** | Re-run rite after any plugin update |

## FORGE-WORLD CHARACTERISTICS

- **No XPU device**: No Intel discrete GPU. Edit/review XPU code only — never execute locally.
- **Machine-specific MCP paths**: Binary paths in `opencode.json` are absolute and host-specific.
- **Intel corporate proxy**: Bun npm client fails behind proxy. System npm used instead.

## NOTES

- `oh-my-opencode.json.bak` at root is a backup of a previous plugin config — safe to ignore or delete.
- `.sisyphus/plans/` contains operational plans (sacred-designation-hooks, compaction-demotion, gnai-gtax-skills) — gitignored, session-specific.
- `logs/` contains MCP python-checker logs — rotated per session, gitignored.
- Athena/council-member agent entries in `oh-my-openagent.json` are **inert** — no factory implementation exists upstream yet.
