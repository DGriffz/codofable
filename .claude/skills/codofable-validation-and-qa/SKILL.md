---
name: codofable-validation-and-qa
description: The canonical home of the codofable evidence hierarchy (E1-E4) and of what counts as proof of "done", "fixed", or "passing" in this project. Load this skill whenever you are about to claim a task is complete, decide whether test/build/lint output is sufficient evidence, set or judge an acceptance threshold, define or update the golden inventory of checks that means "green", add a test to an unfamiliar repository, or handle a flaky test. Trigger phrases and situations - "is this done?", "how do I prove this works?", "what evidence do I need before saying fixed?", "the types check, can I claim done?" (no), "tests pass, ship it?", "what defines green here?", "should I set the threshold before or after measuring?" (before), "this test is flaky", "where do new tests go in this repo?". For the full end-of-task protocol use codofable-verified-done-campaign; this skill defines the evidence standard that protocol enforces.
---

# codofable-validation-and-qa

This skill is the single home for the evidence hierarchy E1-E4 and for what counts as proof in the codofable project. Every other skill that says "evidence at level E1 or E2" is citing THIS document. It defines the four evidence levels, the binding rules for when a "done" claim is legitimate, the discipline for acceptance thresholds, the "golden inventory" concept (the named set of checks that defines green), how to add tests to a repository you did not write, and how to handle flaky tests. The audience is a zero-context mid-level engineer or a Sonnet-class model session dropped into any repository.

## When to use this skill

- You are about to write the words "done", "fixed", "passing", "works", or "verified" and need to know what evidence that claim requires (per N1, see `codofable-change-control`).
- You have build/type/lint output (E3) or a convincing-looking diff (E4) and are tempted to treat it as proof.
- You need to set an acceptance threshold for a change ("how fast is fast enough?", "how many passes count as fixed?").
- You need to identify or define the golden inventory - the checks that define "green" - for this library or for a target repo.
- You are adding a test to a repository whose test conventions you did not write.
- A test gives different results on different runs of the same code and you need to know what that does to your evidence.
- A reviewer asks "what did you actually verify?" and you need the vocabulary to answer precisely.

## When NOT to use this skill

| If you need... | Use instead |
| --- | --- |
| The full step-by-step end-of-task protocol that operationalizes these rules into a decision-gated checklist | `codofable-verified-done-campaign` |
| Measurement tooling: scripts, profilers, the library validator, how to instrument instead of eyeball | `codofable-diagnostics-and-tooling` |
| The statistics for flaky tests (how many runs, what confidence) and causal-fix proof recipes | `codofable-proof-and-analysis-toolkit` |
| Change classes R/1/2/3, gates, and the ten non-negotiables with rationale | `codofable-change-control` |
| Experiment design: hypotheses that predict numbers before running | `codofable-research-methodology` |
| Discovering how an unknown repo builds and runs at all | `codofable-repo-onboarding` |
| Root-causing a failure (as opposed to proving a fix) | `codofable-debugging-playbook` |

## The evidence hierarchy E1-E4

Canonical definitions (verbatim project doctrine; other skills cite these, they do not restate them):

- E1 — Direct observation: the changed behavior exercised end-to-end, in-session, on the final state.
- E2 — Automated test run in-session with output captured; for bug fixes the test must fail before the fix and pass after.
- E3 — Static verification (build, types, lint). Necessary, never sufficient.
- E4 — Reasoning and plausibility. Hypothesis fuel only; never proof.

Rule: a "done" claim requires E1 or E2. E3/E4-only "done" claims are the project's named hardest failure mode.

### The hierarchy in full

