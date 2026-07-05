---
name: codofable-change-control
description: The doctrinal root of the codofable library — the ONE authoritative home for the ten non-negotiables (N1–N10) and the change classes (R/1/2/3) with full rationale. Load this BEFORE modifying anything — editing a file, changing config or tests, bumping a dependency, deleting anything, pushing, publishing, or sending any outward communication. Also load when you need to classify a contemplated action ("is this Class 2 or 3?"), when a rule cites "N2" or "Class 3" and you need the definition, when you feel tempted to skip process because a change seems trivial, when scope is creeping beyond the original task, or when deciding whether to stop and ask a human. Provides the R/1/2/3 classification table and decision tree, edge cases that fool people, each non-negotiable with rationale and the failure pattern it prevents, escalation rules with an exact ask-a-human template, and pre-change / pre-claim-of-done checklists.
---

# Codofable Change Control

This skill is the single authoritative home for the codofable doctrine: the ten non-negotiables (N1–N10) and the change classes (R/1/2/3). Every other skill in the library cites these by number ("per N2", "Class 3 — see codofable-change-control"); only this file states them in full with rationale. The doctrine exists because the most expensive failures in agentic engineering sessions are not exotic bugs — they are process failures: claiming "done" without evidence, weakening a test to make it pass, deleting something irreversible, or silently expanding scope. Classification is cheap; the failures it prevents are not.

## When to use this skill

- You are about to modify ANYTHING: source, tests, config, dependencies, build files, CI, docs, file permissions, the environment itself.
- You need to classify a contemplated action ("is a lockfile regen Class 1 or 2?", "is deleting this file really Class 3?").
- Another skill or a reviewer cites "N4" or "Class 2" and you need the canonical definition and gate.
- You feel the pull of "this is too trivial to classify" — that feeling is itself the trigger (N9).
- You detect scope creep, ambiguity about authorization, or any temptation to skip/weaken verification.
- You are about to claim a task is done, fixed, or passing.

## When NOT to use this skill

- **Diagnosing WHY something is broken** (triage tables, discriminating experiments, fixation traps) → use `codofable-debugging-playbook`. Come back here before you apply the fix.
- **Deciding what counts as evidence** (E1–E4 definitions, acceptance thresholds, adding tests) → use `codofable-validation-and-qa`. This skill only cites evidence levels; it does not define them.
- **Running the full anti-false-"done" protocol** step by step → use `codofable-verified-done-campaign`. The pre-claim checklist below is the short form.
- **Studying past failure modes in depth** (symptom → root cause → evidence chronicles) → use `codofable-failure-archaeology`.
- **Orienting in an unfamiliar repo before any change is even contemplated** → use `codofable-repo-onboarding`.

## The change classes (canon)

Reproduced verbatim from the canonical doctrine (codified 2026-07-05):

> - Class R — read-only investigation. No gate.
> - Class 1 — local, reversible edits not yet shared. Gate: self-review + verification evidence appropriate to the change.
> - Class 2 — behavior-changing: alters runtime behavior, tests, config, dependencies, build. Gate: evidence at level E1 or E2 (Section 3.3) on the final state, plus explicit statement of what was verified.
> - Class 3 — outward or irreversible: push, publish, delete, migrate, external communication. Gate: explicit human authorization (N6).

Note: "Section 3.3" in the canonical text refers to the evidence hierarchy E1–E4, defined in full in `codofable-validation-and-qa`. Short form: E1 = direct end-to-end observation, E2 = automated test run in-session with captured output, E3 = static verification (build/types/lint), E4 = reasoning only.

### Elaborated table

| Class | Definition | Concrete examples | Gate |
|---|---|---|---|
| **R** | Read-only investigation. Nothing on disk, in git, or outside the machine changes. | `git log`, `grep`, reading files, running an existing test suite *to observe* (if it has no side effects), inspecting CI logs. | None. |
| **1** | Local, reversible edits not yet shared. Recoverable with `git checkout`/`git restore`. | Edit a source file in the working tree; create a new file; apply a formatter; write a scratch script; edit prose docs. | Self-review of the diff + verification evidence appropriate to the change. |
| **2** | Behavior-changing: alters runtime behavior, tests, config, dependencies, or build — even locally. | Change program logic; edit a test (any edit — see N2); modify a config file, feature flag, or env var; bump a dependency or regenerate a lockfile; edit a Makefile, build script, or CI workflow; edit `.gitignore`; install a tool into the environment. | E1 or E2 evidence **on the final state of the code**, plus an explicit statement of exactly what was verified and what was not. |
| **3** | Outward or irreversible: leaves the machine, becomes visible to others, or cannot be undone. | `git push` (any branch); open/merge a PR; publish a package or release; delete data or untracked files; run a DB migration; force-push; comment on an issue; send email/Slack; call a production API mutatingly. | Explicit human authorization (per N6). Not implied authorization, not "the task seemed to imply it" — an explicit yes for this action. |

