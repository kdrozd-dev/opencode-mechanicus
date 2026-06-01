# GNAI & GTAX/RIL OpenCode Skills

## TL;DR

> **Quick Summary**: Create two opencode skill files providing deep domain knowledge for Intel GNAI platform and GTAX/RIL operations, registered via the `skills.paths` config mechanism.
>
> **Deliverables**:
> - `skills/gnai.md` — Deep developer reference for GNAI API, SDK, marketplace, toolkits, MCP integration
> - `skills/gtax.md` — RIL user operations reference for reservations, image restore/save, remote access
> - `opencode.json` update — Add `"skills": { "paths": ["./skills"] }` configuration
>
> **Estimated Effort**: Short
> **Parallel Execution**: YES - 2 waves
> **Critical Path**: Task 1 → Task 2 (config) → Tasks 3+4 (parallel skills) → Task 5 (verify)

---

## Context

### Original Request
Create two opencode skills: one for accessing Intel GNAI documentation/toolkit, one for GTAX/RIL operations (reservations, image restore, remote access). Source material from gpusw-docs.intel.com and ~/gnai_and_gtax codebase.

### Interview Summary
**Key Discussions**:
- **File location**: `skills/` subdirectory within opencode config dir, registered via opencode.json
- **GTAX scope**: RIL user operations only — reservations, image restore/save, KVM/RDP/SSH access
- **GNAI depth**: Deep developer reference — full API, SDK, all provider endpoints, toolkit development

**Research Findings**:
- GNAI API at gnai.intel.com with OpenAI + Anthropic provider compatibility, Basic/OAuth2 auth
- GNAI Python SDK: `gnai-client` from Intel Artifactory
- GNAI Marketplace: 50+ toolkits, `gnai` CLI, MCP stdio serving
- RIL: 5 GEO locations, 5-step reservation wizard, image restore/save via TaskML
- GTAX entry: https://gtax-ril-fm.intel.com/
- Key TaskML patterns: `image_dut` for restore/save, `provision_dut` for partitioning

### Metis Review
**Identified Gaps** (addressed):
- **CRITICAL**: `command` schema does NOT support `file` property — corrected to use `skills.paths` mechanism
- **HIGH**: Unknown skill file format — added format-discovery task to inspect builtin skill first
- **MEDIUM**: Context budget risk — enforced ~400 line cap per skill
- **MEDIUM**: Scope creep on toolkit catalog and TaskML depth — locked down to patterns, not exhaustive listing

---

## Work Objectives

### Core Objective
Equip the forge-network with persistent domain knowledge for Intel GNAI and GTAX/RIL, so any agent can be loaded with operational context for these platforms on demand.

### Concrete Deliverables
- `skills/gnai.md` — loadable as `/gnai` slash command
- `skills/gtax.md` — loadable as `/gtax` slash command
- Updated `opencode.json` with `skills.paths` configuration

### Definition of Done
- [ ] `skill(name="gnai")` returns skill content without error
- [ ] `skill(name="gtax")` returns skill content without error
- [ ] `opencode.json` is valid JSON with `skills.paths` key
- [ ] Both skills appear in the available commands list

### Must Have
- GNAI: Authentication methods (Basic + OAuth2), API endpoints, Python SDK examples, marketplace toolkit management, MCP serving, provider compatibility (OpenAI/Anthropic), rate limiting
- GTAX: Reservation wizard flow, image restore (golden/user/TaskML), image save, remote access (KVM/RDP/VNC/SSH), client search via CSQ, My Workspace, key URLs
- Both: Placeholder credentials only (`YOUR_USERNAME`, `your-idsid`), dense reference format, `Last verified` date header

### Must NOT Have (Guardrails)
- No real credentials, API keys, or IDSID values in skill content
- No individual documentation of 50+ GNAI toolkits — document the pattern only, list names
- No TaskML authoring guide — include only the 2-3 user-facing snippets (image restore, image save)
- No troubleshooting sections, FAQs, or "common issues" — scope creep magnets
- No tutorial-style prose ("first, let's understand...") — every line must be reference-dense
- No `command` block registration in opencode.json — use `skills.paths` only
- Each skill MUST NOT exceed ~400 lines (prevent context budget blowout)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: N/A — these are markdown content files
- **Automated tests**: None — no code under test
- **Framework**: N/A

