---
name: codofable-verified-done-campaign
description: Executable, decision-gated protocol that makes a false "done" claim structurally impossible. Load this skill BEFORE saying "done", "fixed", "passing", "works now", "implemented", "should be good", or before committing/reporting any completed task. Also load when reviewing someone else's done claim, when tempted to declare success because the build/types/lint passed, when a test passed but never failed, or when verification seems impossible (no test harness, no runtime). Provides: claim classification (Phase 0), predict-before-check (Phase 1), gated evidence gathering with git stash/worktree failed-before patterns (Phase 2), adversarial self-refutation (Phase 3), the mandatory Done Statement template (Phase 4), a ranked menu for hard-to-verify situations, and fenced-off wrong paths. Targets the project's named hardest failure mode - declaring success without end-to-end verification.
---

# The Verified-Done Campaign

This is the flagship campaign against the project's hardest live problem: **false "done" claims** — declaring success on evidence that does not support it (owner's Phase-1 answer #2, binding as of 2026-07-05). The campaign is a linear, gated protocol: you may not say "done" until you have passed every gate and filled in the Done Statement in Phase 4. A "done" claim without a Done Statement is invalid by definition. Every rule here is an application of the non-negotiables N1–N10 (full rationale in `codofable-change-control`); the evidence levels E1–E4 are defined in `codofable-validation-and-qa`.

Vocabulary used below (defined once): a **claim** is any statement that work is complete ("fixed", "implemented", "passing", "safe to merge"). The **final state** is the working tree exactly as it will be committed/delivered — every file, current content, no pending edits. A **discriminating check** is a command whose outcome differs depending on whether the claim is true or false.

## When to use this skill

- You are about to tell the human (or a parent agent) that a task is done, a bug is fixed, a test passes, a refactor is safe, or performance improved.
- You are about to commit, or hand off, work you believe is complete.
- You wrote a test, it passed, and you have never seen it fail.
- You are reviewing another session's "done" claim and must decide whether to trust it.
- The build/types/lint pass and you feel finished — that feeling is exactly the E3-declared-as-done trap this campaign exists to stop.
- You resumed after compaction or restart and are unsure whether earlier verification still counts (it does not — N10; re-enter at Phase 2, Gate A).

## When NOT to use this skill

- **The bug is not fixed yet** (you are still diagnosing or the fix does not work): use `codofable-debugging-playbook`. This campaign verifies a claimed fix; it does not find one.
- **You need the definitions of evidence levels E1–E4, acceptance thresholds, or how to add tests**: `codofable-validation-and-qa` is the home of that doctrine; this skill only applies it.
- **You are deciding what class a change is or what gate it needs**: `codofable-change-control`.
- **You want a proof that the fix is causal (bisection, flakiness statistics, perf measurement)**: `codofable-proof-and-analysis-toolkit`; this campaign will route you there from Gate B when needed.

---

## Phase 0 — CLASSIFY THE CLAIM (before verifying anything)

Do not run a single command yet. First write down, in one sentence, **what kind of done is being claimed**. Different claims require different evidence; verifying the wrong thing is how plausible-but-false done claims are born.