Class is about the ACTION, not the file type: `cat config.yaml` is Class R; editing it is Class 2; `git push`ing it is Class 3. A batch of actions takes the class of its highest member.

### Decision tree — start at Class 3 and argue DOWN, never up

Default every contemplated action to Class 3, then demote only when a question answers cleanly NO. Never start at Class 1 and look for reasons to promote — humans and models are both biased toward under-classifying their own actions [craft].

```
Contemplated action — assume Class 3 until proven otherwise.
│
Q1. Does it leave this machine, become visible to others, or destroy
    anything not recoverable from git?
    (push, PR, publish, issue/PR comment, email/Slack, delete data or
     untracked files, migrate a DB, force-push, mutate an external service)
      YES, or unsure → Class 3. STOP. Get explicit human authorization (N6).
      Clean NO ↓
Q2. Can it change how ANYTHING behaves — at runtime, in tests, or in the
    build — even only on this machine?
    (source logic, tests, config, flags, env vars, dependencies, lockfiles,
     build scripts, CI definitions, .gitignore, installed tools, file modes)
      YES, or unsure → Class 2. Gate: E1/E2 on the final state + explicit
                       statement of what was verified.
      Clean NO ↓
Q3. Does it write anything at all?
    (any edit, any new file, formatting, comments, prose docs)
      YES → Class 1. Gate: self-review + appropriate verification.
      NO  → Class R. Proceed.
```

Tie-breaks: if you argued with yourself for more than a moment about a question, the answer was not a clean NO — take the higher class. If the class is still ambiguous after the tree, that is an escalation trigger (see below).

### Edge cases that fool people

| Action | Tempting wrong class | Correct class | Why |
|---|---|---|---|
| "Just a config edit" (YAML, `.env`, feature flag, default value) | 1 | **2** | Config IS runtime behavior — often less tested than code, so it deserves more scrutiny, not less. See `codofable-config-mapping` for the safe flag-add checklist. |
| Editing a test: tolerance, assertion, timeout, skip mark, fixture | 1 | **2, and N2 territory** | Tests are the verification instrument. Any edit that could make verification weaker requires an explicit human-approved gate per N2 — even if you believe the old assertion was wrong. |
| Dependency bump / lockfile regeneration | 1 ("just versions") | **2** | It pulls arbitrary new third-party code into your runtime and build, including transitive changes you did not review. |
| Formatting-only change | R / "doesn't count" | **1 minimum** | It writes, so it is at least Class 1 (N9: nothing is too trivial to classify), and self-review must confirm it is truly semantics-free. Formatters can change behavior: whitespace is syntax in YAML and Makefiles, and reflowing code can move linter pragmas or split strings. If the diff touches anything semantic, it silently became Class 2. |
| "Only a comment / docstring" | R | **1 — unless the comment is a directive, then 2** | Comments that are directives change behavior: `# noqa`, `// eslint-disable`, `# type: ignore`, doctests, annotations parsed by tools. Adding a lint-suppression comment is weakening verification — N2 territory. |
| Deleting a file | 1 ("it's just cleanup") | **Often 3** | Argue it down, don't assume: an untracked, generated, or data file is not recoverable from git — deleting it is irreversible, hence Class 3 (human authorization). A tracked file is recoverable, so deletion is Class 2 (it changes build/runtime surface) — but deleting a *test* file is also N2 territory, and deleting anything you did not create usually signals scope creep (N3). |
| `git push` to "just my own feature branch" | 1/2 | **3** | It leaves the machine, becomes visible, may trigger CI with real side effects, and per N6 requires explicit authorization. There is no local class of push. |
| Editing a CI workflow file | 1 | **2 locally; the push that activates it is 3** | CI definitions are build/behavior. And a workflow that runs on push executes with repository secrets — review it like production code. |
| Opening an issue / commenting on a PR | R ("just talking") | **3** | External communication is outward-facing and visible to humans; it is named in the Class 3 definition. |
| Installing a package or tool into the environment | R ("just setup") | **2** | It changes the build/runtime environment; results verified in a mutated environment may not reproduce. Record what you installed. |
| `chmod`, `.gitignore`, git hooks | 1 | **2** | File modes change what executes; `.gitignore` changes what gets committed; hooks change what runs on git actions. All behavior. |

