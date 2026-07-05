---
name: agentic-engineering-reference
description: Domain-theory reference for how agentic coding sessions work mechanically in Claude Code. Defines every core term the codofable library uses (skill, SKILL.md, frontmatter, description-based triggering, progressive disclosure, context window, compaction, subagent, orchestrator, permission mode, hook, CLAUDE.md, token, evidence classes E1-E4) and gives doc-verified mechanics — where skills live, how triggering works, what compaction preserves and loses, what a subagent sees at startup, and why model tier changes how instructions must be written. Load when a session asks "what is a skill / how do skills trigger", "why did my instructions disappear after compaction", "what context does a subagent get", "where do skills, CLAUDE.md, or hooks live", or when authoring or reviewing any codofable skill and a mechanical claim about Claude Code needs checking. All doc facts verified 2026-07-05 against official docs, with URLs for re-verification.
---

# Agentic Engineering Reference

This skill is the knowledge pack a zero-context engineer or fresh Sonnet-class session lacks: how an agentic coding session in Claude Code actually works at the mechanical level, as it applies to this library. Every mechanical claim below is verified against the official Claude Code documentation (evidence class [doc], URLs in the tag table) or labeled as professional judgment ([craft]). It exists so that other codofable skills can cite terms and mechanics instead of restating them — and so that "why does rule X exist" always has a mechanical answer, not folklore.

**Doc tag table** — every `[doc:*]` tag below refers to one of these pages, all fetched and read on 2026-07-05:

| Tag | URL |
|---|---|
| [doc:skills] | https://code.claude.com/docs/en/skills |
| [doc:subagents] | https://code.claude.com/docs/en/sub-agents |
| [doc:how-cc] | https://code.claude.com/docs/en/how-claude-code-works |
| [doc:memory] | https://code.claude.com/docs/en/memory |
| [doc:permissions] | https://code.claude.com/docs/en/permissions |
| [doc:hooks] | https://code.claude.com/docs/en/hooks |
| [doc:context] | https://code.claude.com/docs/en/context-window |

## When to use this skill

- You hit an unfamiliar term in any codofable skill (compaction, subagent, frontmatter, E1, permission mode) and need the one-line definition and where the full treatment lives.
- You are authoring or reviewing a skill and must check a mechanical claim about Claude Code ("does the body load at session start?", "what survives compaction?").
- A session behaves surprisingly: instructions stop being followed mid-session, a skill doesn't trigger, a subagent seems to "forget" the conversation.
- You are deciding how to write instructions for a cheaper model and need the model-tier design rationale.
- You need to know, mechanically, why N10 (re-verify after context loss; see `codofable-change-control`) exists.

## When NOT to use this skill

- **Designing a multi-agent workflow** (when to spawn, how to brief, how to review) → `codofable-orchestration`. This skill covers only the mechanics of what a subagent is and sees.
- **Writing or formatting a skill** (house style, template, tone) → `codofable-docs-and-writing`. This skill covers only what the platform does with the file.
- **Deciding what evidence a claim needs** → `codofable-validation-and-qa` (evidence hierarchy home) and `codofable-change-control` (gates).
- **Debugging a failing program** → `codofable-debugging-playbook`. This skill explains the harness, not your code.

## 1. Glossary

Every term the rest of the library uses, one home each. Cite this section instead of redefining.

