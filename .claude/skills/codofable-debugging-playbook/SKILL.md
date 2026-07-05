---
name: codofable-debugging-playbook
description: The general-craft debugging method for any codebase, as an executable procedure. Load this skill whenever a session is diagnosing a failure it does not yet understand — a failing or flaky test, "works locally, fails in CI", a regression after a merge, wrong output with no error, a crash, a hang or timeout, a performance cliff, or a broken build. Provides the core debugging loop (reproduce → stabilize → shrink → hypothesize → discriminating experiment → prove causality), a symptom→triage table with first questions and first experiments per failure class, a verified git-bisect walkthrough, the catalog of fixation traps (with tells and escape moves), and stop-and-reassess triggers. Do NOT load it for verifying an already-finished change (use codofable-verified-done-campaign) or for statistical analysis of flakiness (use codofable-proof-and-analysis-toolkit).
---

# Codofable Debugging Playbook

This skill is the debugging method itself: a repeatable procedure a zero-context engineer or Sonnet-class session can execute on ANY repository to go from "something is wrong" to "one proven mechanism explains everything, and the fix is verified causal". It is craft doctrine [craft], not documentation of any specific codebase — this repository has no application code and no incident history (its entire git history is two commits [repo]). Every command below is either run-in-session (marked with its transcript) or an ecosystem-generic pattern (marked "pattern").

## When to use this skill

Load this skill when:

- You are staring at a failure whose mechanism you do not yet understand: test failure, crash, wrong output, hang, flake, performance drop, build break.
- Someone says "it worked yesterday", "it works on my machine", "it fails only in CI", "it fails sometimes".
- You have a candidate fix but cannot yet state the mechanism that makes it work.
- You notice yourself editing code "to see if it helps" — stop, load this, restart at Step 1.
- A previous debugging attempt in this session stalled or went in circles.

## When NOT to use this skill

| Situation | Use instead |
|---|---|
| The change is finished and you need to verify it before claiming "done" | `codofable-verified-done-campaign` |
| You need statistical treatment of a flaky test (how many runs to conclude a fix worked, confidence bounds) or the full causal-fix proof recipe | `codofable-proof-and-analysis-toolkit` |
| You know the mechanism and just need to gate/land the fix | `codofable-change-control` |
| You are lost in an unfamiliar repo and can't even run it yet | `codofable-repo-onboarding` |
| You suspect the failure mode is an agentic-session pathology (compaction amnesia, stale state) rather than a code bug | `codofable-failure-archaeology` |

## The core loop (runbook)

Debugging is a loop, not a line. Run the steps in order; the loop exits only at Step 8. All investigation before an intentional fix is Class R (read-only) per `codofable-change-control`; the fix itself is Class 2.

1. **Reproduce (per N5).** Get the failure to happen in your session, on demand, and capture the exact command + output. A bug you cannot reproduce is a bug you cannot verify fixed. If you cannot reproduce yet, that IS the current problem — do not hypothesize about the bug's cause; hypothesize about what your environment lacks (see the triage table's "works locally, fails in CI" row, inverted).
2. **Stabilize the repro.** Make it fail the same way every time: pin the seed, the input, the port, the clock, the ordering — whatever varies. If it stays intermittent, measure the failure rate first so you can detect change later (pattern, shape verified in this sandbox 2026-07-05):
   ```sh
   pass=0; fail=0
   for i in $(seq 1 20); do
     if ./run-the-failing-thing >/dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); fi
   done
   echo "pass=$pass fail=$fail / 20 runs"
   ```
   Record the rate. An intermittent repro without a measured rate cannot support any later claim that a fix helped — for the statistics of "how many clean runs prove it", see `codofable-proof-and-analysis-toolkit`.