| # | Claim type | Example claim | Minimum evidence (per E1–E4, `codofable-validation-and-qa`) | Phase route |
|---|-----------|----------------|-------------------------------------------------------------|-------------|
| C1 | Bug fixed | "The crash on empty input is fixed" | E2 with the **failed-before** property (test fails at pre-fix state, passes at final state), plus E1 if the bug was observed via an entrypoint | Phases 1 → 2 (Gates A, **B**, C, D) → 3 → 4 |
| C2 | Feature works | "The new export flag is implemented" | E1 — drive the real entrypoint end-to-end on the final state; E2 for the covered cases | Phases 1 → 2 (Gates A, C, D) → 3 → 4 |
| C3 | Refactor safe (no behavior change intended) | "Extracted the parser, behavior unchanged" | E2 — full relevant test suite green on final state, **and** evidence the suite exercises the moved code (coverage or a deliberate mutation); E1 spot-check of one representative flow | Phases 1 → 2 (Gates A, C, D) → 3 → 4 |
| C4 | Performance improved | "Startup is 2x faster" | E1 — measured numbers, before AND after, same conditions, per the measurement recipes in `codofable-proof-and-analysis-toolkit` | Phases 1 → 2 (Gates A, B-for-baseline, D) → 3 → 4 |
| C5 | Docs/comments only | "Updated the README" | Verify at the level the content allows: every command and path the doc quotes must be run/checked — that IS E1/E2 for a doc. Links resolve; renders/lints (E3) on top, plus Gate D always. Where end-to-end verification is genuinely impossible, use the labeled-downgrade route (Solution Menu below) | Phases 1 (light) → 2 (Gates A, D) → 4 |

Rules for this table:

1. If the claim mixes types (a fix plus a drive-by refactor), that is already an N3 finding — split or shrink the change before verifying.
2. If you cannot classify the claim, you do not understand the task. Stop and re-read the task; if still unclear, ask the human.
3. There is NO claim type for which E3 alone suffices. For C5, the commands and paths quoted in the doc must actually be run/checked — that is direct observation of the doc's load-bearing content; where verification is genuinely impossible, the claim wording must state what was not verified, via the explicit labeled downgrade in the Solution Menu (per `codofable-validation-and-qa`, rule 6) — never a silent E3 "done". E3/E4-only "done" is the project's named hardest failure mode — forbidden.

## Phase 1 — PREDICT BEFORE YOU CHECK

Per the hypothesis-predicts-numbers discipline in `codofable-research-methodology`: **before running anything**, write down the observable predictions of "done" — exact commands and exact expected observations. Verification you design after seeing output is rationalization, not verification.

Write a prediction block in this form (write it in your response or scratch notes, verbatim structure):

```
CLAIM: <one sentence, classified per Phase 0 as C1..C5>
PREDICTIONS (all must hold if the claim is true):
  P1: `<exact command>` → <exact expected observation, including exit code>
  P2: `<exact command>` → <exact expected observation>
  ...
FAILED-BEFORE PREDICTION (C1 only):
  P0: the same test, run at the pre-change state, FAILS with <expected failure signature>
```

Worked example (pattern, adapt commands to the target repo):

```
CLAIM: C1 — empty-input crash in the importer is fixed.
PREDICTIONS:
  P1: `pytest tests/test_importer.py -k empty -x` → exits 0; `test_empty_input` listed as PASSED
  P2: `<app-entrypoint> import /dev/null` → exits 0, prints "0 records imported" (E1)
FAILED-BEFORE PREDICTION:
  P0: at the pre-fix state, P1's command exits nonzero with the original traceback (ValueError in importer.py)
```

**Gate: the falsifiability test.** Read your predictions and ask: could any realistic output make me retract the claim? If every prediction is vague ("tests pass", "it works"), or if you cannot name a command whose failure would falsify the claim — **you do not have a definition of done. STOP.** That is a requirements gap, not a verification problem. Ask the human what observable behavior constitutes done, quoting your best-guess predictions so they can correct them. Do not proceed to Phase 2 on an unfalsifiable claim (N8: label it "open", not "done").

## Phase 2 — GATHER EVIDENCE (gated steps)

Run the gates **in order**. Each step gives the command pattern, the EXPECTED observation, and the branch to take if you see something else. Test commands are generic patterns — substitute the target repo's real runner. The git patterns were rehearsed end-to-end in a scratch repository on 2026-07-05; the full transcript is in [references/rehearsal-transcript.md](references/rehearsal-transcript.md).

### Gate A — State check: is this the FINAL state?

Evidence is only valid if produced on the final state (N1). Any edit after your last test run voids all prior evidence.