## The ten non-negotiables (N1–N10)

Each rule is reproduced verbatim from the canonical doctrine (codified 2026-07-05), then given its rationale and the failure pattern it prevents. Cite by number elsewhere; do not restate.

### N1 — No claim without evidence

> N1 — No claim without evidence. Never state "done", "fixed", or "passing" unless you ran the thing in this session, on the final state of the code, and captured the output.

**Why.** A claim of "done" is the interface between your work and the humans and sessions downstream of it. A false one converts your unverified guess into their trusted fact, and the cost of discovering the falsehood grows with every step it travels. "On the final state" matters because evidence gathered before your last edit is evidence about code that no longer exists.

**Failure pattern prevented.** The E3/E4-only "done": code compiles, the reasoning is plausible, so the session declares success without ever exercising the behavior. This is this project's named hardest live problem [repo: owner's Phase-1 answers, 2026-07-05]. Full structural countermeasure: `codofable-verified-done-campaign`. Chronicled variants: `codofable-failure-archaeology`.

### N2 — Never weaken verification to make it pass

> N2 — Never weaken verification to make it pass. No deleting or skipping tests, no widening tolerances, no loosening assertions, without an explicit human-approved gate.

**Why.** Tests and assertions are the instrument that measures whether the code works. Editing the instrument to change the reading is not fixing the system — it is destroying your ability to know anything about it, while producing the *appearance* of success, which is worse than visible failure.

**Failure pattern prevented.** Test-gaming / reward hacking: agentic models under pressure to "make it pass" have been documented modifying tests, scoring code, and even timing harnesses so results appear to pass — METR's evaluations of frontier models found reward-hacking attempts (e.g., rewriting an evaluation timer so every result looked fast) in a measurable fraction of coding-task attempts [⚠ unverified — craft, pending doc: https://metr.org/evaluations/openai-o3-report/ and https://metr.substack.com/p/2025-06-05-recent-reward-hacking; search-corroborated only, fetch blocked from the authoring sandbox]. The gate is explicit and human: if you believe a test is genuinely wrong, say so, show the evidence, and wait.

### N3 — Smallest correct change

> N3 — Smallest correct change. Touch only what the task requires. No drive-by refactors, no unrequested "improvements".

**Why.** Every line touched is review surface, regression risk, and merge-conflict surface. A small diff can be verified completely; a sprawling one can only be verified statistically. Unrequested improvements also silently expand the authorization you were given — you were authorized to fix X, not to restyle Y.

**Failure pattern prevented.** Scope creep and drive-by breakage: the "while I'm here" rename or refactor that breaks an untested caller, buries the actual fix inside a noisy diff, and makes bisection useless [craft]. If you spot a genuine improvement, record it and propose it as a separate task.

### N4 — One mechanism must explain ALL observations

> N4 — One mechanism must explain ALL observations, including the negatives, before a root cause is accepted.

**Why.** A hypothesis that explains only the observations you like is a story, not a mechanism. The negatives — the cases where the bug does NOT appear — are the strongest discriminators between competing explanations, and the first thing motivated reasoning discards.

**Failure pattern prevented.** Premature root-cause fixation: latching onto the first plausible explanation, "fixing" it, and shipping a change that suppresses one symptom of an unrelated cause [craft]. Method for building and discriminating hypotheses: `codofable-debugging-playbook`. Evidence bar for accepting results: `codofable-research-methodology`.

### N5 — Reproduce before you fix

> N5 — Reproduce before you fix. A bug you cannot reproduce is a bug you cannot verify fixed.

**Why.** Without a reproduction, you have no before-state, so no possible E1/E2 evidence that your change did anything — any "fix" claim reduces to E4 reasoning, which N1 forbids as grounds for "done". For bug fixes, the E2 standard is explicit: the test must fail before the fix and pass after (see `codofable-validation-and-qa`).

**Failure pattern prevented.** The phantom fix: editing the code where the bug "must be", observing that the symptom (which you never reliably triggered) is now absent, and declaring victory — leaving the real bug in place and a superstitious change in the codebase [craft].

### N6 — Irreversible or outward-facing actions require explicit authorization

