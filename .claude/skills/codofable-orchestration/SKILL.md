---
name: codofable-orchestration
description: Multi-agent workflow craft — when to spawn subagents vs work inline, how to brief them (shared canonical brief pattern), write-scope isolation for concurrent agents, the author→reviewer→fixer review pyramid, and fan-out/fan-in mechanics. Load this skill when you are about to delegate work to subagents, split a task across parallel agents, design a review pass over generated artifacts, or when an orchestrated run produced duplicated work, contradictory outputs, or agents that invented context. Trigger phrases: "spawn agents", "parallel subagents", "split this across workers", "orchestrate", "fan out", "review pyramid", "should I use a subagent for this", "the agents stepped on each other".
---

# codofable-orchestration

This skill teaches how to decompose work across subagents without the classic failure modes: duplicated work, forked doctrine, collisions on shared files, under-briefed agents inventing facts, and reviewers rubber-stamping. It covers the spawn decision, briefing discipline, write-scope isolation, the review pyramid, and fan-out/fan-in mechanics. The running worked example is this library itself: it was authored by parallel agents reading one canonical brief, each with an exclusive write scope, then reviewed by parallel specialized reviewers and repaired by a single fixer — the pattern is visible in the repo's own manifest and directory structure [repo].

Definitions (used throughout): an **orchestrator** is the session that decides the plan and spawns workers. A **subagent** is a worker session spawned by the orchestrator; it starts with its own empty context window, works independently, and returns only its final report to the orchestrator [doc: https://code.claude.com/docs/en/sub-agents]. A **brief** is the written instruction package a subagent receives.

## When to use this skill

- You are deciding whether to delegate a task to a subagent or do it inline.
- You have a task that splits into several independent units (author N documents, migrate N modules, investigate N hypotheses) and want to parallelize.
- You are designing a review pass over a large set of generated or edited artifacts.
- A previous multi-agent run failed: agents overwrote each other, produced contradictory content, invented facts, or a reviewer passed everything without findings.
- You are writing the prompt (brief) for a subagent and want the checklist of what it must contain.

## When NOT to use this skill

| Situation | Use instead |
|---|---|
| You need the mechanics of subagents themselves — context windows, tool access, permissions, nesting, foreground/background flags | `agentic-engineering-reference` |
| You need to know what evidence a reviewer should demand for a "done" claim, or the evidence hierarchy E1–E4 | `codofable-validation-and-qa` |
| You need change classes and gates for the edits the agents will make | `codofable-change-control` |
| You are diagnosing a specific past multi-agent incident (e.g. the concurrent-write collision pattern) | `codofable-failure-archaeology` |
| The task is a single sequential piece of work with no independent units | Do it inline; this skill's first section tells you why |

## The spawn decision [craft]

A subagent starts cold: it knows nothing you have not written into its prompt. That single fact drives the whole decision.

Spawn a subagent when at least one of these holds:

1. **Parallelizable independent units.** The work splits into units that do not read each other's output and do not write the same files. N units → N agents running concurrently. This library's authoring phase is the example: a set of skills, none depending on another's text, each written by its own agent into its own directory [repo — one directory per skill under `.claude/skills/`].
2. **Context isolation for large reads.** The task requires reading volumes of material (logs, test output, many files) that would flood your conversation but whose details you will never need again — only the conclusion. The subagent absorbs the bulk in its own context window and returns a summary [doc: https://code.claude.com/docs/en/sub-agents].
3. **Adversarial or fresh-eyes review.** You want an evaluation untainted by the context that produced the artifact. A fresh agent has no memory of the author's intentions and no incentive to justify choices it never made. See "The review pyramid" below.

Do NOT spawn when any of these holds:

1. **Sequential dependent steps.** If step 2 needs step 1's output, agents add hand-off overhead and information loss at each boundary. Do it inline, or run agents in sequence only if each step also qualifies under reason 2 above.
2. **The task needs the full conversation context.** If briefing the agent means transcribing most of what you already know — the user's constraints, the investigation so far, the half-formed plan — the transcription will be lossy and the agent will fill gaps by inventing. Do it inline.
3. **The briefing-cost rule: if writing an adequate brief takes longer than doing the task, do it inline.** An agent that saves you 3 minutes of work but costs 10 minutes of brief-writing plus review of its output is a net loss. This rule dominates for small tasks; parallelism only pays when unit work is large relative to briefing cost.

Decision table:

| Task shape | Verdict |
|---|---|
| 10 independent files to author/migrate, same rules for all | Spawn: one shared brief, N agents |
| Read 5,000 lines of logs, answer one question | Spawn: context isolation |
| Review artifacts you just wrote | Spawn: fresh eyes (never review your own work as the sole gate) |
| 3 steps where each consumes the previous step's output | Inline |
| Fix a typo, rename a variable, one small edit | Inline (briefing-cost rule) |
| Task needs judgment calls grounded in the whole conversation | Inline |

## Briefing discipline [craft]

### The shared canonical brief pattern

When N agents work under the same rules, put the rules in **one file that every agent is instructed to read in full before acting**, and keep each agent's individual prompt to a short charter layered on top ("your unit is X; write only in Y; everything else is in the brief").

Why one file instead of N copies pasted into N prompts: doctrine cannot fork. If you paste the rules N times, you will edit one copy and not the others, or paraphrase differently per agent, and the agents' outputs will contradict each other in ways no single agent can detect. One canonical file means one source of truth, and a mid-run correction (edit the file, re-run affected agents) propagates everywhere.

This library was built this way: one canonical authoring brief containing the doctrine (the non-negotiables, the evidence hierarchy, the format contract, the skill inventory for cross-references), read by every authoring agent, with a per-agent charter naming its one skill and its write scope [repo — the uniformity is observable: every `SKILL.md` under `.claude/skills/` carries the same frontmatter shape, section order, and cites the same doctrine by the same names].

### What every brief must contain

Checklist — a brief missing any of these produces a guessing agent:

1. **Ground-truth facts.** The verified facts the agent needs, stated as facts, with an explicit boundary: "do not invent more." Include what the agent might otherwise assume wrongly (e.g. "this repo has exactly two commits; there is no CI; there are no issues").
2. **Binding constraints.** The rules the output must satisfy, including the doctrine it must not contradict and any format contract. Cite canonical sources by name rather than paraphrasing them (per the one-home-per-fact rule in `codofable-docs-and-writing`).
3. **Write scope.** The exact files/directories the agent may write, stated as a hard limit. See the next section.
4. **Definition of done.** A checkable list: what must exist, what must be verified, what "complete" means. Not "write good documentation" but "SKILL.md exists at path P with valid frontmatter, every command run in-session or marked generic".
5. **Report-back format.** What the final report must contain: paths written, commands actually executed, and — critically — **claims the agent could NOT verify**. Requiring a could-not-verify list converts silent guesses into flagged review items. An agent that reports "I could not verify X" has done its job; an agent that states X as fact without verifying has poisoned the downstream phases. This is N1 and N8 applied to delegation (per `codofable-change-control`).

### Briefing anti-pattern

Do not brief by vibes ("write a skill about debugging, you know the drill"). The agent does not know the drill — it starts cold. Every assumption you leave implicit is a fact the agent will invent. This is the **context starvation** failure mode in the table below.

## Write-scope isolation [craft]

**Rule: every concurrently running agent gets a disjoint file/directory scope, stated in its prompt as a hard limit** ("Write ONLY inside directory D. Everything else is read-only. No mutating git commands.").

Why a hard limit in the prompt, not an informal expectation: two agents editing the same file concurrently produce silent lost updates — the second write wins and nobody errors. Concurrent mutating git operations (add/commit/checkout) on one working tree corrupt each other's view of the index. The only reliable prevention is scopes that cannot overlap, declared where the agent cannot miss them. Cross-reference: the multi-agent collision entry in `codofable-failure-archaeology` documents this failure pattern.

Design guidance:

- Partition by directory, not by file list, when possible — "your directory is `.claude/skills/<your-skill>/`" is harder to misread than a list of 7 files.
- The shared brief and all reference material are read-only for everyone.
- Reserve all git state mutation (staging, committing) for the orchestrator, after all agents finish. Agents produce working-tree changes only.
- If two units genuinely need to touch the same file, they are not independent units — merge them into one agent or sequence them.

This library's layout is the worked example: one authoring agent per skill, one directory per skill under `.claude/skills/`, so collisions were impossible by construction [repo — `ls .claude/skills/` shows one directory per skill].

## The review pyramid [craft]

Structure for reviewing a large batch of agent-produced artifacts:

```
  Layer 1: N author agents           (produce the artifacts, disjoint scopes)
  Layer 2: K parallel reviewers      (read EVERYTHING, different lens each, write findings)
  Layer 3: 1 fixer                   (applies findings by severity, single writer)
  Layer 4: orchestrator spot-check   (samples the fixed output; final gate)
```

### Reviewers must be different agents from authors

An author reviewing its own artifact re-reads it through the context that produced it: it knows what it *meant*, so it sees what it meant instead of what it wrote, and it is structurally inclined to justify its own choices rather than find them wrong. A fresh reviewer has none of that context — it can only evaluate what is actually on the page, which is exactly what the next zero-context reader will experience. Self-review is a Class-1 gate at best (per `codofable-change-control`); independent review is a different and stronger check.

### Different lenses, defined by their question

Reviewers with the same lens duplicate each other. Give each reviewer ONE question:

| Lens | The question it asks of every artifact |
|---|---|
| **Factual** | Is every command, path, flag, and citation actually true — re-verifiable against the repo/docs right now? Severity: would the error send an engineer down a wrong path? |
| **Doctrine** | Does anything contradict the canonical rules, or another artifact in the set? Is any claim overstated relative to its evidence? Does anything route around required gates? |
| **Usability** | Will the zero-context target reader find, load, and successfully follow this? Are triggers/descriptions good, is each fact stated in exactly one home, is it scannable and self-contained? |

This three-lens split (factual / doctrine / usability, then one fixer) is the review design specified in this repo's own manifest [repo — `README.md` Phase 3].

### The fixer is one agent, not three

Findings from all reviewers funnel to a single fixer so that fixes cannot collide (the write-scope rule again: during the fix phase, the fixer is the only writer). The fixer applies findings in severity order — blocking first, then important; cosmetic findings are optional. The fixer does not re-litigate findings it dislikes; if a finding seems wrong, it reports the disagreement to the orchestrator rather than silently dropping it.

### The orchestrator spot-check

The orchestrator never forwards "reviewers passed it" as its own claim without sampling. Pick a few artifacts, re-verify a few of the most load-bearing claims directly. Per N1, "the reviewer said it's fine" is a report, not evidence; what evidence a spot-check should demand is defined in `codofable-validation-and-qa`.

## Fan-out/fan-in mechanics [craft]

1. **Launch parallel agents in one batch.** Issue all independent spawn calls together rather than one-per-turn. Sequential launching serializes what should be concurrent and invites you to tweak later briefs mid-run, forking doctrine (the fix for a discovered brief problem is: edit the canonical brief, then re-run affected units — not: improve prompts silently from agent 7 onward).
2. **Background vs synchronous.** Run agents in the background when you have other work to do meanwhile; run synchronously (wait for the result) only when your very next action depends on that result [doc: https://code.claude.com/docs/en/sub-agents — background subagents run concurrently; foreground is for results needed before continuing]. Exact flags and tool parameters: `agentic-engineering-reference`.
3. **The orchestrator's job while agents run: prepare the next phase, never idle-poll.** While authors run, draft the reviewer briefs and the findings-file format. While reviewers run, prepare the fixer's severity rubric. Repeatedly asking "are you done yet" burns context and adds nothing — completion arrives as a notification/report.
4. **Fan-in: collect reports against the definition of done.** For each agent, check its report against the brief's definition-of-done checklist and its could-not-verify list. Do not read reports as prose; read them as checklists.
5. **Handling a failed or nonconforming agent: re-brief and re-run that unit only.** If one agent's output violates the contract (wrong path, missing sections, invented facts), do not patch it yourself in a hurry and do not re-run the whole batch. Diagnose whether the fault was the brief (ambiguity → fix the brief, since other agents may have silently hit the same ambiguity) or the agent (ignored a clear instruction → re-run with the same brief plus a pointed correction). One unit re-run is cheap precisely because units are independent.

## Orchestration failure modes [craft]

| Failure mode | Symptom | Root cause | Prevention |
|---|---|---|---|
| Duplicated work | Two agents produce overlapping content; a fact has two conflicting homes | Unit boundaries not disjoint; no per-unit charter | Partition the work explicitly; each brief names its unit AND what belongs to siblings (cross-reference, don't restate) |
| Context starvation | Agent output contains plausible invented facts, wrong paths, imaginary history | Under-briefed agent filled gaps by guessing — a cold-start agent cannot distinguish "unknown" from "unstated" | Brief checklist above: ground-truth facts with a "do not invent more" boundary; require a could-not-verify list in the report |
| Doctrine fork | Artifacts contradict each other on rules/terminology; no single agent's output is wrong in isolation | Rules pasted per-prompt instead of one shared brief; or brief edited mid-run without re-running earlier agents | Shared canonical brief file; mid-run corrections edit the brief and re-run affected units |
| Write collision | Lost edits, corrupted git state, file content from agent A vanishes after agent B finishes | Overlapping write scopes among concurrent agents | Disjoint scopes as hard limits in every prompt; orchestrator owns git state; see `codofable-failure-archaeology` |
| Reviewer rubber-stamping | Reviewer returns "all good" with zero findings over a large artifact set | Review framed as approval, not as finding-hunting; passing is the low-effort output | Require findings-or-explicit-pass PER FILE: for every artifact, the reviewer must list findings or state "PASS: <artifact> — checked <what>". A global "looks fine" is a nonconforming report — re-run that reviewer |
| Lost reports | Orchestrator cannot reconstruct what was found or fixed; fixer works from memory of chat summaries | Findings existed only as transient chat text | Reviewers write findings to files at agreed paths in an agreed format (artifact, finding, severity, evidence); the fixer reads files, not paraphrases |
| Zombie unit | One agent's failure stalls the whole run or gets silently forgotten | No per-unit done-check at fan-in | Fan-in checklist per unit; re-brief and re-run failed units individually |

## Provenance and maintenance

- Date-stamped 2026-07-05.
- [repo] claims: this repository's `README.md` (commit `c321e16`) specifies the pattern documented here — Phase 2 "parallel agents, one skill per agent" and Phase 3 "Three parallel reviewers over the complete set, then one fixer" with the factual/doctrine/usability lenses; the directory-per-skill layout under `.claude/skills/` is the write-scope isolation evidence. Re-verify: `git -C <repo> show c321e16:README.md | grep -n "parallel"` and `ls .claude/skills/`.
- [doc] claims about subagent mechanics (own context window; independent work returning a final report; concurrent background execution; foreground for results needed immediately) verified 2026-07-05 against https://code.claude.com/docs/en/sub-agents. These are volatile — Claude Code versions change defaults; re-verify against that page before relying on version-specific behavior, and use `agentic-engineering-reference` for the mechanics themselves.
- [craft] everything else: the spawn-decision heuristics, briefing checklist, review-pyramid design, and failure-mode table are the fellow's professional judgment, illustrated by (not derived from) this library's build. The library's own build was a single successful run, not a controlled experiment; treat effect-size claims about this pattern as candidate, not proven (per N8).
- Commands in this skill are patterns unless noted: `ls .claude/skills/` and the `git show` line above were run in-session on 2026-07-05; everything else is process description, not runnable commands.
