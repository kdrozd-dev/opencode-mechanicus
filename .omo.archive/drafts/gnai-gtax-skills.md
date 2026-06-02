# Draft: GNAI & GTAX/RIL OpenCode Skills

## Requirements (confirmed)
- Create TWO opencode skill files (markdown-based)
- Skill 1: **GNAI Toolkit** — access Intel GNAI documentation, marketplace, API, toolkits
- Skill 2: **GTAX/RIL Operations** — create reservations, restore images, remote into VMs

## Research Findings

### GNAI Platform (from gpusw-docs.intel.com/services/gnai/)
- **Marketplace**: 50+ toolkits available (gtax, gnai, jira, hsdes, github, etc.)
- **API**: REST API at gnai.intel.com/api with OpenAI/Anthropic provider compatibility
- **Auth**: Basic (LDAP) or OAuth2 token via gnai.intel.com/auth/oauth2/sso
- **Python SDK**: `pip install gnai-client --index-url https://gfx-assets.fm.intel.com/artifactory/api/pypi/pypi-gsae/simple`
- **CLI**: `gnai` CLI tool for toolkit management (register, serve, etc.)
- **Collections**: Pre-bundled toolkit sets (e.g., `gnai marketplace add gfx`)
- **Toolkits as MCP**: `gnai toolkits serve --stdio <name>`
- **Developer integration**: Vanilla SKILL.md, Skills with Toolkit, Full toolkit + tools
- **Key toolkits**: gtax (27 tools, 13 skills), gnai (3 tools, 2 skills), ci-helper (30 tools, 11 skills)
- **Rate limiting**: Per-user RPM + daily LLM cost quota

### GTAX/RIL Operations (from gpusw-docs.intel.com/services/ril/)
- **RIL**: Remote Interactive Lab — machine farm across 5 GEOs (FM, IGK, BA, SH, JF)
- **Entry point**: https://gtax-ril-fm.intel.com/
- **Reservation flow**: Client Search (CSQ) → Find DUT → Reserve → Wizard (5 steps)
  - Step 1: Time/duration
  - Step 2: Add guests, config recovery
  - Step 3: taskml_on_start (golden template, user image, custom TaskML, skip)
  - Step 4: taskml_on_end (save image, custom TaskML)
  - Step 5: Justification → Reserve
- **Image Restore**: Via reservation wizard or submit job with TaskML
  - Golden templates: searchable dropdown
  - User images: from your idsid directory
  - Custom TaskML: `image_dut -a 3 -rto 1250` with asset params
- **Image Save**: Via reservation end or submit job
  - `image_dut --capture-and-submit-artifactory` for Artifactory
  - Local save via TaskML helpers
- **Remote access**: KVM, RDP, VNC, SSH from My Workspace page
- **Client search**: Client Set Queries (CSQ) — filter by geo, program, SKU, etc.
- **GTAX codebase**: ~/gnai_and_gtax/applications.validation.gta.execution.gtax-runner/
  - Python-based, `gta` CLI, plugin architecture, TaskML job files
  - Executors: LocalExecutor, ThinClientExecutor, etc.
- **Support**: MS Teams channel for RIL

### OpenCode Skills System
- Skills defined as markdown files
- Loaded via `skill(name="...")` or as `/command` slash commands
- Can be registered in `opencode.json` under `command` key with `file` or `template`
- Existing commands example: `"review": { "template": "...", "description": "..." }`

## Technical Decisions
- TBD: File location for skills
- TBD: Registration method (opencode.json command vs standalone)

## Open Questions
1. Where should skill files live? (e.g., `skills/gnai.md`, root-level, etc.)
2. Should they be registered as `/gnai` and `/gtax` commands in opencode.json?
3. For GTAX skill: should it cover GTAX-Runner development (make devenv, tests, plugins) or focus on RIL user operations?
4. Should the GNAI skill include the full API reference (curl examples, Python SDK) or mainly doc navigation?

## Scope Boundaries
- INCLUDE: GNAI toolkit usage, marketplace, API, developer integration
- INCLUDE: RIL reservations, image restore/save, remote access (KVM/RDP/VNC/SSH)
- INCLUDE: TaskML operations, client search, reservation wizard
- EXCLUDE (TBD): GTAX-Runner internal development (make targets, plugin dev)
- EXCLUDE (TBD): GTA Workflow, Iceberg, deployment operations