| Level | Definition | What it proves | What it CANNOT prove | Concrete examples |
| --- | --- | --- | --- | --- |
| **E1** | You drove the actual behavior end-to-end, in this session, on the final state of the code, and observed the new behavior with your own captured output. | The feature/fix actually behaves as intended in the real execution path, including wiring, config, and environment. | That OTHER behaviors still work (no regression coverage), or that the behavior holds under inputs you did not try. | Drove the actual CLI with the new flag and pasted the changed output; hit the modified endpoint with `curl` and captured the new response body; opened the app and observed the fixed rendering; ran the migration against a scratch database and inspected the resulting schema. |
| **E2** | An automated test executed in-session, output captured. For bug fixes: the test demonstrably FAILED before the fix and PASSES after, both runs captured. | The specific asserted behavior holds, and (for fixes, via failed-before) that the test actually detects the bug - so its pass is informative. | Anything the test does not assert; that the test exercises the real integration path (a mocked test can pass while the wired system is broken). | `pytest tests/test_parser.py::test_empty_input` output pasted twice: the failing run from before the edit and the passing run after; a new regression test added alongside the fix, shown red on the pre-fix code and green on the final code. |
| **E3** | Static verification: compilation, type checking, linting, schema validation - anything that runs without executing the changed behavior. | The code is well-formed: it parses, type-checks, satisfies lint rules. Absence of a whole class of mechanical errors. | That the code does anything correct at runtime. `tsc` clean proves the types line up; it proves nothing about behavior, logic, wiring, or data. | `tsc --noEmit` exits 0; `cargo check` clean; `ruff check .` clean; a JSON config validates against its schema. |
| **E4** | Reasoning and plausibility: reading the diff, tracing the logic mentally, "this should work because...". | Nothing. It generates hypotheses worth testing and helps you decide WHAT to verify. | Everything. E4 is exactly where false "done" claims are born: "the diff looks right", "I traced the logic and it's correct", "this is a trivial change". | "The diff looks right"; "the only caller passes a non-null value, so this is safe"; "I changed the same pattern in three files, the fourth must work too". |

### Binding rules

These rules are canon. Violating them is the project's named hardest failure mode (false "done" claims - see `codofable-failure-archaeology` for the failure-mode chronicle).