1. Run:
   ```
   git status --porcelain=v1
   git diff --stat HEAD
   ```
   EXPECTED: the listed modified/untracked files are exactly the files of your change, and you have made **zero edits since your last verification run**.
   - If files appear that you did not knowingly touch → go to Gate D now (side-effect sweep) before anything else; unexplained changes may be the real story.
   - If you edited anything (even a comment, even "just formatting") after the last test run → all evidence is void. Re-run every prediction from Phase 1 on the current tree. There is no "that edit couldn't matter" exemption — that judgment is E4.
   - If you cannot remember whether you edited since the last run (post-compaction, long session) → per N10, assume you did; re-run everything.
2. Confirm you are on the intended branch/commit: `git branch --show-current` and `git log --oneline -1`.
   EXPECTED: the branch and HEAD you believe you are on.
   - If not → stop; establish where you are before generating any more evidence (`codofable-repo-onboarding` if truly lost).

### Gate B — Failed-before check (mandatory for C1 bug fixes; baseline for C4)

A fix-verifying test that never failed proves nothing (E2's definition requires fail-before/pass-after). You must run the test at the **pre-change state**. Do this without mutating history. Both patterns below are **Class 1 — local, reversible** (per `codofable-change-control`): they temporarily mutate the working tree (stash) or add a second checkout and move its HEAD (worktree), touch no branch refs, and MUST end with the tree restored exactly to its Gate-A state before any further evidence counts. Rehearsed transcript: [references/rehearsal-transcript.md](references/rehearsal-transcript.md).

**Pattern B-1: worktree (preferred; use when the pre-change state is a commit).** A `git worktree` is a second checkout of the same repository in another directory; your main tree is untouched.

1. ```
   git worktree add --detach ../prefix-check <pre-change-commit>
   ```
   EXPECTED: `Preparing worktree (detached HEAD <sha>)`.
   - If `fatal: ... already exists` → pick another directory name, or `git worktree remove` the stale one.
2. Copy ONLY the new test file(s) into the worktree (the test must run against old code):
   ```
   cp <new-test-file> ../prefix-check/<same-relative-path>
   ```
3. Run the test **inside the worktree**:
   ```
   (cd ../prefix-check && <test cmd>)
   ```
   EXPECTED: nonzero exit, failing with the signature predicted in P0 (Phase 1).
   - If it **passes** at the pre-change state → your test does not capture the bug, or the bug never existed as understood, or your fix is not what changed the behavior. Do NOT proceed. Branch to `codofable-debugging-playbook` (you are back in diagnosis) and to `codofable-proof-and-analysis-toolkit` if you need a causal-fix proof.
   - If it fails but with a **different** signature than predicted → your mechanism story is incomplete (N4). Branch to `codofable-debugging-playbook`.
4. Clean up and confirm the main tree is untouched:
   ```
   git worktree remove --force ../prefix-check
   git worktree list
   git status --porcelain=v1
   ```
   EXPECTED: only your main worktree listed; status unchanged from Gate A.
5. Re-run the test on the final state. EXPECTED: passes (this is the run you will cite).

**Pattern B-2: stash round-trip (use when the fix is uncommitted working-tree edits).** `git stash push` temporarily shelves selected edits; `git stash pop` restores them.

1. Stash only the fix files, by pathspec, so the (untracked) new test file stays in place:
   ```
   git stash push -m "verify-failed-before" -- <fixed-file> [<fixed-file2> ...]
   ```
   EXPECTED: `Saved working directory and index state ... verify-failed-before`.
   - If the new test file is itself a *modification to a tracked file*, this pathspec trick cannot separate them — commit nothing; instead copy the test file aside, `git stash push` everything, restore the copy, proceed.
2. Confirm the fixed file is at its pre-fix content (inspect the relevant lines: `git diff -- <fixed-file>` shows nothing; the buggy code is back).
3. Run `<test cmd>`. EXPECTED: fails with the P0 signature. Same branches as B-1 step 3 if not.
4. Restore the fix — this step is NOT optional and must happen even if step 3 surprised you:
   ```
   git stash pop
   ```
   EXPECTED: `Dropped refs/stash@{0} ...` and `git status` matches Gate A again.
   - If pop reports conflicts → do not improvise; the stash still exists (`git stash list`). Resolve carefully; your fix is in the stash, not lost.
5. Re-run `<test cmd>` on the restored final state. EXPECTED: passes. Because the tree was mutated and restored, this final-state re-run is mandatory (Gate A logic).

**For C4 (performance):** Gate B means measuring the *baseline* at the pre-change state via the same worktree pattern — never from memory or from an old log. Methods in `codofable-proof-and-analysis-toolkit`.

### Gate C — End-to-end check (mandatory for C1 behavior claims and all C2/C3)

Unit tests exercise code; users exercise entrypoints. For any claim about behavior, drive the **actual entrypoint** — the CLI command, server endpoint, script, or UI flow a user would hit — on the final state (E1).

1. Identify the real entrypoint for the claimed behavior. If you do not know it, find how the repo is run (`codofable-repo-onboarding`) — do not substitute "the unit test passed" for this step.
2. Run it with inputs matching the claim, e.g. pattern:
   ```
   <entrypoint cmd with the relevant input>; echo "exit=$?"
   ```
   EXPECTED: the exact observable behavior from your Phase-1 prediction (output text, created file, HTTP status — something you can paste).
   - If the entrypoint cannot be run in this environment → you cannot claim E1. Go to the Solution Menu below; the claim wording must be downgraded, not the evidence bar quietly lowered.
   - If output differs from prediction → the claim is false or the prediction was wrong; either way, back to `codofable-debugging-playbook` or back to the human for requirements clarification. Do not edit the prediction to match the output and call it verified.

### Gate D — Side-effect sweep (always, every claim type)

Verify the *whole* change, not the part you remember making (N10: memory of your diff is not the diff).

1. Run:
   ```
   git status --porcelain=v1
   git diff --stat HEAD
   git diff HEAD
   ```
   EXPECTED: every listed file is within the task's scope, and you can state in one sentence why each hunk is required by the task (N3).
   - Files outside scope (editor artifacts, generated files, accidental formatting of untouched regions, debug prints, leftover scratch files) → remove or revert them, then **return to Gate A** — the tree changed, so all evidence is void again.
   - A hunk you cannot explain → treat it as an unexplained observation (N4). Investigate before claiming anything.
2. Check for verification-weakening in the diff: any deleted/skipped test, widened tolerance, loosened assertion, commented-out check?
   EXPECTED: none.
   - If present and not explicitly human-approved → **hard stop, N2**. This is never yours to decide. Surface it to the human verbatim.

## Phase 3 — ADVERSARIAL SELF-REFUTATION

Per `codofable-research-methodology`: a claim that has survived only friendly checks has survived nothing. Generate the strongest available "this is NOT done" hypotheses and run a discriminating check for each. **Minimum one refutation attempt per claim; the claim must survive all attempts you generate.** Standard refutation set — pick every row that applies:

| Refutation hypothesis | Discriminating check | Claim survives if |
|---|---|---|
| The test passes vacuously (asserts nothing real, wrong file collected, skipped silently) | Mutate the code-under-test or the assertion to something wrong, re-run, then revert the mutation (Class 1 — a deliberate, temporary working-tree mutation; it MUST be reverted and the tree restored before any further evidence counts; rehearsed in [references/rehearsal-transcript.md](references/rehearsal-transcript.md)) | The mutated run FAILS. If it still passes, the test is vacuous — you have no E2 |
| Works only on the happy path | Run the entrypoint/test with one boundary input and one malformed input relevant to the claim | Behavior is correct or explicitly-out-of-scope (noted in the Done Statement residual) |
| Evidence came from stale state (old build artifact, cached bytecode, running server not restarted, pre-edit binary) | Force a rebuild/restart (clean build dir, kill and relaunch the process), re-run the key prediction | Same result after clean rebuild |
| Verification was weakened somewhere I forgot (N2) | `git diff HEAD -- '<test dirs>' '<ci config>'` and read it | No weakening present, or human-approved and cited |
| The fix masks the symptom, not the mechanism (N4) | State the one mechanism; check it explains the original symptom AND why Gate B failed pre-fix with that exact signature | One mechanism explains all observations, including negatives |
| It only works in my environment | Identify environment assumptions (env vars you exported, files you created ad hoc); re-run key prediction in a fresh shell / clean checkout if feasible | Result reproduces, or the assumption is documented in the residual |

If any refutation succeeds: the claim is dead in its current form. Return to the appropriate gate (or to `codofable-debugging-playbook`) — do not soften the claim's wording to dodge the refutation while still implying done.

## Phase 4 — THE DONE STATEMENT

The only valid way to claim done is to emit this statement, filled in. If a field cannot be filled honestly, the claim is not ready. This template is the interface to review: reviewers judge the checklist, never the vibe.

```
DONE STATEMENT
--------------
Claim: <one sentence, exactly what is being claimed>
Claim class: <C1..C5 (Phase 0)> / Change class: <R/1/2/3 per codofable-change-control>
Final-state check (Gate A): git status/diff --stat output attached; last edit BEFORE last verification run: yes
Evidence level achieved: <E1 / E2 / explicitly labeled downgrade per the Solution Menu (state what was NOT verified)>
Commands run on the final state, with outputs (paste or link transcript):
  1. <command> → <observed output / exit code>
  2. ...
Failed-before evidence (C1/C4 only): <pattern B-1 or B-2; pre-change run output with failure signature>
End-to-end evidence (Gate C): <entrypoint command + observed behavior, or "N/A: <claim class reason>">
Side-effect sweep (Gate D): <N files changed, each mapped to task scope; no verification weakening>
Refutations attempted (Phase 3): <list each hypothesis + discriminating check + result>
NOT verified (honest residual, N8): <what this evidence does NOT cover — platforms, inputs,
  concurrency, scale, downstream consumers. "Nothing" is almost never true.>
```

A report that says "done" without this statement is, by this project's doctrine, not a done claim — it is an E4 opinion and must be labeled as such.

## Solution menu: when verification seems impossible

Ranked. Take the highest-ranked option whose obligation you can meet. Each option carries a non-optional obligation — an option without its obligation is a wrong path.

1. **No test harness exists → build the minimal harness first.**
   Obligation: the harness itself must be verified by mutation — make it fail on purpose once (break the assertion or the code, observe the failure, revert) before trusting any green run. A harness never seen red is unverified equipment. (Rehearsed: see transcript, "harness mutation check".) Adding a harness is a Class 2 change itself — classify it (N9).
2. **No runtime available (can't execute the code here) → verify at E3 and downgrade the claim wording.**
   Obligation: the *claim itself* must carry the downgrade, in the same sentence — "compiles and type-checks; NOT verified end-to-end" — and the Done Statement's evidence level says E3 with the residual listing everything unexecuted. Saying "done (couldn't test)" in passing does not satisfy this; the headline claim must be the downgraded one.
3. **Partially verifiable → verify the verifiable core at E1/E2, name the unverified remainder.**
   Obligation: the residual section enumerates the unverified part explicitly; the claim covers only the verified part.
4. **Truly unverifiable (no harness possible, no runtime, no static signal) → say exactly that and route the decision to the human.**
   Obligation: present what you attempted, why each avenue is closed, and what verification would require. The human decides whether to accept the risk. **Never silently downgrade** — an unverifiable change shipped as "done" is this project's named failure mode in its purest form.

## Wrong paths (fenced off — do not enter)

- **Declaring done on E3/E4.** "It builds", "types check", "the logic is clearly right" — necessary at best, never sufficient, for any claim type. This is the exact failure this campaign exists to kill.
- **Testing a pre-final state.** Any edit after the last run voids the run. "I only changed a comment" is an E4 judgment about relevance, not evidence. Re-run (Gate A).
- **The test that never failed.** A regression test you have only ever seen green demonstrates nothing about the fix. Gate B is mandatory for C1, no exceptions for "obvious" fixes.
- **Weakening assertions to pass.** Deleting/skipping tests, widening tolerances, loosening asserts — N2 hard stop, human gate required. If you find yourself editing a test to make the run green, stop typing and surface it.
- **"CI will catch it."** Deferring verification to CI is claiming done on E4 plus someone else's future E2. You claim done only on evidence produced in this session (N1). CI is a backstop, not your verification.
- **Verifying the diff you remember instead of the diff that exists.** Memory of what you changed is not `git diff` (N10). Gate D reads the actual diff, every time — this is also the only way to catch tool-induced or accidental edits you never consciously made.
- **Retrofitting predictions.** Running commands first and then writing "predictions" that match the output inverts Phase 1 and produces confirmation, not verification.

## Promotion protocol: from Done Statement to accepted change

The Done Statement is not the end; it is the input to change control.

1. Classify the change (N9) per `codofable-change-control`. Anything behavior-changing is Class 2; its gate **requires** evidence at E1/E2 on the final state plus an explicit statement of what was verified — which is precisely the Done Statement. Attach it.
2. Class 3 actions implied by "done" (push, publish, migrate, external messages) still require explicit human authorization (N6). A perfect Done Statement authorizes nothing outward by itself.
3. Reviewer contract: a reviewer (human, or a review agent per `codofable-orchestration`) accepts or rejects by checking the Done Statement fields against this skill's gates — commands actually shown? failed-before shown for C1? residual non-empty and plausible? Reviewers never accept "looks done to me"; success is measured by the statement's checklist, never judged by eye.
4. If review rejects a field, the claim reverts to "open" (N8) and re-enters this campaign at the failed gate — not at Phase 4.

## Provenance and maintenance

- Evidence classes per the library's convention: **[repo]** — the owner's Phase-1 answer naming false done claims as the hardest live problem, and doctrine references N1–N10 / Class R-3 / E1–E4, trace to the project manifest (`README.md`) and to the doctrine's canonical home skills, `codofable-change-control` and `codofable-validation-and-qa`, as of 2026-07-05. **[craft]** — the phase structure, gate design, refutation table, and solution-menu ranking are the retiring fellow's professional judgment; they are consistent with, but not derivable from, the repo alone.
- All `git worktree`, `git stash push/pop` pathspec, status/diff sweep, and harness-mutation command patterns were executed end-to-end in a throwaway scratch repository on 2026-07-05; the full transcript is preserved in [references/rehearsal-transcript.md](references/rehearsal-transcript.md). Test-runner commands (`pytest ...`, `<test cmd>`, `<entrypoint cmd>`) are generic patterns — substitute the target repo's real commands; they were not run against a specific application here (this repo has none, as of 2026-07-05 [repo]).
- Re-verification one-liners for drift:
  - Git pattern still behaves as documented: `cd "$(mktemp -d)" && git init -q -b main . && git -c user.email=x@x -c user.name=x commit -q --allow-empty -m x && git worktree add --detach wt HEAD && git worktree remove wt && echo OK`
  - Cross-referenced skills still exist: `ls /path/to/repo/.claude/skills | grep -E 'change-control|validation-and-qa|debugging-playbook|proof-and-analysis'`
  - Doctrine anchors unchanged: `git -C /path/to/repo log --oneline -- README.md` (any new commit → re-check the doctrine references above against the manifest).
