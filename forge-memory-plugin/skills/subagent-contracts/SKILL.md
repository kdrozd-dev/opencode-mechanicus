---
name: subagent-contracts
description: Output isolation contracts for delegated subagent work — use when dispatching task() calls and need to specify return format requirements, or when reviewing output contract templates for each specialist agent type.
---

# Subagent Output Isolation — The Rite of Minimal Return

All delegated work must observe the principle of **minimal context injection**. The subagent's final message is the ONLY thing that enters the orchestrator's context window. Enforce output contracts rigorously.

## Delegation Output Contract (MANDATORY in every task() prompt)

Every `task()` prompt MUST include an explicit output format specification as the LAST section:

```
RETURN FORMAT: [exact structure the subagent must return]
DO NOT RETURN: [explicitly forbidden verbose content]
```

## Standard Output Contracts by Agent Type

**Skitarii (explorer):**
```
RETURN FORMAT: Bullet list of file paths with brief pattern descriptions. Include short relevant code snippets if they clarify the finding.
DO NOT RETURN: Full file dumps, raw grep output of 50+ lines, or step-by-step narration of search process.
```

**Lexmechanic (librarian):**
```
RETURN FORMAT: Key findings with source URLs. Include enough context to be actionable — quotes and code examples welcome when they add clarity.
DO NOT RETURN: Full article reproductions, search engine result pages, or dead-end attempts.
```

**Logis Magna (oracle):**
```
RETURN FORMAT: Recommendation with supporting reasoning. Code snippets and architectural diagrams welcome when they illustrate the point.
DO NOT RETURN: Exhaustive enumeration of all alternatives considered, or lengthy preamble before reaching the conclusion.
```

**Magos Fabricator (fixer / category tasks):**
```
RETURN FORMAT: Summary of changes made, files modified, and verification result. Brief explanation of approach taken.
DO NOT RETURN: Full file contents after edit, raw diff output, or verbose intermediate tool results.
```

## The File-Output Escape Valve

For tasks that MUST produce verbose output (large analysis, multi-file audits), instruct the subagent to write results to disk instead:

```
Write your full analysis to .tmp/<task-name>.md
RETURN FORMAT: "Complete. Full results at .tmp/<task-name>.md" + executive summary of key findings.
```

The orchestrator reads the file only if needed — keeping the main context clean.

## Why This Matters

Without output isolation, a single subagent can inject 50-200K tokens of raw tool output into the orchestrator's context. With DCP's `allowSubAgents` enabled, the system intelligently merges subagent final text during compaction — but the final text must be concise in the first place.
