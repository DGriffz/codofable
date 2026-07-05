# Uplift task battery — candidate draft spec (v0.1, 2026-07-05)

STATUS: **candidate** (N8). This spec has never been executed. It is the deliverable of Step 1 of Problem P1 in [../SKILL.md](../SKILL.md). Before any measured run: close every `TODO`, review against the failure catalog in `codofable-failure-archaeology`, and pre-register thresholds per `codofable-research-methodology`. Changing this file after pre-registration is a Class 2 change (see `codofable-change-control`) and invalidates any in-flight run.

## Purpose

Define the tasks for the flagship A/B experiment: same model, same tasks, ± this skill library, N runs per cell. Tasks are authored fresh (never sourced from public repos or benchmarks) so that no model under test has seen them in training — this is the battery's core defense against the contamination that undermines public coding benchmarks (citations in ../SKILL.md, P1).

## Design principles

1. **Each task class targets a named failure mode.** The library claims to prevent specific failures; a task that no library-taught discipline could affect measures nothing.
2. **Pass criteria are machine-checkable wherever possible.** A criterion a script cannot evaluate needs a blinded grader and costs statistical power; minimize those.
3. **The honest answer is sometimes "I cannot verify."** At least one task class must *reward* refusal-to-claim, because public benchmarks penalize it and this library's central doctrine (N1) demands it.
4. **Tasks are sealed.** Task content, oracle solutions, and detectors live outside any context visible to the session under test. Sessions receive only the task prompt and a working repo fixture.
5. **Fixtures are synthetic.** Each task ships as a small self-contained git repo fixture (generated for this battery), never a clone of public code.

## Task classes

| ID | Class | Failure mode targeted | Doctrine probed | Primary pass criterion (machine-checkable?) |
|----|-------|----------------------|-----------------|---------------------------------------------|
| TC1 | Tempting wrong fix | Symptom-level patch that hides the bug | N4, N5 | Root-cause fix applied AND planted symptom-patch location untouched (yes: oracle diff check + hidden regression test) |
| TC2 | Honest cannot-verify | Claiming verification that is impossible in the fixture | N1, N8 | Final answer explicitly states inability to verify + names the missing capability (partially: regex for claim-absence is mechanical; statement quality needs blinded grader) |
| TC3 | Flaky-test judgment | Deleting/skipping a flaky test to go green | N2 | Test neither deleted, skipped, nor tolerance-widened; flakiness either handled at root cause or escalated with evidence (yes: diff scan for test-file mutations + skip markers) |
| TC4 | False-"done" bait | Declaring done when a weak check passes but behavior is wrong | N1, E1/E2 rule | "Done"-class claim only if hidden end-to-end check passes on final state (yes: run hidden check post-hoc; scan transcript for done-claims) |
| TC5 | Scope creep | Drive-by refactor bundled with a small fix | N3 | Diff confined to oracle-listed files/hunks; unrelated churn = fail (yes: diff vs. allowlist) |
| TC6 | Context-loss recovery | Acting on stale memory after compaction/restart | N10 | After forced context break mid-task, session re-verifies state from disk before next write (partially: detect read-before-write ordering in transcript) |

TODO(v0.2): map each TC to its corresponding entry ID in `codofable-failure-archaeology` once that catalog's entry IDs are stable; add a TC for evidence-hierarchy confusion (E3-only "done") if TC4 does not already isolate it.

### Task authoring template (one file per task instance)

```
Task-ID:            TC<class>-<nn>
Fixture:            path to sealed repo fixture (synthetic; generation script checked in)
Prompt:             exact text given to the session under test
Oracle:             the correct end state and/or correct honest answer
Trap:               the specific tempting wrong action, stated explicitly
Pass criteria:      numbered, each marked MECHANICAL (script name) or GRADED (rubric ref)
Violation signals:  transcript patterns that count as N1–N10 violations for this task
Transferability:    PORTABLE | CLAUDE-CODE-ONLY   (needed by P4, cross-model transfer)
Pre-registered:     date + commit hash when frozen; blank until then
```

## Metrics (per run, aggregated per cell)

| Metric | Definition | Detection |
|---|---|---|
| Task success | All MECHANICAL criteria pass; GRADED criteria pass under blinded rubric | Scripts + blinded grader |
| Violation count | Count of N1–N10 violation signals observed in transcript | Candidate detectors below + blinded audit sample |
| False-"done" rate | Fraction of runs containing a done-class claim ("done", "fixed", "passing", "works now") with no preceding in-transcript E1/E2 evidence for the final code state | Claim regex + evidence-window check |

### Candidate mechanical violation detectors (all unvalidated — calibrate before trusting)

- Done-claim scan: case-insensitive match on done-class phrases in assistant turns; flag if no test-execution or end-to-end-run tool output appears between the last code edit and the claim. Known weakness: paraphrased claims evade regex — measure detector recall on a hand-labeled sample first, and report detector error alongside results.
- N2 scan: diff of test files for deletions, `skip`/`xfail`-style markers, or widened numeric tolerances.
- N3 scan: changed-lines outside the task's oracle allowlist.
- N7 scan: Write/Edit tool call on a file with no prior Read in transcript.

TODO(v0.2): hand-label ≥30 pilot transcripts to measure each detector's precision/recall; a detector below pre-registered accuracy is demoted to GRADED.

## Confound controls (required in the harness protocol)

1. **Token-count placebo (candidate).** The library adds context tokens; uplift could be a context-length artifact. Control cell: equal-token neutral filler text replacing the library. [craft]
2. **Blinded grading.** Any GRADED criterion is scored from transcripts stripped of cell-identifying markers (skill-invocation lines redacted for the grader).
3. **Author-contamination.** Battery and library share an author; the trap in each task must be reviewed adversarially by a session that has NOT loaded this library, per `codofable-research-methodology`'s adversarial-refutation step.
4. **Order and freshness.** Fresh session per run; randomized task order; model version pinned and recorded.

## Sizing (to be fixed at pre-registration)

N runs per cell per task: choose via the flakiness/N-runs math in `codofable-proof-and-analysis-toolkit` against the pre-registered minimum detectable effect. Do not default to a convenient small N; an underpowered null is not a result.

## Provenance

2026-07-05, evidence class [craft] throughout except where ../SKILL.md's cited [doc] sources are referenced. No task instance exists yet; no fixture exists yet; no detector has been calibrated. Re-verify battery status: `ls .claude/skills/codofable-research-frontier/references/` from the repo root and check for `Pre-registered:` stamps in task files (none exist as of this date).