| Term | Definition | Evidence |
|---|---|---|
| **Token** | The unit models read and write in; roughly 3–4 characters of English text. Context budgets, skill caps, and costs are all counted in tokens. | [doc:context] shows all budgets in tokens; the chars-per-token ratio is [craft] approximation |
| **Context window** | Everything the model can currently see: system prompt, CLAUDE.md, memory, loaded skills, conversation, file contents, tool outputs. Finite; fills as you work. Run `/context` in-session to see usage. | [doc:how-cc] |
| **Compaction (summarization)** | What Claude Code does as the context window approaches its limit: it clears older tool outputs first, then replaces conversation history with a structured summary. Requests and key snippets are preserved; detailed early instructions may be lost. See Section 3. | [doc:how-cc] |
| **Skill** | A directory containing a `SKILL.md` file (plus optional support files) that extends what Claude can do. Invoked automatically by the model when relevant, or manually via `/skill-name`. | [doc:skills] |
| **SKILL.md** | The required entrypoint file of a skill: YAML frontmatter (metadata) followed by a markdown body (the instructions). | [doc:skills] |
| **Frontmatter** | The YAML block between `---` markers at the top of SKILL.md. All fields optional; `description` is the load-bearing one. | [doc:skills] |
| **Trigger / description-based loading** | The mechanism by which skills load: the `description` is metadata the model always sees in a skill listing; the body loads into context only when the skill is invoked. The description is therefore the trigger surface. | [doc:skills] |
| **Progressive disclosure** | The design consequence: name+description always visible (cheap), SKILL.md body on invocation (moderate), `references/*.md` files only when explicitly read (on demand), `scripts/` executed but never loaded. Detail costs nothing until needed. | [doc:skills] ("a skill's body loads only when it's used, so long reference material costs almost nothing until you need it") |
| **Subagent** | A worker with its own fresh, isolated context window, spawned by the main session with a delegation message; it works independently and returns only a summary. | [doc:subagents] |
| **Orchestrator** | The main session when it is coordinating subagents: it writes briefs, spawns workers, and synthesizes their reports. Workflow discipline for this role lives in `codofable-orchestration`. | [craft] term; mechanics in [doc:subagents] |
| **Permission mode** | Session-level setting controlling how tool calls are approved: `default` (prompt), `acceptEdits`, `plan` (read-only exploration), `auto`, `dontAsk`, `bypassPermissions`. Enforced by the harness, not by the model. | [doc:permissions] |
| **Hook** | A user-defined shell command (or HTTP/prompt handler) that runs automatically at fixed lifecycle events (`PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, ...). Deterministic: enforced by the system regardless of what the model decides. Exit code 2 blocks the action. | [doc:hooks] |
| **CLAUDE.md / memory** | Persistent instruction files loaded at the start of every session: CLAUDE.md files you write (project/user/org scopes), plus auto memory (`MEMORY.md`, first 200 lines or 25KB) that Claude writes itself. Context, not enforced configuration. | [doc:memory] |
| **E1 — direct observation** | Changed behavior exercised end-to-end, in-session, on the final state. Full definition: `codofable-validation-and-qa`. | [repo] (Brief §3.3) |
| **E2 — automated test** | Test run in-session with output captured; for bug fixes: fails before, passes after. Home: `codofable-validation-and-qa`. | [repo] |
| **E3 — static verification** | Build/types/lint. Necessary, never sufficient. Home: `codofable-validation-and-qa`. | [repo] |
| **E4 — reasoning** | Plausibility argument. Hypothesis fuel only, never proof. Home: `codofable-validation-and-qa`. | [repo] |

## 2. Skill mechanics [doc-verified]

### 2.1 Where skills live [doc:skills]

| Location | Path | Applies to |
|---|---|---|
| Enterprise | via managed settings | all users in the organization |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | all your projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | this project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | where the plugin is enabled |

- Name collisions: enterprise overrides personal, personal overrides project. Plugin skills are namespaced `plugin-name:skill-name` and cannot collide. [doc:skills]
- Skills also load from nested `.claude/skills/` directories below the working directory (monorepo support) and from every parent directory up to the repository root. [doc:skills]
- Live change detection: edits to `SKILL.md` under watched skill directories take effect within the current session; creating a top-level skills directory that didn't exist at session start requires a restart. [doc:skills]
- This library lives at project scope: `.claude/skills/codofable-*` plus this skill. [repo]

### 2.2 Discovery and triggering [doc:skills]

The core mechanic, quoted-in-substance from the docs:

1. **Descriptions are always in context.** In a regular session, skill names and descriptions are loaded so Claude knows what's available. Full skill content loads only when invoked.
2. **The body loads on invocation** — either the model invokes the skill because the request matches the description, or the user types `/skill-name`.
3. Once invoked, the rendered body **enters the conversation as a single message and stays there for the rest of the session**; Claude Code does not re-read the file on later turns. Write standing instructions, not one-time steps.
4. `disable-model-invocation: true` → only the user can invoke; the description is not in context at all. `user-invocable: false` → only the model can invoke (background knowledge). [doc:skills]
5. **Description budget**: the skill listing gets a character budget scaling at 1% of the model's context window; when it overflows, least-used skills' descriptions are dropped first. Each entry's combined `description` + `when_to_use` text is truncated at 1,536 characters. Put the key use case first. Run `/doctor` (in-session command) to see which descriptions are shortened. [doc:skills]

Engineering consequence [craft]: the description is the only part of a skill guaranteed to be seen. A skill with a vague description is functionally invisible to the model; trigger phrases in the description are not decoration, they are the activation mechanism.

### 2.3 Frontmatter fields and constraints [doc:skills]

All fields optional; only `description` is recommended. Fields that matter for this library:

| Field | Constraint / behavior |
|---|---|
| `name` | Display name in listings; defaults to (and for normal skills, the command name comes from) the directory name |
| `description` | What the skill does and when to use it; if omitted, the first paragraph of the body is used; combined with `when_to_use`, truncated at 1,536 chars in the listing |
| `when_to_use` | Extra trigger context appended to the description; counts toward the same 1,536-char cap |
| `disable-model-invocation` | `true` = manual-only; also removes description from context and prevents preloading into subagents |
| `user-invocable` | `false` = hidden from the `/` menu; background knowledge |
| `allowed-tools` | Tools usable without permission prompts while the skill is active (grants, does not restrict) |
| `context: fork` + `agent` | Run the skill body as the prompt of a subagent instead of inline |
| `paths` | Glob patterns; skill auto-loads only when working with matching files |
| Malformed YAML | Body still loads with empty metadata; `/skill-name` works but the model has no description to match against. Run `claude --debug` to see the parse error |

Other documented fields (`argument-hint`, `arguments`, `model`, `effort`, `hooks`, `shell`, `disallowed-tools`) exist; see [doc:skills] before using them — do not guess semantics.

### 2.4 Size discipline — what the docs actually say [doc:skills]

- Explicit guidance: **"Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files."**
- "Keep the body itself concise. Once a skill loads, its content stays in context across turns, so every line is a recurring token cost. State what to do rather than narrating how or why."
- Supporting files (`references/*.md`, `examples/`, `scripts/`) do not load with the body; reference them from SKILL.md so Claude knows what each contains and when to load it.
- Compaction truncation keeps the **start** of the file, so put the most important instructions near the top of SKILL.md. [doc:context]

The Brief's 150–450 line target for this library [repo] is stricter than, and compatible with, the documented 500-line ceiling.

## 3. Context mechanics and their engineering consequences

### 3.1 What loads at session start [doc:context] [doc:memory] [doc:how-cc]

Before your first prompt, the context window already contains: the system prompt, environment info, git status, the CLAUDE.md hierarchy (managed policy → user `~/.claude/CLAUDE.md` → project `CLAUDE.md`/`.claude/CLAUDE.md` → `CLAUDE.local.md`, concatenated, walking up the directory tree), auto memory (first 200 lines or 25KB of `MEMORY.md`, whichever comes first), unscoped `.claude/rules/` files, the skill name+description listing, and MCP tool names (schemas deferred by default). CLAUDE.md content is delivered as a user message after the system prompt — it is context the model tries to follow, **not enforced configuration** [doc:memory]. Docs advise targeting under 200 lines per CLAUDE.md file; longer files reduce adherence [doc:memory].

### 3.2 What compaction does [doc:how-cc] [doc:context]

As the context window approaches its limit, Claude Code first clears older tool outputs, then summarizes the conversation. What survives, verbatim from the docs' table [doc:context]:

| Mechanism | After compaction |
|---|---|
| System prompt and output style | Unchanged (not part of message history) |
| Project-root CLAUDE.md and unscoped rules | Re-injected from disk |
| Auto memory | Re-injected from disk |
| Rules with `paths:` frontmatter | Lost until a matching file is read again |
| Nested CLAUDE.md in subdirectories | Lost until a file in that subdirectory is read again |
| Invoked skill bodies | Re-injected, capped at 5,000 tokens per skill and 25,000 tokens total; oldest dropped first |
| Hooks | Not applicable — hooks run as code, not context |

Also documented: if a single file or tool output is so large that context refills immediately after each summary, auto-compaction stops after a few attempts with a thrashing error instead of looping [doc:how-cc].

### 3.3 Engineering consequences [craft, derived from the doc facts above]

These are the mechanical reasons behind library doctrine. Cite the doctrine by number (per `codofable-change-control`); cite this section for *why*.

1. **Why N10 exists (re-verify after context loss).** After compaction, your "knowledge" of file contents, test results, and command outputs is a *summary written by a model under a token budget* — not the observations themselves. A summary is E4-class evidence at best. Any state you act on post-compaction must be re-established from the repo and filesystem (`git status`, `git diff`, re-read the file, re-run the check). The same applies after session restart, where nothing of the conversation survives at all ("Sessions are independent. Each new session starts with a fresh context window" [doc:how-cc]).
2. **Why skills must be self-contained.** A fresh Sonnet session loads a skill body with no authoring context, no sibling-skill bodies, and possibly a truncated 5,000-token version of the skill after compaction. Anything load-bearing must be inside the skill (top of file first) or reachable by an explicit relative path or sibling-skill name — never "as discussed above."
3. **Why long sessions drift.** Documented: "instructions from early in the conversation can get lost" during compaction, and an invoked skill "seems to stop influencing behavior" while technically still present as the model favors other approaches [doc:how-cc] [doc:skills]. Countermeasures: put persistent rules in CLAUDE.md (re-injected from disk), re-invoke important skills after compaction, and use hooks when a behavior must be deterministic rather than persuaded.
4. **Why "one home per fact."** Duplicated doctrine costs recurring tokens in every session that loads both copies, and duplicated copies drift independently with no mechanism to reconcile them. Cross-referencing by skill name costs a single line and survives compaction because the target lives on disk, not in context.
5. **Why evidence must be captured in-session (N1).** Tool outputs are the first thing cleared under context pressure [doc:how-cc]. An output you observed but did not quote into your working notes or final report may be gone by the time you claim "done."

## 4. Subagents and orchestration mechanics [doc:subagents]

Mechanics only — when to spawn, briefing discipline, and review pyramids live in `codofable-orchestration`.

- **Fresh context per agent.** "Each subagent starts with a fresh, isolated context window. It doesn't see your conversation history, the skills you've already invoked, or the files Claude has already read." Its initial context is: its own system prompt (not the full Claude Code one) + the delegation message the orchestrator writes + CLAUDE.md/memory hierarchy + a git-status snapshot from parent-session start + any preloaded skills. Exception: the built-in Explore and Plan agents skip CLAUDE.md and git status; a *fork* inherits the whole parent conversation instead of starting fresh.
- **Report-back.** The subagent works independently and only its final message returns to the main conversation; its intermediate tool calls and file reads never touch the parent context. This is the context-isolation payoff — and the risk: the orchestrator sees a *claim*, not the evidence behind it. Documented caution: many subagents each returning detailed results can still consume significant parent context.
- **Parallelism.** Independent subagents can run simultaneously ("parallel research" pattern); subagents run in the background by default as of v2.1.198, with permission prompts surfacing in the main session. Nested spawning is allowed to a fixed depth: an agent at depth five doesn't receive the Agent tool and can't spawn further.
- **Continuation.** Each invocation is a new instance with fresh context; resuming an existing subagent (via SendMessage / asking Claude to continue it) retains its full history. Explore and Plan are one-shot and cannot be resumed.
- **Preloaded skills.** A subagent definition's `skills` field injects full skill content at startup — the one case where a skill body loads without description-triggering [doc:skills] [doc:subagents].

Consequence [craft]: a subagent's "done" is an unverified claim in the orchestrator's context. Per N1 and the evidence hierarchy (`codofable-validation-and-qa`), the orchestrator must either require evidence in the report-back or re-verify independently. This is doctrine in `codofable-orchestration`; the mechanics above are why it is non-optional.

## 5. Harness control surfaces: permissions and hooks (one screen)

What a skill author must know; full treatment is the cited docs, and this library's own gates live in `codofable-change-control`.

- **Permission rules** are `allow` / `ask` / `deny` lists in settings files, evaluated deny → ask → allow, first match wins; a deny at any settings level cannot be overridden by an allow anywhere else. Syntax `Tool` or `Tool(specifier)`, e.g. `Bash(npm run *)`, `Read(./.env)`, `WebFetch(domain:example.com)`. Precedence of settings sources: managed > CLI args > `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.json`. [doc:permissions]
- **Rules are enforced by Claude Code, not by the model.** "Instructions in your prompt or CLAUDE.md shape what Claude tries to do, but they don't change what Claude Code allows." [doc:permissions]
- **Permission modes** (cycled with Shift+Tab in the terminal): `default`, `acceptEdits`, `plan` (read-only exploration), `auto` (research preview), `dontAsk`, `bypassPermissions`. [doc:permissions] [doc:how-cc]
- **Hooks** are the deterministic layer: shell commands at fixed lifecycle events (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`, `SessionEnd`, `SubagentStart`, `SubagentStop`, `PreCompact`, `PostCompact`, and others), configured in settings files or skill/agent frontmatter. Exit code 2 blocks the action; a blocking hook takes precedence over allow rules. [doc:hooks] [doc:permissions]
- Design rule of thumb [craft], consistent with [doc:memory]: use CLAUDE.md/skills for behavior you want *shaped*, permissions/hooks for behavior that must be *guaranteed*. A skill can urge N2 ("never weaken verification"); only a hook or deny rule can make its violation impossible.

## 6. Model-tier reality [craft]

No benchmark numbers are cited here because none were verified against a document; this section is the fellow's professional judgment, labeled as such, and it is the design premise of the entire library.

**Observed difference in kind.** A top-tier (Fable-class) session tends to *infer procedure from sparse instruction*: given "fix the bug," it independently reproduces first, distrusts its own first hypothesis, re-verifies after compaction, and notices when a passing test doesn't actually exercise the change. A mid-tier (Sonnet-class) session executes *explicit* procedure reliably and cheaply, but fills fewer gaps on its own: unstated steps are skipped more often, "looks plausible" is more often accepted as "verified" (E4 treated as E1 — the project's named hardest failure mode, per the Brief), and recovery from a wrong path takes longer without a decision table pointing at the exit.

**The design consequence: this library converts judgment into procedure.** Everything an expert "just does" is externalized into forms a procedure-follower executes well:

| Expert judgment (implicit) | Library artifact (explicit) |
|---|---|
| "I should double-check this actually works" | Evidence classes E1–E4 + the E1/E2-required rule (`codofable-validation-and-qa`) |
| "This change feels risky" | Change classes R/1/2/3 with mandatory gates (`codofable-change-control`) |
| "I've seen this failure shape before" | Symptom→cause tables (`codofable-debugging-playbook`, `codofable-failure-archaeology`) |
| "I don't trust my memory after that compaction" | N10 as a mechanical rule, justified in Section 3.3 |
| "I'll just measure it" | Runnable scripts and recipes (`codofable-diagnostics-and-tooling`, `codofable-proof-and-analysis-toolkit`) |

Authoring implications for every skill in this library [craft]: imperative checklists over prose; copy-pasteable commands over descriptions of commands; decision tables with explicit exits; trigger-rich descriptions (Section 2.2 — the description is the activation mechanism); most important content at the top (Section 2.4 — truncation keeps the start). Whether the library measurably lifts a Sonnet-class session is an **open, falsifiable question** — the experiment design belongs to `codofable-research-frontier` and `codofable-research-methodology`; do not present uplift as established.

## Provenance and maintenance

- **Date stamp:** all `[doc:*]` facts verified 2026-07-05 by fetching the seven URLs in the tag table at the top of this file. Claude Code documentation is volatile (many facts carry "as of v2.1.x" markers in the source pages); numbers most likely to drift: 500-line SKILL.md guidance, 1,536-char description cap, 1% listing budget, 5,000/25,000-token compaction caps, 200-line/25KB memory limits, subagent depth limit, background-by-default behavior.
- **Evidence classes used:** [doc] = the cited official page; [repo] = this repository's files (Brief-mandated doctrine, the two-commit history, this library's paths); [craft] = the fellow's judgment, always labeled inline (Sections 3.3, 5 design rule, and all of Section 6).
- **Re-verification:** re-fetch any tag-table URL and diff against the relevant section. In-session: run `/context` (context usage), `/memory` (loaded CLAUDE.md/memory files), `/doctor` (skill-description truncation) — these are Claude Code in-session commands, not shell commands. Shell check that this library's skills are where Section 2.1 says: `ls .claude/skills/` from the repo root (run in this sandbox 2026-07-05).
- **Known gaps (honest):** the docs pages fetched did not state an exact auto-compaction trigger threshold percentage or the numeric subagent parallelism ceiling; where this file says "approaches the limit" or "fixed depth," that is the docs' own level of precision. Do not invent numbers to fill these gaps.
