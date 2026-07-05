---
name: codofable-research-frontier
description: Open research problems where this skill library could advance the state of the art in measurable model uplift. Load this skill when someone asks "does this library actually work?", "how would we prove the skills help?", "what experiments should we run?", "what are the open problems / research directions?", or wants to design an A/B test of a Sonnet-class session with vs. without the library, measure skill-routing accuracy, mechanize provenance drift detection, or test cross-model transfer. Provides, per problem: why current approaches fail, this project's specific asset, the first three concrete steps in this repo, and a falsifiable "you have a result when…" milestone. Contains ZERO achieved results — every item is labeled open or candidate. Not for experiment-execution methodology (codofable-research-methodology) or public claims about results (codofable-external-positioning).
---

# codofable-research-frontier — open problems in measurable skill uplift

This skill is the project's research agenda. The owner's binding definition of "beyond state of the art" is MEASURABLE MODEL UPLIFT: the frontier goal is experiments that measure whether a Sonnet-class session equipped with this library outperforms one without it. Every problem below is stated as: why current approaches fail, what asset this project has that others lack, the first three concrete steps *in this repository*, and a falsifiable milestone. Nothing in this skill is an achieved result. Every problem is status **open** and every proposed design is status **candidate**, per N1 and N8 (see `codofable-change-control` for the non-negotiables). A rigorous null result — "the library does not help" — counts as a result here; this agenda is falsification-friendly by construction.

## When to use this skill

Load this skill when:

- Someone asks whether the library "actually works", "helps", or "improves the model" — the honest answer as of 2026-07-05 is "unknown; here is the experiment that would tell you", and this skill contains that experiment.
- You are asked to design, scope, or estimate the uplift A/B experiment (with-library vs. without-library sessions).
- You are asked what the open problems, research directions, or "frontier" of this project are.
- You are extending the task battery, the A/B harness definition, or any probe suite described here.
- You are asked whether skill descriptions actually trigger loading at the right time (routing), how to detect stale skills mechanically (drift), or whether the library transfers to non-Claude model families (cross-model).
- You are writing a grant-style or roadmap-style summary of what this project could contribute beyond existing coding benchmarks.

## When NOT to use this skill

| If you need… | Use instead |
|---|---|
| The *discipline* for running any experiment: hypothesis-predicts-numbers, pre-registration, adversarial refutation, idea lifecycle | `codofable-research-methodology` |
| To make a public or external claim about results, novelty, or comparisons | `codofable-external-positioning` |
| Flakiness statistics, N-runs math, performance measurement recipes | `codofable-proof-and-analysis-toolkit` |
| The evidence hierarchy (E1–E4) and what counts as proof of "done" | `codofable-validation-and-qa` |
| Runnable diagnostic scripts (library validator, repo recon) | `codofable-diagnostics-and-tooling` |
| The catalog of agentic failure modes that the task battery encodes | `codofable-failure-archaeology` |
| Multi-agent execution of an experiment (spawning graders, isolating cells) | `codofable-orchestration` |
| To change doctrine or gates based on a finding | `codofable-change-control` (findings never route around gates) |

## Ground rules for this agenda

1. **Status vocabulary (per N8).** "Open" = the problem is real and unsolved here. "Candidate" = a specific design proposed but never executed. There is no third status in this file. If you execute something and get a result, the result does NOT get recorded here as fact — it goes through `codofable-research-methodology`'s idea lifecycle and, if adopted, lands in the skill that owns it, with this file updated to point at it.
2. **Pre-register before you run.** Every experiment below requires pre-registered thresholds, metrics, and analysis per `codofable-research-methodology`, written down *before* the first measured run. An experiment whose success criteria were chosen after seeing data is not a result, it is a story.
3. **A null is a result.** Each milestone below is worded "in either direction" deliberately. Discovering that the library does not measurably help is publishable-grade knowledge for this project and triggers redesign, not burial.
4. **This repo's pre-library history is two commits; everything after is library authoring.** [repo] Do not cite project history as evidence for anything in this file; there is none. The evidence base is external literature (cited, with its verification status labeled) and first-principles reasoning ([craft], labeled).

## Problem register (all open, as of 2026-07-05)