3. **Shrink it.** Remove everything not needed to trigger the failure: fewer files, smaller input, one test instead of the suite, no parallelism, default config. Each removal is itself a small experiment ("does it still fail without X?"). Stop shrinking when removing anything else makes the failure disappear — that boundary is information.
4. **Enumerate hypotheses — plural.** Write down at least three candidate mechanisms before testing any. If you can only think of one, you have not thought yet; force alternatives by layer (my code / dependency / config / environment / test itself / toolchain) and by time (what changed recently — code, deps, data, infra, calendar). Label each hypothesis "candidate" (per N8).
5. **Design the DISCRIMINATING EXPERIMENT.** Definition: a *discriminating experiment* is one whose outcome splits the hypothesis space — each possible result eliminates at least one candidate, ideally half of them, no matter which way it comes out. Contrast with a *confirming experiment*, which can only agree with your favorite hypothesis and teaches nothing when it does. Before running anything, write the prediction table:
   - "If hypothesis A is true, I will see X; if B, I will see Y."
   - If every hypothesis predicts the same outcome, the experiment is worthless — design a different one.
   The cheapest discriminating experiments are usually: binary search over history (`git bisect`), binary search over config/input (halve it), A/B over environment (diff the two), and adding one observation point at the boundary between two suspects.
6. **Run the experiment. Capture the output.** One variable at a time. If you changed two things and the behavior changed, you learned nothing attributable.
7. **Update and repeat.** Cross off eliminated hypotheses in writing. If the result eliminated nothing, the experiment was not discriminating — go back to Step 5, not Step 6. If all hypotheses are eliminated, your hypothesis space was too narrow — go back to Step 4 and widen (new layers, earlier in time, "the test/tooling is wrong", "two bugs, not one").
8. **Exit criterion (per N4): one mechanism explains ALL observations — including the negatives.** The negatives are the observations that did NOT happen: the configurations where it does not fail, the runs that passed, the platforms that are fine. If your mechanism cannot explain why the passing cases pass, it is not yet the root cause; it is a correlate. Stay in the loop.
9. **Prove causality, then fix via change-control.** Before claiming the root cause is fixed:
   - Apply the fix → failure gone (on the stabilized repro from Step 2).
   - Revert the fix → failure returns. This revert-test is the minimum causal proof; the full recipe (including flaky-failure variants where "gone" needs N clean runs) lives in `codofable-proof-and-analysis-toolkit`.
   - Then route the fix through `codofable-change-control` as a Class 2 change with E1/E2 evidence (hierarchy defined in `codofable-validation-and-qa`) — for a bug fix, the repro must fail before the fix and pass after, captured in-session (per N1).

## Symptom → triage table