1. **"Done" requires E1 or E2 on the FINAL state.** Re-run the evidence-producing command AFTER your last edit. Evidence gathered before the last edit is void - even a one-character "cosmetic" edit invalidates it, because you have not observed the code that will actually ship. There is no "too trivial to re-verify" (parallel to N9's "too trivial to classify").
2. **For bug fixes, E2 requires failed-before / passes-after.** A test that never failed proves nothing about the fix: it may not exercise the bug at all. If you cannot make the test fail on the pre-fix code, you have not reproduced the bug (N5) and you cannot claim the fix is verified. Capture both runs.
3. **E3 is necessary, never sufficient.** Run it - a broken build voids everything above it - but a clean build/typecheck/lint is a precondition for a "done" claim, not a form of one.
4. **E4 is hypothesis fuel only.** Use it to decide what to test, never as the test. If your evidence section reads like an argument instead of pasted output, it is E4. Cross-ref: `codofable-failure-archaeology` catalogs sessions where E4-as-proof produced confident false "done" claims.
5. **Evidence must be captured, not remembered.** Paste the actual command and actual output into your report. "I ran the tests and they passed" without output is a claim, not evidence (N1). After context loss, re-run - never trust remembered evidence (N10).
6. **Downgrade honestly.** If E1/E2 is genuinely impossible in-session (e.g. the behavior requires production credentials you do not have), say so explicitly, present the E3/E4 evidence you do have, label the claim "candidate - unverified end-to-end" (N8), and route the decision to a human. Never silently present E3 as if it settled the question.

Mapping to change classes (defined in `codofable-change-control`): Class 2 changes require E1 or E2 on the final state; Class 1 requires "verification evidence appropriate to the change", which this hierarchy makes precise - pick the highest level the change can support, and never claim a level you did not reach.

## Acceptance-threshold discipline

An acceptance threshold is the pre-committed, numeric or binary criterion that decides whether a change is accepted ("p95 latency under 200 ms", "all 314 tests pass", "output byte-identical to golden file").

Rules:

1. **Thresholds are set BEFORE running the measurement.** Write down the pass/fail criterion, then measure. This is the same predict-before-run discipline as `codofable-research-methodology` (hypothesis-predicts-numbers): a threshold chosen after seeing the result is a description of the result, not a test of it.
2. **"It looks better" is not a threshold.** Neither is "noticeably faster", "seems fixed", or "cleaner". If you cannot state the criterion as a command plus an expected observation ("run X, the number must be <= Y", "run X, exit code must be 0"), you do not have a threshold yet - go get one before measuring.
3. **Changing a threshold after seeing results is an N2 event.** Widening a tolerance, lowering a target, or reinterpreting "pass" because the measurement missed is weakening verification to make it pass. It requires an explicit human-approved gate: state the original threshold, the observed result, the proposed new threshold, and the justification, then STOP and wait for approval. Silently moving the goalposts is a blocking violation.
4. **Record the threshold with the evidence.** A report should read: "Threshold (set before measurement): X. Command: Y. Observed: Z. Verdict: pass/fail." That ordering is auditable; "measured Z, which seems fine" is not.

Legitimate threshold revision exists - sometimes the original threshold was genuinely wrong (measured the wrong thing, physically unachievable, based on a false assumption). The discipline does not forbid revision; it forbids UNGATED revision. The gate exists so a human sees the goalpost move.

## The golden inventory

The **golden inventory** is a project's named, written list of checks that define "green" - the concrete meaning of "the project is healthy" and the baseline every change must preserve. If it is not named and listed, "all checks pass" is unfalsifiable: nobody can tell whether you ran all of them.

Every project needs one. Rules:

- The inventory is a finite, enumerable list of commands/gates, each with its expected outcome.
- "Green" means every item in the inventory passes on the final state - not "the checks I happened to run".
- A change may not shrink the inventory (delete/skip/quarantine a check) without an N2 gate.
- When you enter a repo, discovering its golden inventory is part of onboarding; when you leave a report, state which inventory items you ran.

### This library's golden inventory (as of 2026-07-05)

| # | Check | Expected outcome | Source |
| --- | --- | --- | --- |
| 1 | The library validator: `validate_skills.sh` (shipped in `codofable-diagnostics-and-tooling`, see that skill for exact path, usage, and interpretation) | Exit 0; every skill directory has a valid SKILL.md per the format contract | [craft] - script authored 2026-07-05; verify it exists before relying on it (command in Provenance) |
| 2 | The three-reviewer gate for content changes: FACTUAL, DOCTRINE, and USABILITY review passes over changed skills, per the project manifest's Phase 3 | No blocking findings outstanding | [repo] - `README.md`, "Phase 3 — Review and fix" |

This repo has no CI configuration and no application test suite (verified 2026-07-05: the repo contains only `LICENSE`, `README.md`, and `.claude/`), so the inventory above IS the full definition of green here.

### Discovering a target repo's golden inventory

When dropped into an unfamiliar repo, derive its golden inventory from what its CI actually enforces. Finding and mining CI is `codofable-repo-onboarding`'s job (its Step 3, CI-as-ground-truth, has the discovery commands). The inventory-specific steps once CI is located:

1. Extract the commands CI actually runs (generic pattern, adapt per repo): `grep -nE 'run:|script:' .github/workflows/*.yml` - each gating job's commands are candidate inventory items.
2. Check the contributor docs (`CONTRIBUTING.md`, `docs/development*`) and task runners (`Makefile`, `justfile`, `package.json` "scripts", `noxfile.py`, `tox.ini`) for a canonical "check everything" target - these often bundle the inventory into one command.
3. Write the inventory down as an explicit list in your task notes before making changes, and run it once UNCHANGED to capture the baseline: you must know the repo was green before your change to attribute any red to your change.
4. If baseline is already red, record which items fail before you touch anything - those failures are pre-existing, and your obligation is "no NEW reds", stated explicitly in your report (N8: label what you did and did not prove).

## Adding tests to an unfamiliar repo

Adding a test is a behavior-changing edit: it alters what "green" means and what CI runs. It is Class 2 per `codofable-change-control` - it needs its own evidence and its own statement of what was verified. Procedure:

1. **Find the existing harness first.** Locate the test framework, runner, and invocation the repo already uses (see the golden-inventory discovery above; also `ls tests/ test/ spec/ src/**/*test*` as a pattern). NEVER introduce a second test framework because you know it better - that is a drive-by change to project infrastructure and an N3 violation. If the repo uses unittest, write unittest; if it uses a bespoke harness, learn the bespoke harness.
2. **Mirror the conventions of the nearest existing tests.** Before writing, read 2-3 tests closest to the code you are testing and copy their: file location, file naming (`test_x.py` vs `x_test.go` vs `x.spec.ts`), fixture/setup style, assertion style, and how they are registered with the runner (some harnesses need explicit registration; a test the runner never collects is silently worthless - confirm collection by seeing your test's name in the runner output).
3. **The new test must fail without your change.** Run it against the pre-change code (or with your change temporarily reverted) and capture the failure. A new test that passes on the unmodified code asserts something that was already true; it is not evidence for your change (binding rule 2 above). For a pure regression-prevention test added without a code change, the analogue is: mutate the guarded behavior once, watch the test fail, restore - proving the test can detect what it guards.
4. **Run the harness's relevant scope, then the golden inventory.** Your test passing alone is not enough; your test addition must not break collection, fixtures, or unrelated tests.
5. **Report per Class 2:** what the test asserts, the failed-before output, the passes-after output, and the inventory items you re-ran.

## Flakiness

**Definition:** a test is flaky when the same code produces different outcomes across runs - pass sometimes, fail sometimes, with zero changes to code, test, or declared inputs. Common mechanisms: timing/races, unseeded randomness, shared state between tests, network/external dependencies, resource exhaustion.

**The rule:** a flaky test can neither prove nor refute your change until it is treated statistically. One green run of a flaky test is not E2 - you may have sampled the lucky outcome. One red run does not refute your fix - you may have sampled the unlucky one. To extract evidence from a flaky test you need repeated runs and a statistical read (how many runs, what pass-rate change is significant): that math, with worked examples, lives in `codofable-proof-and-analysis-toolkit`.

**Detection (generic pattern):** re-run the suspect test several times on IDENTICAL code, e.g.:

```bash
# pattern - adapt runner and selector to the repo:
for i in 1 2 3 4 5 6 7 8 9 10; do pytest tests/test_x.py::test_y -q; echo "run $i exit=$?"; done
```

Mixed exit codes on identical code = flaky. All-same outcome across ~10 runs is not proof of stability, but flakiness is no longer your default explanation.

**Interim discipline (until the statistical treatment or a root-cause fix):**

- **Quarantine explicitly, never delete.** Deleting or silently skipping a flaky test is weakening verification - an N2 event requiring a human-approved gate. Legitimate quarantine uses the harness's visible, attributable mechanism (e.g. an expected-failure/skip marker WITH a reason string and a tracking reference) so the quarantine is auditable and reversible - and the quarantine itself is a Class 2 change through the normal gate.
- A quarantined test stays in the golden inventory as a named known-red with an owner/tracking note; it does not vanish from "green means".
- Never claim the flaky test as evidence in either direction in a "done" report; state "test X is flaky (observed n passes / m fails on identical code), excluded from evidence, quarantined via [mechanism] with approval [where]".
- Root-causing the flake is a separate task (`codofable-debugging-playbook`); do not let it silently expand your current task's scope (N3).

## Provenance and maintenance

- Evidence-hierarchy definitions (E1-E4) and the "done requires E1 or E2" rule: canonical project doctrine, authored 2026-07-05 as part of the founding skill library. [craft], adopted as project canon (the repo `README.md` manifest mandates the doctrine; `codofable-change-control` holds the sibling canon); this skill is the single home - if these definitions must change, change them HERE and fix citations elsewhere.
- The three-reviewer gate (FACTUAL/DOCTRINE/USABILITY): [repo] - stated in `README.md` Phase 3. Re-verify: `grep -n "Three parallel reviewers" /path/to/repo/README.md` (run from the repo root; verified present 2026-07-05).
- Repo contents claim ("no CI, no application test suite; only LICENSE, README.md, .claude/"): [repo], as of 2026-07-05. Re-verify: `ls -A` at the repo root and `git log --oneline c321e16` (the pre-library history is exactly two commits; library-authoring commits after them are expected and do not affect this claim).
- Golden-inventory item 1 (`validate_skills.sh`): the validator ships with `codofable-diagnostics-and-tooling`, authored concurrently with this skill on 2026-07-05. [craft] - re-verify existence before relying on it: `ls .claude/skills/codofable-diagnostics-and-tooling/scripts/` from the repo root; consult that skill's SKILL.md for the authoritative invocation.
- All shell snippets in "Discovering a target repo's golden inventory", "Adding tests", and "Flakiness" are marked as generic patterns - adapt to the target repo; they were not run against a target repo here because this repo has no CI or test suite to run them on.
- Example tool names (pytest, tsc, cargo, ruff) are illustrative ecosystem-generic examples [craft], not claims about this repo.
- Volatile facts in this file are date-stamped 2026-07-05. If the repo gains real CI, update "This library's golden inventory" first - it is the most drift-prone section.