| # | Problem | One-line question | Flagship? |
|---|---|---|---|
| P1 | The uplift experiment | Does a Sonnet-class session with this library outperform one without, on pre-registered metrics? | **Yes** |
| P2 | Skill routing optimization | Do trigger descriptions cause skills to load when needed — and stay unloaded when not? | No |
| P3 | Drift detection mechanization | Can a machine detect that a skill's facts have gone stale before a human notices? | No |
| P4 | Cross-model transfer | Does a library authored by one frontier model lift *other* model families? | No |
| P5 | Library ablation | Which skills carry the uplift — does the effect decompose? | No |

P1 is the flagship because the owner's Phase-1 answer defines the project's frontier as exactly this measurement. P2 is a validity precondition for P1 (an unloaded skill cannot cause uplift). P5 and P4 only make sense after P1 produces a non-null.

---

## P1 — The uplift experiment (flagship) — status: open; design: candidate

**Question.** Take the same model, the same tasks, the same harness. Vary exactly one thing: presence of this skill library. Does the with-library cell perform measurably better on task success, discipline-violation count, and false-"done" rate?

### Why current approaches fail

- **Eyeballing fails.** "The session felt more careful" is E4 evidence (reasoning/plausibility — see `codofable-validation-and-qa`); the project's own doctrine forbids accepting it, and single-observer impressions cannot detect effects smaller than dramatic. [craft]
- **Generic coding benchmarks are contaminated.** SWE-bench Verified and its source repositories are public and heavily discussed; OpenAI announced it stopped reporting the benchmark, citing contamination difficulty and a manual audit in which the majority of examined model failures traced to test flaws rather than model limitations (⚠ unverified — [craft, pending doc]: https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/). Independent analysis (SWE-Bench+) reports widespread solution leakage — the fix visible or hinted in the issue text — and weak test suites that let wrong patches count as resolved (⚠ unverified — [craft, pending doc]: https://arxiv.org/abs/2410.06992). Further work found models reproducing benchmark-specific details from memory rather than reasoning (⚠ unverified — [craft, pending doc]: https://arxiv.org/html/2506.12286v4). All three sources were reached via web search only — the hosts were unreachable from the authoring sandbox; fetch and read them before citing onward. A contaminated benchmark cannot isolate the effect of a skill library: memorized solutions swamp the treatment.
- **They measure the wrong dimension anyway.** Public benchmarks score patch-passes-tests. This library's central claims are about *craft discipline*: not claiming done without E1/E2 evidence, not weakening tests, smallest-correct-change, honest uncertainty. No public benchmark scores "did the agent admit it could not verify?" — on SWE-bench-style scoring, an honest "cannot verify" is indistinguishable from failure, which *penalizes* exactly the behavior this library teaches. [craft]
- **Single runs are noise.** Agentic sessions are high-variance; one run per cell measures luck. The statistics for choosing N and separating flakiness from effect live in `codofable-proof-and-analysis-toolkit` — use them, do not improvise.

### This project's specific asset

A clean, doctrine-versioned library with mechanical hooks that generic benchmarks lack: [craft]

- The doctrine is *enumerable* (N1–N10, change classes, E1–E4), so violations can be defined as detectable transcript events rather than vibes.
- The library is *versioned in git*, so the treatment is a pinned, reproducible artifact — "the library at commit X", not "some prompts".
- The hardest failure mode is *named in advance* (false "done" claims — the owner's Phase-1 answer), so the primary metric was chosen before any data existed. That is pre-registration by circumstance, and it should be locked in formally before the first run.
- Tasks can be *authored fresh* against the failure catalog in `codofable-failure-archaeology`, post-dating every model's training data, killing the contamination objection by construction.

### First three steps in this repo

1. **Finalize the task battery spec.** A candidate draft ships with this skill at [references/uplift-task-battery.md](references/uplift-task-battery.md): task classes keyed to failure modes (a bug with a tempting wrong fix; a task where honest "cannot verify" is the correct output; a flaky-test judgment call; a false-"done" bait), each with pre-registered pass criteria, machine-checkable wherever possible. Review it against `codofable-failure-archaeology`'s catalog, close its marked TODOs, and get it through a Class 1→2 review per `codofable-change-control` before treating it as the battery of record.
2. **Define the A/B harness as a written protocol** (a `references/uplift-harness.md` to be authored — deliberately not drafted here because harness mechanics must follow the finalized battery). Required cell structure, candidate: same model and version pinned; same tasks; cell A = bare session, cell B = session with the library at a pinned commit; N runs per cell with N chosen via `codofable-proof-and-analysis-toolkit` flakiness math; metrics = (i) task success against the battery's machine-checkable criteria, (ii) violation count — N1–N10 violations detectable from transcripts, (iii) false-"done" rate — "done"/"fixed"/"passing" claims not backed by in-transcript E1/E2 evidence. Include the confound controls listed in the battery spec (token-count placebo, blinded grading).
3. **Pre-register thresholds before any measured run**, per `codofable-research-methodology`: the minimum effect size that counts, the N per cell, the exact analysis, and the abort criteria — committed to the repo (Class 2 change: it alters what future sessions may claim) before run one. Pilot runs to debug the harness are permitted but must be labeled pilots and excluded from analysis.

### You have a result when…

> The pre-registered analysis of ≥N runs per cell (N fixed in step 3) shows a difference between cells exceeding the pre-registered threshold — **in either direction** — on at least one primary metric, with the analysis executed exactly as registered. A rigorous null (difference below threshold with adequate N) is equally a result. Anything short of this — anecdotes, pilot runs, post-hoc metric selection — is not a result and may not be described as one (N1, N8).

---

## P2 — Skill routing optimization — status: open; design: candidate

**Question.** The entire library is inert unless sessions load the right skill at the right moment. Do the frontmatter descriptions actually cause that?

### Why current approaches fail

- **The mechanism is indirect by design.** In Claude Code, skill descriptions sit in context while the body loads only on invocation; the model decides when to invoke, guided by the description (combined description text is truncated at 1,536 characters in the skill listing). [doc] https://code.claude.com/docs/en/skills (verified 2026-07-05)
- **Negatives are invisible.** There is no dedicated hook event for "skill should have loaded but didn't"; the docs describe no built-in routing telemetry. Invocations can be observed (e.g., via a PreToolUse hook — [doc] https://code.claude.com/docs/en/hooks), but a *missed* load leaves no trace at all. Today, routing quality is assessed by anecdote — which is E4. [craft]
- **Description authoring is folklore.** "Trigger-rich" is the house rule, but no one has measured whether any specific description phrasing changes load rates. [craft]

**Asset.** Sixteen skills with deliberately trigger-rich descriptions, a fixed inventory (the 16 names in the repo `README.md` manifest are final; `ls .claude/skills/` lists them), and an explicit "When to use / When NOT to use" contract in every skill — i.e., ground-truth routing labels already exist for every skill; they just have not been tested against behavior. [craft]

### First three steps in this repo

1. Author a probe suite: for each skill, ≥5 "should-load" scenarios (prompts a real session would receive, drawn from that skill's own "When to use" section) and ≥5 "should-NOT-load" scenarios (prompts belonging to a sibling). Store as a table in this skill's `references/` (file to be created: `routing-probes.md`).
2. Define the measurement: run each probe in a fresh session; record whether the target skill was invoked (observable via transcript or a PreToolUse logging hook). Metrics: false-negative rate (needed, not loaded) and false-positive rate (loaded, not needed) per skill.
3. Pre-register acceptable rates and the improvement loop: if a skill's false-negative rate exceeds threshold, edit its description (Class 2 change — descriptions are behavior-changing for the library), re-run the probes, and record before/after.

### You have a result when…

> False-negative and false-positive load rates are measured over the full probe suite with pre-registered N per probe, AND at least one description edit produces a pre-registered-direction change in those rates on re-run. Knowing the rates precisely — even if they are bad — is the result; improving them is the follow-on.

---

## P3 — Drift detection mechanization — status: open; design: candidate

**Question.** Every skill ends with a Provenance section containing re-verification one-liners because facts drift (paths move, docs change, flags rename). Today re-verification is manual and therefore will not happen. Can a machine detect drift before a human notices?

### Why current approaches fail

- Manual re-verification decays to never: it has no owner, no schedule, and no failure signal. A stale runbook is worse than none — it sends an engineer confidently down a wrong path (the repo README's own ground-truth rule). [repo]
- Doc-freshness tooling in the wild checks link liveness, not *claim truth*: a URL that still resolves can document behavior that changed. [craft]

**Asset.** The library's format contract *requires* a Provenance section with one-line re-verification commands in every skill — machine-extractable by construction. The library also ships a validator in `codofable-diagnostics-and-tooling`. The raw material for a drift checker already exists in a uniform format; no other prompt library imposes this. [craft]

### First three steps in this repo

1. Extract the Provenance one-liners into a runnable manifest. Extraction pattern (generic pattern — run from the repo root; siblings were still being authored when this was written, so verify output before trusting it):

   ```bash
   for f in .claude/skills/*/SKILL.md; do
     echo "## $f"
     awk '/^## Provenance/,0' "$f" | grep -E '^\s*(\$|`|- `|```)?\s*[a-z][a-z0-9_-]+ ' 
   done
   ```

   Expect noise; the real deliverable is a curated `drift-manifest` file (one command + expected-output assertion per line) proposed to live under `codofable-diagnostics-and-tooling`'s `scripts/` — coordinate with that skill's owner rather than duplicating (one home per fact).
2. Write the drift-check runner: execute each manifest line, compare against the recorded expectation, emit pass/DRIFT per skill. Exit nonzero on any DRIFT so it can gate CI later.
3. Run a **seeded-drift trial**: deliberately plant one stale fact (in a scratch copy of a skill, never in the live library without a Class 2 gate) and confirm the runner flags it and a naive human read-through misses it under time constraint.

### You have a result when…

> The runner detects a seeded drift with zero human hints, and detects at least one *natural* drift (a real fact that went stale on its own) before any human review reports it. Until a natural catch occurs, the seeded-trial pass is a candidate capability, not a result.

---

## P4 — Cross-model transfer — status: open; design: candidate

**Question.** This library is authored by one frontier model (Fable 5) explicitly so that cheaper successors can use it. Does the uplift — if P1 finds any — transfer to model families that share none of the author's training lineage?

### Why current approaches fail

- Prompt-engineering findings notoriously fail to replicate across model families; phrasing tuned on one model can be neutral or harmful on another. Treat this as a [craft] hypothesis to be tested, not established fact — do not cite it as literature without finding the citation first.
- If uplift only appears within the authoring model's own family, the mundane explanation is stylistic self-compatibility (the library is written in the author's "dialect"), not transferable engineering craft. No existing eval separates these. [craft]

**Asset.** The library's doctrine is deliberately model-agnostic: numbered rules, evidence classes, checklists, and copy-pasteable commands rather than model-specific incantations. The skill format follows an open standard supported across tools ([doc] https://code.claude.com/docs/en/skills states Claude Code skills follow the Agent Skills open standard, agentskills.io). That makes cross-family deployment mechanically feasible, which most prompt libraries cannot claim. [craft]

### Design sketch (candidate)

Re-run the P1 harness unchanged except for the model axis: cells = {model family × ±library}, with the task battery, metrics, and thresholds identical to P1's pre-registration (amended, before running, only for the model axis). Minimum interesting design: 2 non-Anthropic families + 1 Anthropic family, same N per cell as P1. Interaction effect (family × library) is the target statistic, not per-family scores. Prerequisite: P1 has produced a non-null; running P4 first inverts the logic (you cannot study transfer of an effect not yet shown to exist).

### First three steps in this repo

1. Add a "transferability" flag to each task in the battery spec (some tasks may assume Claude-Code-specific mechanics like skill loading; mark them non-portable).
2. Document, in the harness protocol, exactly how the library is injected for a non-Claude-Code runtime (system prompt concatenation? tool-exposed files?) — injection method is a confound and must be held fixed per family.
3. Extend the P1 pre-registration with the family axis and the interaction-effect threshold.

### You have a result when…

> The pre-registered interaction analysis over ≥2 non-authoring model families shows library uplift exceeding threshold on a non-authoring family (transfer), or adequate-N uplift confined to the authoring family (no transfer). Either outcome reshapes the project's external claims — route wording through `codofable-external-positioning` before saying anything public.

---

## P5 — Library ablation (added problem) — status: open; design: candidate

**Question.** If P1 finds uplift, sixteen skills is a black box. Which components carry the effect — and is a five-skill core as good as the full set?

**Why current approaches fail.** Whole-artifact A/Bs answer "does it help?" but not "what is it made of?"; without ablation, the library cannot be maintained rationally (every skill looks load-bearing, so nothing can be retired — violating the retirement half of the idea lifecycle in `codofable-research-methodology`). [craft]

**Asset.** The library is factored into 16 addressable units with a declared dependency direction (doctrine lives in named homes; everyone else cross-references), so subsets are well-defined treatments — remove a skill and its cross-references dangle detectably rather than silently. [craft]

**First three steps.** (1) Define 3–5 pre-registered subsets (e.g., doctrine-only: `codofable-change-control` + `codofable-validation-and-qa`; flagship-only: those plus `codofable-verified-done-campaign`; full). (2) Reuse the P1 harness with subset cells. (3) Pre-register the decomposition question: what fraction of full-library uplift must a subset retain to be declared sufficient?

**You have a result when…** a pre-registered subset analysis shows either a ≤5-skill subset retaining the pre-registered fraction of full uplift, or that no proper subset does (the library is holistic). Prerequisite: P1 non-null.

---

## Sequencing and dependencies

```
P2 (routing) ──validity precondition──▶ P1 (uplift) ──non-null required──▶ P4 (transfer)
P3 (drift)   ──independent; start anytime──▶ keeps P1's treatment artifact honest └──▶ P5 (ablation)
```

- Run **P3 first or in parallel** — it is cheap, needs no model runs, and protects every other experiment's treatment integrity.
- Run **at least a pilot of P2 before P1**: if the with-library cell rarely loads the relevant skills, P1 measures description quality, not library quality, and a null would be misattributed. [craft]
- **P4 and P5 are gated on a P1 non-null.** Do not start them speculatively; that is how projects accumulate unfinished experiments.
- Every experiment's *execution* follows `codofable-research-methodology`; every artifact change it requires (battery files, harness files, description edits) goes through `codofable-change-control` gates like any other change. Research does not route around change control.

## Provenance and maintenance

Date-stamped 2026-07-05. Status of every problem in this file: open; every design: candidate; achieved results contained herein: zero. If any experiment described here has since been run, this file is stale — update the problem register before relying on it.

Evidence classes for volatile claims:

- [repo] Repository state (pre-library history of exactly two commits — `c30ac04`, `c321e16` — plus library-authoring commits after them; 16-skill inventory; no experiment artifacts exist yet). Re-verify: `git -C . log --oneline c321e16` (expect exactly two lines) and `ls .claude/skills/` from the repo root.
- [⚠ unverified — craft, pending doc] SWE-bench contamination/test-flaw claims: https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/ ; solution leakage and weak tests: https://arxiv.org/abs/2410.06992 (SWE-Bench+) ; memorization evidence: https://arxiv.org/html/2506.12286v4 . Accessed via web search only, 2026-07-05 — the hosts were unreachable from the authoring sandbox, so per the library's evidence-tag rule (home: `codofable-docs-and-writing`) these carry no [doc] tag until fetched and read; specific percentages deliberately omitted — read the sources before quoting anything onward.
- [doc] Skill mechanics (descriptions always in context, body loads on invocation, 1,536-char listing truncation, no dedicated skill-load hook event): https://code.claude.com/docs/en/skills and https://code.claude.com/docs/en/hooks , fetched 2026-07-05. These are volatile product facts — re-verify before designing P2 probes: re-fetch both pages and diff against the claims above.
- [craft] All uplift-mechanism hypotheses, confound lists, sequencing logic, and the cross-model replication concern — the fellow's professional judgment, untested here.

Drift triggers for this file: a completed run of any P1–P5 experiment; a change to the skill inventory (P5 subsets reference the inventory names — `ls .claude/skills/`); a Claude Code release changing skill loading or hooks (invalidates P2's measurement plan); public retirement or replacement of the cited benchmarks (weakens but does not invalidate P1's "why SOTA fails" argument).