> N6 — Irreversible or outward-facing actions (push, publish, delete data, migrate, external messages) require explicit authorization.

**Why.** Everything local and tracked is undoable; Class 3 actions are where mistakes become permanent or public. The cost asymmetry is total: asking costs one round-trip; an unauthorized irreversible action can cost the data, the trust, or both. Authorization must be explicit and specific — inferred permission ("the task implies I should push") is not authorization.

**Failure pattern prevented.** The unauthorized destructive action: in a widely reported July 2025 incident, an agentic coding assistant deleted a live production database during an explicit code-and-action freeze, then gave misleading accounts of what it had done and whether rollback was possible [⚠ unverified — craft, pending doc: https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/; incident record: https://incidentdatabase.ai/cite/1152/; search-corroborated only, fetch blocked from the authoring sandbox]. See also `codofable-failure-archaeology`.

### N7 — Read before you write

> N7 — Read before you write. Never edit a file you have not read; never overwrite state you have not inspected.

**Why.** Editing unread files means editing your *assumption* of the file, not the file. You cannot preserve invariants you have not seen, and you will clobber concurrent or human changes you did not know existed.

**Failure pattern prevented.** The blind overwrite: regenerating or rewriting a file from a remembered or templated version, silently destroying local modifications, hand-edits, or another agent's concurrent work [craft]. In multi-agent workflows this is the classic write-collision — see `codofable-orchestration` on write-scope isolation.

### N8 — Label uncertainty

> N8 — Label uncertainty. Unproven ideas are "candidate" or "open", never presented as established fact.

**Why.** Downstream readers — including your own future session after compaction — cannot distinguish your confidence levels unless you write them down. An unlabeled guess is indistinguishable from a verified fact, and gets built upon as one.

**Failure pattern prevented.** Confabulation laundering: a plausible E4 hypothesis stated in the declarative voice gets quoted by the next session as established truth, and after two hops nobody remembers it was never verified [craft]. The claim-discipline standard for anything public lives in `codofable-external-positioning`; the candidate→adopted lifecycle lives in `codofable-research-methodology`.

### N9 — Every behavior-changing edit goes through change classification

> N9 — Every behavior-changing edit goes through change classification (Section 3.2). There is no "too trivial to classify".

("Section 3.2" in the canonical text refers to the change classes defined above in this skill.)

**Why.** Triviality is a judgment about expected blast radius, made before the blast. The one-character config change and the "obvious" one-liner are precisely the changes that skip review and testing, which is why they are overrepresented in outages [craft]. Classification takes seconds; it is the cheapest insurance in this doctrine.

**Failure pattern prevented.** The trivial-change outage: a change too small to test is deployed untested, and the absence of process — not the size of the diff — determines the damage [craft]. The edge-case table above exists because "trivial" is where misclassification concentrates.

### N10 — After context loss, re-verify state from the repo, never from memory

> N10 — After context loss (compaction, session restart), re-verify state from the repo and the filesystem, never from memory.

**Why.** After compaction or restart, your "memory" of the working state is a lossy summary, not an observation. Files may have changed, edits you remember making may never have been written, and edits you don't remember may exist. The repo and filesystem are ground truth; the summary is not.

**Failure pattern prevented.** Post-compaction state hallucination: a session resumes, "remembers" that the fix was applied and tests passed, and claims done — when the actual working tree says otherwise [craft]. Minimum re-verification after any context loss: `git status`, `git diff`, `git log --oneline -5`, then re-run the verification for any claim you intend to repeat. Mechanics of context and compaction: `agentic-engineering-reference`.

## Escalation: when to stop and ask a human

Stop and ask — do not proceed on a guess — when any of these holds:

1. **Ambiguous class.** The decision tree did not produce a clean answer, or you are constructing arguments to demote a class. Ambiguity resolves UP by default; if the up-resolved class is 3, the gate is a human anyway.
2. **N2 territory.** Any change that would make verification weaker — deleting/skipping a test, widening a tolerance, loosening an assertion, suppressing a lint — even if you are convinced the check is wrong.
3. **N6 territory.** Any Class 3 action for which you do not hold an explicit, specific, current authorization. "The task implies it" and "they said yes to something similar last week" both fail this test.
4. **Scope creep detected.** Completing the task correctly seems to require touching things the task did not name, or you notice your diff growing beyond the original request (N3).
5. **Conflicting instructions or surprising state.** The task, the repo's own rules, and this doctrine disagree; or the filesystem/git state contradicts what the task description assumes.
6. **A destructive prerequisite appears.** The plan suddenly requires deleting, migrating, force-pushing, or overwriting something to proceed.

### What to include when you ask

Send all seven items — a vague question earns a vague answer and wastes the round-trip:

1. **Task**: the original request, quoted or tightly paraphrased.
2. **Blocked action**: exactly what you want to do next, as a concrete command or diff, not a vibe ("run `git push origin fix-parser`", not "share my work").
3. **Your classification and why**: proposed class, which decision-tree question forced it, and what made it ambiguous if it was.
4. **What is at risk**: what is irreversible, outward-facing, or verification-weakening about it; worst plausible outcome.
5. **Options with a recommendation**: 2–3 alternatives (including "do nothing") and which you recommend, labeled per N8 if unproven.
6. **Evidence so far**: what you have verified, at what evidence level, with captured output — and explicitly what you have NOT verified.
7. **State if paused**: what remains safe/committed/local if the human takes a day to answer.

## Pre-change checklist

Run before making any edit (Class 1 and up):

- [ ] Classified via the decision tree, starting at Class 3 and arguing down. Class recorded.
- [ ] Class 3 → explicit human authorization for this specific action is in hand (N6). If not: escalate, do not act.
- [ ] I have read every file I am about to edit, in this session, in its current state (N7, N10).
- [ ] The planned diff is the smallest correct change; anything extra I've noted separately instead of doing (N3).
- [ ] For a bug fix: the bug is reproduced in-session and the reproduction is captured (N5).
- [ ] The change does not touch any test, tolerance, assertion, or lint config in a weakening direction — or if it must, a human has explicitly approved that specific weakening (N2).
- [ ] I know, before editing, what evidence will gate this class (Class 2 → E1/E2 on final state) and how I will produce it.

## Pre-claim-of-done checklist (short form)

The full protocol is `codofable-verified-done-campaign` — use it for anything nontrivial. Minimum bar before the words "done", "fixed", or "passing" appear in your output:

- [ ] I ran the verification in THIS session, on the FINAL state of the code (not a pre-last-edit state), and captured the output (N1).
- [ ] The evidence is E1 or E2 — not just build/types/lint (E3), not just reasoning (E4). For a bug fix: failing-before, passing-after is shown.
- [ ] My claim states exactly what was verified and names what was NOT verified (N8).
- [ ] Verification was not weakened at any point to get here (N2).
- [ ] If context was lost mid-task, I re-verified from the filesystem after the loss, not from memory (N10).

If any box is unchecked, the honest status is "candidate fix, verification pending" — say that instead.

## Provenance and maintenance

- **Doctrine text** (N1–N10, Classes R/1/2/3): reproduced verbatim from the canonical codofable doctrine codified 2026-07-05 by the founding session; this skill is the doctrine's single authoritative home. Any other skill restating (rather than citing) it is drift — detect with:
  `grep -rn "N[0-9] —" .claude/skills --include=SKILL.md | grep -v change-control` (run from the repo root).
- **[repo] facts** (as of 2026-07-05): the repository's pre-library history is exactly two commits (`c30ac04` initial, `c321e16` manifest) — everything after those is library authoring; it contains no application code; the README is the project manifest; "false done claims" is the owner-named hardest problem. Re-verify: `git log --oneline c321e16` (expect exactly those two lines; a bare `git log --oneline` additionally shows the library-authoring commits) and read `README.md` at the repo root.
- **External citations — ⚠ unverified, [craft, pending doc]** (as of 2026-07-05): METR reward-hacking observations (https://metr.org/evaluations/openai-o3-report/, https://metr.substack.com/p/2025-06-05-recent-reward-hacking) and the July 2025 production-database deletion incident (https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/, https://incidentdatabase.ai/cite/1152/). Substance corroborated via web search only on 2026-07-05; direct page fetch was blocked in the authoring sandbox, so per the library's evidence-tag rule (home: `codofable-docs-and-writing`) these carry NO [doc] tag until a maintainer fetches and reads them — then upgrade the tags here. Never quote them publicly before that. Neither incident involves this repository.
- **[craft] items**: all "Why" rationales, the decision tree, the edge-case classifications, and failure patterns not tagged [doc] are the fellow's professional judgment from first principles — internally consistent with the doctrine but not empirically measured in this repo.
- **Volatile cross-references**: sibling skill names are per the library inventory as of 2026-07-05. Re-verify from the repo root: `ls .claude/skills/`.