Universal failure classes. For each: the first three discriminating questions to answer (each question's answer should eliminate hypotheses), and the first command-level experiment. All commands here are generic patterns unless marked verified; adapt names to the repo at hand. [craft]

| Symptom | First three discriminating questions | First experiment |
|---|---|---|
| **Works locally, fails in CI** | 1. Same commit SHA in both places? 2. Same toolchain/dependency versions? 3. What does CI have/lack that local doesn't (env vars, network, clock/timezone, CPU count, clean checkout)? | Diff the two environments (see below). Then reproduce CI's conditions locally one axis at a time: clean clone in a temp dir, `CI=true`, same container image if any. |
| **Intermittent / flaky failure** | 1. What is the measured failure rate (run it 20×, count)? 2. Does it correlate with parallelism, ordering, or timing (does `--jobs 1` / fixed seed / fixed order change the rate)? 3. Does it ever flake in isolation, or only in the full suite (shared-state suspect)? | Run the single test 20× alone, then 20× inside the suite; compare rates (loop pattern in Step 2). Pin the seed/order (pattern: `--seed 42`, `-p no:randomly`, `--test-threads=1` — flag names vary by ecosystem). Rate analysis: `codofable-proof-and-analysis-toolkit`. |
| **Regression after merge** | 1. What is the last known-good commit — verified by running, not by memory? 2. Is the failure deterministic at both endpoints (else you'll bisect noise)? 3. Did dependencies/data/infra change in the same window, or only code? | `git bisect` with an automated test — full verified walkthrough below. If deps are lockfiled, bisect covers them; if not, pin them first or you are bisecting two variables. |
| **Wrong output, no error** | 1. Is the INPUT to the failing stage already wrong (walk upstream), or does this stage corrupt it? 2. Wrong for all inputs or only some — what distinguishes the failing inputs? 3. Was it ever right (if yes → regression row)? | Bisect the pipeline: dump the intermediate value at the midpoint stage (`print`/log/debugger — one observation point) and compare against expected. Each probe halves the suspect region. |
| **Crash / exception** | 1. What is the FIRST error in the log (later ones are usually cascade)? 2. Does the top stack frame belong to your code or a dependency — and which frame is the last one you own? 3. Is the crashing value (null/index/type) wrong at the crash site, or already wrong when it entered? | Read the full stack trace bottom-up to the last frame you own; add one assertion/log just above it to test "value already bad on entry vs corrupted here" (pattern). That single probe discriminates callee-bug vs caller-bug. |
| **Hang / timeout** | 1. Is it hung (no progress) or just slow (progress, insufficient time)? 2. Where is it stuck — what does the stack/state say at the moment of hang? 3. Is it waiting on something external (lock, socket, subprocess, stdin)? | Snapshot the process while hung (pattern, by ecosystem): `py-spy dump --pid <PID>` (Python), `jstack <PID>` (JVM), `kill -QUIT <PID>` (Go, dumps goroutines), `gdb -p <PID> -ex 'thread apply all bt'` (native). One snapshot usually names the wait; two snapshots discriminate deadlock (identical) from livelock/slowness (moving). |
| **Performance cliff** | 1. Cliff since a commit (→ bisect with a timing script) or since an input/data change? 2. Where does the time actually go — measured by a profiler, not guessed? 3. Does cost scale with input size as expected, or did complexity change (O(n)→O(n²) shows as cliff)? | Time it end-to-end first (`time <cmd>` — pattern) to get a number; then profile before touching anything. Never optimize on a guess. Measurement discipline: `codofable-diagnostics-and-tooling`; performance measurement recipes: `codofable-proof-and-analysis-toolkit`. |
| **Build breaks** | 1. Does a pristine build fail too (`git stash` your edits or clean-clone to a temp dir — read-only w.r.t. history), or only incremental (stale cache/artifacts)? 2. Did the toolchain or a dependency version drift since the last green build? 3. First error in the build log (later errors are cascade)? | Clean rebuild in a scratch clone (pattern): `git clone <repo> /tmp/clean && cd /tmp/clean && <build cmd>`. Pristine-fails vs pristine-passes cleanly splits "code/deps broken" from "my workspace state is broken". |

**Environment diff pattern** (shape verified in this sandbox 2026-07-05; capturing the CI side requires adding an `env | sort` step to the CI job):

```sh
# on each side:  env | sort > env-local.txt   /   env | sort > env-ci.txt
diff <(sort env-local.txt) <(sort env-ci.txt)
```

Verified sample output on synthetic files:

```
1c1,2
< LANG=en_US.UTF-8
---
> CI=true
> LANG=C.UTF-8
```

Also diff toolchain versions (`node --version`, `python --version`, lockfile hashes) the same way — version skew is the most common "works locally" mechanism [craft].

## Worked example: git bisect mechanics (verified in-session)

`git bisect` is the canonical discriminating experiment for "regression after merge": every probe halves the suspect commit range regardless of outcome. The following was executed 2026-07-05 in a throwaway demo repository created for this skill (NOT this project's history — this repo has only two commits [repo]). Setup: 8 commits; commit 5 silently changed `+` to `-` in a `calc.sh` script; `test.sh` exits 0 iff `./calc.sh 2 3` prints `5`.

Commands run:

```sh
git bisect start
git bisect bad HEAD                 # newest commit: known failing
git bisect good <first-commit-sha>  # oldest commit: known good — VERIFY by running the test there first
git bisect run ./test.sh            # automates the loop; script must exit 0=good, 1-124/126/127=bad, 125=skip
```

Actual transcript (trimmed to the decisions):

```
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[ce16749...] commit 4: harmless comment
running './test.sh'
Bisecting: 1 revision left to test after this (roughly 1 step)
[ecaa457...] commit 6: harmless comment
running './test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[bcd91fc...] commit 5: refactor arithmetic (introduces bug)
running './test.sh'
bcd91fc24d9d68de8665a85364aec1ea3d674f0c is the first bad commit
    commit 5: refactor arithmetic (introduces bug)
 calc.sh | 2 +-
```

Then `git bisect reset` to return to your branch. 8 commits, 3 probes — log₂ scaling; 1000 commits is ~10 probes.

Craft rules that make bisect trustworthy [craft]:

- Verify BOTH endpoints by actually running the test before starting; a mislabeled "good" endpoint silently yields a wrong answer.
- The test must be deterministic at the failure (Step 2 of the core loop). Bisecting a flake converges on a random commit. If forced, wrap the test to run N times and fail on any failure — and treat the result as "candidate", to be confirmed by revert-test.
- Exit code 125 from the script skips an untestable commit (e.g. build broken for unrelated reasons).
- Bisect names the first bad commit; that is strong evidence, not yet mechanism. You still owe Step 8 (mechanism explains all observations) and Step 9 (revert-test) before fixing.
- In this project, `git bisect` is read-only investigation of history (Class R) but it moves HEAD; finish with `git bisect reset`, and per this library's write-scope rules do not run it inside a repo where you are prohibited from checkout-style operations — clone to a scratch directory instead.

## Fixation traps

The failure modes of the debugger, not the code. Each entry: how it feels from inside (you will not recognize the trap by feeling wrong — it feels like progress), the tell you can check objectively, and the escape move. All [craft] — general professional judgment; no incidents from this repository are cited because none exist [repo].

### Trap 1 — First-plausible-hypothesis lock-in
- **Feels like:** confidence. The first mechanism you imagined fits the headline symptom, so every subsequent action is about confirming it. You feel efficient.
- **The tell:** you have run ≥2 experiments and every one was designed to *confirm* the same hypothesis — none could have eliminated it. Check your notes: is there even a second hypothesis written down?
- **Escape:** return to core-loop Step 4 and write three mechanisms that are NOT your favorite, one per layer (code / dependency / environment / test / toolchain). Then design an experiment that discriminates between your favorite and the strongest alternative — one where a possible outcome would kill the favorite.

### Trap 2 — Fix-by-coincidence (symptom moved, mechanism unproven)
- **Feels like:** victory. You changed something, the failure stopped, you want to write "fixed".
- **The tell:** you cannot complete the sentence "it failed because ⟨mechanism⟩, and this change breaks that mechanism by ⟨…⟩". Or the change that "fixed" it is one you cannot connect to the failure (reordered imports, added a sleep, bumped a version "to be safe").
- **Escape:** run the revert-test (core-loop Step 9): revert the change; if the failure does not come back, your change was not the cause of the recovery — something else moved (cache, timing, state). Per N1 and N8, until the revert-test passes the status is "symptom currently not reproducing — cause unproven (candidate)", never "fixed".

### Trap 3 — Flakiness misattributed to determinism
- **Feels like:** a normal deterministic bug hunt. The failure happened, then after your edit it didn't, so the edit "worked" — but the failure was intermittent all along and you never measured it.
- **The tell:** you never established the baseline failure rate; your evidence for "fixed" is a single passing run of something that only failed sometimes.
- **Escape:** go back to core-loop Step 2: measure the rate over ≥20 runs before and after. If baseline is 30% failure, one green run is ~70% likely with no fix at all. For how many clean runs constitute evidence, use `codofable-proof-and-analysis-toolkit`.

### Trap 4 — Blaming the environment without an experiment
- **Feels like:** relief. "CI is flaky", "the runner is slow", "must be a network blip" ends the uncomfortable investigation with no code to change.
- **The tell:** the claim names no specific environmental variable and is backed by zero diffs or probes — it is E4 reasoning (plausibility only, per the `codofable-validation-and-qa` hierarchy) presented as a conclusion.
- **Escape:** make the environment claim falsifiable: name the axis (version? env var? CPU count? network?), then run the env-diff pattern above or reproduce that one axis locally. An environment hypothesis is a hypothesis like any other — it enters the Step 5 prediction table or it is not admissible.

### Trap 5 — Editing code you haven't read (violates N7)
- **Feels like:** momentum. The stack trace names a line, you jump in and change it, iterating compile-guess-compile without ever reading the surrounding function or its callers.
- **The tell:** you cannot summarize what the function you just edited is *supposed* to do, or who calls it. Your last three actions were edits with no intervening reads.
- **Escape:** revert to the last understood state. Read the full function, its contract, and at least one caller before the next edit. Per N7, no edit to unread code — ever; it converts one bug into two.

### Trap 6 — "Fixing" the test instead of the code (violates N2)
- **Feels like:** pragmatism. The assertion is "too strict", the tolerance "too tight", the test "outdated" — and loosening it makes everything green in one minute.
- **The tell:** your candidate fix touches only test files / assertions / tolerances / skip-lists, while the production behavior it guards is unchanged and you have not proven the test wrong against the SPEC (only against current behavior).
- **Escape:** treat "the test is wrong" as a hypothesis requiring the same evidence bar as "the code is wrong": show what the correct behavior is from spec/docs/contract, not from what the code currently does. If the test really is wrong, weakening it is still gated per N2 — explicit human approval, through `codofable-change-control`, never silently.

## Stop-and-reassess triggers

Mechanical circuit-breakers. When one fires, stop typing and run its action before the next experiment. [craft]

| Trigger | Action |
|---|---|
| 3 failed hypotheses in a row | Widen the hypothesis space (core-loop Step 4): you are probably searching the wrong layer. Explicitly add: "the test/harness is wrong", "there are two interacting bugs", "my repro is not reproducing the same bug", "the bug is older than I assume — bisect further back". |
| About to modify a 4th file for one fix | Re-check scope per N3 (smallest correct change). Either your mechanism is wrong (a true root-cause fix is usually local) or the task has silently grown beyond the bug — re-classify under `codofable-change-control` before continuing. |
| Same experiment run twice hoping for a different result | You have no active hypothesis. Return to Step 4 and write the prediction table before running anything else. |
| You catch yourself about to claim "fixed" without a captured failing-then-passing run | N1 stop. Produce the E1/E2 evidence or downgrade the claim to "candidate". |
| Context loss (compaction/restart) mid-investigation | Per N10: re-verify repro, current diff, and hypothesis list from the filesystem and repo — not memory — before resuming. |

## Provenance and maintenance

- Authored 2026-07-05 by the retiring fellow. Method content is [craft] — first-principles debugging doctrine, deliberately repo-agnostic; it does not drift with this repository.
- [repo] facts: this repository contains no application code and exactly two commits; no incidents or war stories exist to cite, and none are cited. Re-verify: `git -C /home/user/codofable log --oneline` (expect 2 commits as of 2026-07-05; more later is fine and does not affect this skill).
- Verified in-session 2026-07-05, in a throwaway scratch repository outside this project: the `git bisect start/bad/good/run` walkthrough (transcript above is the real output, SHAs from the demo repo), the `diff <(sort a) <(sort b)` env-diff shape, and the 20-run pass/fail counting loop. Re-verify bisect mechanics anytime: build an 8-commit scratch repo with a mid-history bug and rerun the four commands in the walkthrough.
- Pattern-only (not runnable here, correct per ecosystem docs as of training; re-verify against your target ecosystem before relying on flags): `py-spy dump`, `jstack`, `kill -QUIT` (Go), `gdb -p ... 'thread apply all bt'`, test seed/ordering flags (`--seed`, `-p no:randomly`, `--test-threads=1`), `git bisect` exit-code-125 skip semantics (`git help bisect` to confirm).
- Doctrine cited, not restated: N-rules and change classes live in `codofable-change-control`; evidence hierarchy in `codofable-validation-and-qa`; causal-proof and flakiness statistics in `codofable-proof-and-analysis-toolkit`.