### QA Policy
Every task includes agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Config validation**: Use Bash (python3 JSON validation)
- **Skill loading**: Use skill() tool to verify discoverability
- **Content review**: Use Read tool + grep for forbidden patterns

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — sequential):
├── Task 1: Discover builtin skill format [quick]
└── Task 2: Create skills/ directory + update opencode.json [quick]

Wave 2 (Content — MAX PARALLEL):
├── Task 3: Write GNAI skill (skills/gnai.md) [writing]
└── Task 4: Write GTAX/RIL skill (skills/gtax.md) [writing]

Wave 3 (Verification):
└── Task 5: Verify both skills load and register correctly [quick]

Wave FINAL (After ALL tasks — reviews + user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1    | —         | 2,3,4  | 1    |
| 2    | 1         | 3,4,5  | 1    |
| 3    | 1,2       | 5      | 2    |
| 4    | 1,2       | 5      | 2    |
| 5    | 3,4       | F1-F4  | 3    |

### Agent Dispatch Summary

- **Wave 1**: 2 tasks — T1 `quick`, T2 `quick`
- **Wave 2**: 2 tasks — T3 `writing`, T4 `writing`
- **Wave 3**: 1 task — T5 `quick`
- **FINAL**: 4 tasks — F1 `oracle`, F2 `unspecified-high`, F3 `unspecified-high`, F4 `deep`

---

## TODOs

- [ ] 1. Discover Builtin Skill File Format

  **What to do**:
  - Load an existing builtin skill (e.g., `skill(name="git-master")` or `skill(name="playwright")`) to see the exact markdown structure opencode expects
  - Document the format: frontmatter (if any), header structure, section organization, trigger phrases, description format
  - Determine how the filename maps to the command name (e.g., does `gnai.md` become `/gnai`?)
  - Note any required metadata fields or conventions

  **Must NOT do**:
  - Do not modify any builtin skill files
  - Do not create skill files yet — this task is discovery only

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple discovery task — load a tool, read its output, document the format
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - None needed — this is a read-only exploration task

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (sequential)
  - **Blocks**: Tasks 2, 3, 4
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - The available skills list in the system prompt shows skills like `/playwright`, `/git-master`, `/frontend-ui-ux` with `(opencode - Skill)` in description and `scope: builtin`

  **External References**:
  - opencode.json schema: `skills.paths` (array of strings) and `skills.urls` (array of strings)

  **WHY Each Reference Matters**:
  - The builtin skills define the canonical format. Our custom skills must mirror this format exactly or they won't be discovered/loaded by the opencode skill system

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Load builtin skill and observe format
    Tool: skill() tool
    Preconditions: opencode is running with oh-my-openagent plugin
    Steps:
      1. Call skill(name="git-master") and capture the returned content
      2. Examine: Does it have YAML frontmatter? What headers? What sections?
      3. Record the structure in a brief note (can be in the same response)
    Expected Result: Skill content returned; structure is documented for Tasks 3-4 to follow
    Failure Indicators: skill() returns error or empty content
    Evidence: .sisyphus/evidence/task-1-skill-format-discovery.md
  ```

  **Commit**: NO

- [ ] 2. Create skills/ Directory and Update opencode.json

  **What to do**:
  - Create the `skills/` directory at the opencode config root (`~/.config/opencode/skills/`)
  - Edit `opencode.json` to add the `skills` configuration key:
    ```json
    "skills": {
      "paths": ["./skills"]
    }
    ```
  - Place this key at the top level of the JSON object (sibling to `$schema`, `plugin`, `mcp`, etc.)
  - Validate the JSON is syntactically correct after editing

  **Must NOT do**:
  - Do NOT add anything to the `command` block — the `command` schema does not support `file` references
  - Do NOT modify any existing configuration keys
  - Do NOT add `skills.urls` — we're using local paths only

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Two simple operations — mkdir + JSON edit
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (sequential, after Task 1)
  - **Blocks**: Tasks 3, 4, 5
  - **Blocked By**: Task 1

  **References**:

  **Pattern References**:
  - `opencode.json` (current file) — see existing structure at `/home/kdrozd/.config/opencode/opencode.json`

  **API/Type References**:
  - opencode config schema: `"skills": { "paths": ["./skills"] }` — the `paths` array takes relative paths to skill folders

  **WHY Each Reference Matters**:
  - opencode.json is the core config. The `skills.paths` key must be placed correctly and the JSON must remain valid. The `command` block is tempting but WRONG — its schema only accepts `template` (inline string), NOT `file` references.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify directory exists and JSON is valid
    Tool: Bash
    Preconditions: Task 1 complete
    Steps:
      1. Run: ls -la /home/kdrozd/.config/opencode/skills/
      2. Run: python3 -c "import json; d=json.load(open('/home/kdrozd/.config/opencode/opencode.json')); assert 'skills' in d; assert './skills' in d['skills']['paths']; print('PASS')"
    Expected Result: Directory exists; JSON valid; skills.paths contains "./skills"
    Failure Indicators: Directory missing, JSON parse error, missing skills key
    Evidence: .sisyphus/evidence/task-2-config-validation.txt
  ```

  **Commit**: NO (groups with final commit)

- [ ] 3. Write GNAI Skill (`skills/gnai.md`)

  **What to do**:
  - Create `skills/gnai.md` following the format discovered in Task 1
  - Include a `Last verified: 2026-04-10` header
  - **Must contain these sections** (dense reference, not tutorial):
    - **Overview**: GNAI is Intel's GPU Network AI platform at gnai.intel.com
    - **Authentication**: Two methods:
      - Basic Auth: `-u $USERNAME:$PASSWORD` with Intel LDAP credentials
      - OAuth2: Token from `gnai.intel.com/auth/oauth2/sso`, passed via `Authorization: Bearer $TOKEN`
      - AGS entitlements: GNAI Public (`goto.intel.com/ags-gnai-public`), Generic Account variants
    - **API Reference**: Base URL `https://gnai.intel.com/api`
      - Chat: `POST /chat?profile={profile}&stream={bool}` with `{"question": "..."}` body
      - Chat history: `conversation_id` + `chat_history=True` options
      - Structured output: JSON Schema via `output` option in `GnaiChatOptions`
    - **Provider Compatibility**:
      - OpenAI: `https://gnai.intel.com/api/providers/openai/v1` — completions, responses, embeddings
      - Anthropic: `https://gnai.intel.com/api/providers/anthropic` — messages
      - Use GNAI OAuth2 token as `api_key` for both
    - **Python SDK**: `pip install gnai-client --index-url https://gfx-assets.fm.intel.com/artifactory/api/pypi/pypi-gsae/simple`
      - `GnaiClient(username, password)` or token-based
      - `client.chat.ask_question(question, profile=...)` pattern
      - `GnaiChatOptions` for history, structured output, agent_prompt
    - **Marketplace & Toolkits**:
      - Browse: `https://gpusw-docs.intel.com/services/gnai/marketplace`
      - Register: `gnai toolkits register <org>/<repo>/<toolkit>`
      - Serve as MCP: `gnai toolkits serve --stdio <name>`
      - Collections: `gnai marketplace add gfx` (bundles gnai, hsdes, jira, gtax, gfx-dev)
      - Key toolkits (names only, NOT full docs): gtax, gnai, ci-helper, gta-core, val-helper, build, github, jira, hsdes, confluence
    - **Rate Limiting**: Per-user RPM + daily cost quota. Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Used`, `X-RateLimit-Reset`. 429 with `Retry-After` on limit.
    - **Developer Integration**: Three levels:
      - Vanilla SKILL.md (Agent Skills standard, works in Claude Code)
      - Skills with Toolkit (toolkit.yaml, sandboxed, secrets support)
      - Full toolkit with tools (custom Python/Node, MCP sharing)
    - **Key URLs**: gnai.intel.com, API docs at gnai.intel.com/api/docs, Swagger, Jira (GNAI project), Viva Engage community
  - Keep under 400 lines total. Dense, no filler.

  **Must NOT do**:
  - No real credentials or API keys — use `YOUR_USERNAME`, `YOUR_PASSWORD`, `YOUR_TOKEN`
  - No tutorial prose — pure reference
  - No individual toolkit documentation (just names + pattern)
  - No troubleshooting/FAQ sections

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Technical documentation writing — dense reference material
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 4)
  - **Blocks**: Task 5
  - **Blocked By**: Tasks 1, 2

  **References**:

  **Pattern References**:
  - Format discovered in Task 1 (builtin skill structure)
  - Evidence from Task 1: `.sisyphus/evidence/task-1-skill-format-discovery.md`

  **External References**:
  - GNAI API docs: https://gpusw-docs.intel.com/services/gnai/developer/api/
  - GNAI Marketplace: https://gpusw-docs.intel.com/services/gnai/marketplace/
  - GNAI Developer: https://gpusw-docs.intel.com/services/gnai/developer/
  - GNAI Agentic Flows: https://gpusw-docs.intel.com/services/gnai/developer/agentic-flows/
  - Swagger: https://gnai.intel.com/api/docs

  **WHY Each Reference Matters**:
  - API docs provide auth methods, endpoints, SDK examples, rate limiting — the core of the skill
  - Marketplace provides toolkit registration/serving patterns
  - Developer docs provide the three integration levels (vanilla/toolkit/full)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify GNAI skill content completeness
    Tool: Bash (grep + wc)
    Preconditions: skills/gnai.md exists
    Steps:
      1. Run: wc -l skills/gnai.md — verify under 400 lines
      2. Run: grep -c "Authentication\|OAuth2\|Basic Auth" skills/gnai.md — verify ≥ 3 matches
      3. Run: grep -c "openai\|anthropic\|provider" skills/gnai.md — verify ≥ 2 matches
      4. Run: grep -c "gnai toolkits\|marketplace\|MCP" skills/gnai.md — verify ≥ 2 matches
      5. Run: grep -ci "YOUR_USERNAME\|YOUR_PASSWORD\|YOUR_TOKEN" skills/gnai.md — verify placeholder creds exist
      6. Run: grep -c "gnai.intel.com" skills/gnai.md — verify key URL present
    Expected Result: Under 400 lines, all required sections present, placeholder creds only
    Failure Indicators: Over 400 lines, missing auth/provider/toolkit sections, real credentials found
    Evidence: .sisyphus/evidence/task-3-gnai-skill-validation.txt

  Scenario: Verify no real credentials in GNAI skill
    Tool: Bash (grep)
    Preconditions: skills/gnai.md exists
    Steps:
      1. Run: grep -iE '[a-z0-9]{8,}@intel\.com|password\s*[:=]\s*["\x27][^"\x27]+' skills/gnai.md
    Expected Result: No matches (empty output)
    Failure Indicators: Any match indicates potential real credentials
    Evidence: .sisyphus/evidence/task-3-gnai-no-creds.txt
  ```

  **Commit**: NO (groups with final commit)

- [ ] 4. Write GTAX/RIL Skill (`skills/gtax.md`)

  **What to do**:
  - Create `skills/gtax.md` following the format discovered in Task 1
  - Include a `Last verified: 2026-04-10` header
  - **Must contain these sections** (dense reference, not tutorial):
    - **Overview**: RIL (Remote Interactive Lab) — machine farm for GPU debug with DUTs across 5 GEOs (FM, IGK, BA, SH, JF). Entry point: https://gtax-ril-fm.intel.com/
    - **Access**: AGS entitlements required. Public pool: `ril_sas_public`. Private pools: PDPs (Purpose Driven Pools). Access doc: https://gpusw-docs.intel.com/services/ril/access/
    - **Finding a DUT**: Client List at `#/clients`. Client Set Queries (CSQ) for filtering by geo, program, SKU, etc. Calendar icons: No icon=Free, Red=Reserved, Blue=Coming, Black=No Access
    - **Creating a Reservation** — 5-step wizard:
      - Step 1: Start/End time, duration, recurrence options
      - Step 2: Add guests, disable automated recovery, email alerts
      - Step 3: TaskML on start — Golden Template, User Image, Custom TaskML, or Skip
      - Step 4: TaskML on end — Save image or Custom TaskML
      - Step 5: Justification → Reserve
    - **Image Restore** — three methods:
      - Golden template: Select from searchable dropdown in wizard Step 3
      - User image: Search by idsid in wizard Step 3
      - Custom TaskML (paste into wizard or submit as job):
        ```
        image_dut -a 3 -rto 1250
            -image_dut.asset.os_image.asset_name: "IMAGE_NAME"
            -image_dut.asset.os_image.asset_path: "gfx-sandbox-fm/YOUR_IDSID/path"
            -image_dut.asset.os_image.asset_version: "VERSION"
        ```
    - **Image Save** — two methods:
      - Via wizard Step 4: enter image name
      - Via TaskML (submit as job):
        ```
        image_dut --capture-and-submit-artifactory --capture-image-timeout=5000
            -image_dut.submitted_os_root_url: "gta+https://gfx-assets.intel.com/artifactory"
            -image_dut.submitted_os_asset_path: "gfx-sandbox-LOCATION/YOUR_IDSID/path"
            -image_dut.submitted_os_asset_name: "IMAGE_NAME"
            -image_dut.submitted_os_asset_version: 1.0
            -image_dut.captured_os_img_name: "IMAGE_NAME"
        ```
    - **Remote Access**: From My Workspace (`#/user/me`) — KVM buttons, RDP, VNC, SSH. Client controls include reboot (soft/hard), recover, reprovision
    - **My Workspace**: `https://gtax-ril-fm.intel.com/#/user/me` — active reservations, client controls, KVM buttons. Replace `me` with idsid for other users
    - **Reservation Management**: Edit, Release (triggers taskml_on_end), Cancel from My Workspace calendar
    - **TaskML Helpers**: Available in Submit Job modal → TaskML Helpers dropdown. Options include restore-local-user-image, save-local-user-image, download-assets. Custom task items via PR to gtax-runner `plugins/tasks.yml`
    - **Key URLs**: RIL home, My Workspace, Client List, RIL docs, MS Teams support channel, Artifactory (gfx-assets.intel.com)
    - **GTAX Runner CLI**: `gta start` to launch, `gta console` for foreground, `./gta` on Linux/Mac. Codebase at `~/gnai_and_gtax/applications.validation.gta.execution.gtax-runner/`
  - Keep under 400 lines total. Dense, no filler.

  **Must NOT do**:
  - No real idsid values — use `YOUR_IDSID`
  - No TaskML authoring guide — only the 2-3 paste-ready snippets above
  - No GTAX-Runner development instructions (make targets, plugin dev, executor internals)
  - No troubleshooting/FAQ sections
  - No tutorial prose

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Technical documentation writing — operational reference material
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 3)
  - **Blocks**: Task 5
  - **Blocked By**: Tasks 1, 2

  **References**:

  **Pattern References**:
  - Format discovered in Task 1 (builtin skill structure)
  - Evidence from Task 1: `.sisyphus/evidence/task-1-skill-format-discovery.md`

  **External References**:
  - RIL docs: https://gpusw-docs.intel.com/services/ril/
  - RIL Usage Basics: https://gpusw-docs.intel.com/services/ril/usage/
  - RIL Advanced: https://gpusw-docs.intel.com/services/ril/advanced/
  - RIL TaskML: https://gpusw-docs.intel.com/services/ril/taskml/
  - GTAX Runner AGENTS.md: `~/gnai_and_gtax/applications.validation.gta.execution.gtax-runner/AGENTS.md`
  - GTAX Runner README.md: `~/gnai_and_gtax/applications.validation.gta.execution.gtax-runner/README.md`
  - Reservation System: https://gpusw-docs.intel.com/services/gtax/gtax-service/user/reservations/reservations/

  **WHY Each Reference Matters**:
  - RIL usage/advanced docs provide the reservation wizard flow, image restore/save TaskML, remote access methods
  - GTAX Runner AGENTS.md provides project context and CLI patterns
  - Reservation system docs provide the reservation API concepts

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify GTAX skill content completeness
    Tool: Bash (grep + wc)
    Preconditions: skills/gtax.md exists
    Steps:
      1. Run: wc -l skills/gtax.md — verify under 400 lines
      2. Run: grep -c "reservation\|Reservation\|wizard" skills/gtax.md — verify ≥ 3 matches
      3. Run: grep -c "image_dut\|Image Restore\|Image Save" skills/gtax.md — verify ≥ 3 matches
      4. Run: grep -c "KVM\|RDP\|VNC\|SSH" skills/gtax.md — verify ≥ 2 matches
      5. Run: grep -c "gtax-ril-fm.intel.com" skills/gtax.md — verify key URL present
      6. Run: grep -c "YOUR_IDSID" skills/gtax.md — verify placeholder creds
    Expected Result: Under 400 lines, all required sections present, placeholder creds only
    Failure Indicators: Over 400 lines, missing reservation/image/remote sections
    Evidence: .sisyphus/evidence/task-4-gtax-skill-validation.txt

  Scenario: Verify no real credentials in GTAX skill
    Tool: Bash (grep)
    Preconditions: skills/gtax.md exists
    Steps:
      1. Run: grep -iE '[a-z0-9]{5,}@intel\.com|idsid\s*[:=]\s*[a-z]{3,}[0-9]' skills/gtax.md
    Expected Result: No matches (empty output)
    Failure Indicators: Any match indicates potential real IDSID or credentials
    Evidence: .sisyphus/evidence/task-4-gtax-no-creds.txt
  ```

  **Commit**: NO (groups with final commit)

- [ ] 5. Verify Skills Load and Register Correctly

  **What to do**:
  - Attempt to load both skills using the `skill()` tool:
    - `skill(name="gnai")`
    - `skill(name="gtax")`
  - Verify each returns non-empty content containing expected section headers
  - Validate `opencode.json` is valid JSON with correct `skills.paths` entry
  - If skills don't load (possible if opencode needs restart), document the verification method for the user
  - Create the final git commit with all changes

  **Must NOT do**:
  - Do not modify skill content in this task — only verify
  - Do not push to remote

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple verification — tool calls + JSON validation + git commit
  - **Skills**: [`git-master`]
    - `git-master`: For creating the atomic commit with all changes

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (sequential, after Tasks 3+4)
  - **Blocks**: F1-F4
  - **Blocked By**: Tasks 3, 4

  **References**:

  **Pattern References**:
  - opencode.json: `/home/kdrozd/.config/opencode/opencode.json` — verify skills.paths added correctly

  **WHY Each Reference Matters**:
  - This is the integration verification step — confirms the entire pipeline works end-to-end

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Both skills load via skill() tool
    Tool: skill() tool
    Preconditions: Tasks 1-4 complete, skills/ dir exists with both files, opencode.json updated
    Steps:
      1. Call skill(name="gnai") — capture returned content
      2. Verify returned content is non-empty and contains "Authentication" or "API"
      3. Call skill(name="gtax") — capture returned content
      4. Verify returned content is non-empty and contains "Reservation" or "RIL"
    Expected Result: Both skills return content; key sections are present
    Failure Indicators: Error on load, empty content, missing key sections
    Evidence: .sisyphus/evidence/task-5-skills-load-verification.txt

  Scenario: opencode.json remains valid
    Tool: Bash
    Preconditions: opencode.json has been edited
    Steps:
      1. Run: python3 -c "import json; d=json.load(open('opencode.json')); assert 'skills' in d; print('VALID')"
    Expected Result: Prints "VALID"
    Failure Indicators: JSON parse error or assertion failure
    Evidence: .sisyphus/evidence/task-5-json-validation.txt

  Scenario: All files exist and are non-empty
    Tool: Bash
    Preconditions: All tasks complete
    Steps:
      1. Run: test -s skills/gnai.md && test -s skills/gtax.md && echo "ALL FILES EXIST"
    Expected Result: Prints "ALL FILES EXIST"
    Failure Indicators: test fails — file missing or empty
    Evidence: .sisyphus/evidence/task-5-files-exist.txt
  ```

  **Commit**: YES
  - Message: `feat(skills): add GNAI and GTAX/RIL opencode skills`
  - Files: `skills/gnai.md`, `skills/gtax.md`, `opencode.json`
  - Pre-commit: `python3 -c "import json; json.load(open('opencode.json'))"`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read skill files, check opencode.json). For each "Must NOT Have": search skill files for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Validate opencode.json is valid JSON and conforms to schema expectations. Review both skill files for: broken markdown, dead links, placeholder text that was never filled, inconsistent formatting, lines exceeding reasonable length. Check for AI slop: excessive headers, generic filler text, repetitive patterns.
  Output: `JSON [PASS/FAIL] | Skills [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Load both skills via `skill(name="gnai")` and `skill(name="gtax")`. Verify they return meaningful content. Check that key sections are present (auth for GNAI, reservation flow for GTAX). Attempt to use the skill content to answer a concrete question (e.g., "how do I authenticate to GNAI API?"). Save evidence.
  Output: `Skills Loadable [N/N] | Content Quality [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual content. Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance: no real creds, no tutorial prose, no FAQ sections, each under 400 lines. Flag unaccounted content.
  Output: `Tasks [N/N compliant] | Line counts [gnai: N, gtax: N] | VERDICT`

---

## Commit Strategy

- **1**: `feat(skills): add GNAI and GTAX/RIL opencode skills` — skills/gnai.md, skills/gtax.md, opencode.json

---

## Success Criteria

### Verification Commands
```bash
python3 -c "import json; json.load(open('opencode.json'))"  # Expected: no error
wc -l skills/gnai.md  # Expected: < 400 lines
wc -l skills/gtax.md  # Expected: < 400 lines
```

### Final Checklist
- [ ] Both skill files exist and are non-empty
- [ ] opencode.json has `skills.paths` pointing to `./skills`
- [ ] `skill(name="gnai")` loads successfully
- [ ] `skill(name="gtax")` loads successfully
- [ ] No real credentials in either skill file
- [ ] Each skill under 400 lines
- [ ] All "Must Have" content sections present
- [ ] All "Must NOT Have" patterns absent
