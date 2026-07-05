---
name: codofable-proof-and-analysis-toolkit
description: First-principles analysis recipes that turn "I believe" into "I proved" - load when you need to demonstrate that a fix (not a coincidence) changed an outcome, find which commit introduced a failure (automated git bisect), decide how many clean runs a flaky test needs before you may trust it, make a defensible performance claim (warmup, repetitions, median vs mean), shrink a failing input to a minimal reproduction (delta debugging), or isolate which single difference between a working and a broken configuration matters. Trigger situations - "prove the fix worked", "which commit broke this", "the test passed twice, is it fixed?", "is it actually faster?", "this repro is huge", "works on A, fails on B". Each recipe includes a worked example executed for real, and ships runnable scripts (flaky_bound.py, bench_median.py, ddmin_lines.py). Not for end-of-task done-verification (codofable-verified-done-campaign) or day-to-day triage (codofable-debugging-playbook).
---

# codofable-proof-and-analysis-toolkit

Recipes for proving claims from first principles instead of trusting impressions. Each recipe states when to use it, gives the procedure as numbered steps, shows a worked example that was actually executed (transcripts below are real output, trimmed only for length and with temporary paths shortened), explains how to interpret results, and lists the failure modes of the method itself. Evidence levels (E1–E4) are defined in `codofable-validation-and-qa`; the doctrine numbers (N-rules) live in `codofable-change-control`.

Scripts shipped in `scripts/` (Python 3, stdlib only):

| Script | Purpose | Verified |
|---|---|---|
| `flaky_bound.py` | 95% confidence bounds for flaky-test failure probability | 2026-07-05, outputs below |
| `bench_median.py` | Timing with warmup, N reps, median + spread | 2026-07-05, outputs below |
| `ddmin_lines.py` | Line-granularity delta debugging (ddmin by halves) | 2026-07-05, outputs below |

## When to use this skill

- You have a fix and must prove it is causal, not coincidental.
- A failure appeared somewhere in a range of commits and you need the culprit.
- A test is flaky and you must decide how much re-running constitutes evidence.
- You are about to claim "faster", "smaller", or any comparative number.
- A failing input/program is too large to reason about.
- Config A works, config B fails, and the diff has many axes.

## When NOT to use this skill

- Deciding what to verify before claiming a task done → `codofable-verified-done-campaign`.
- You do not yet have a reproduction or hypothesis → `codofable-debugging-playbook` (its loop feeds this toolkit at the "prove causality" step).
- Defining what evidence level a claim needs → `codofable-validation-and-qa`.
- Designing a pre-registered experiment → `codofable-research-methodology`.

## Recipe 1 — Causal-fix proof (the revert test)

**When:** every bug fix. This is the mechanical answer to "did MY change fix it, or did something else move?" (fix-by-coincidence is a fixation trap — see `codofable-debugging-playbook`).

**Procedure:**
1. With the fix present, run the failing test/check. Expected: PASS.
2. Remove ONLY the fix, keeping everything else identical: `git stash push -m fix -- <fixed-file>` (Class 1 per `codofable-change-control` — a local, reversible working-tree mutation; it touches nothing else and must be restored in step 4). The exact stash-by-pathspec pattern and its pitfalls (untracked test files, pop conflicts) are rehearsed in `codofable-verified-done-campaign` Gate B, Pattern B-2 — follow that pattern for the mechanics.
3. Run the same test. Expected: the ORIGINAL failure, same signature. A different failure means your fix interacts with something else — mechanism not yet understood (N4).
4. Restore: `git stash pop`. Run again. Expected: PASS.

**Worked example (executed 2026-07-05):** scratch repo with `calc.py` raising `KeyError: 'qty'` when the key is absent; fix is `x.get("qty", 1)`.

```text
--- 1) fix present:
PASS: qty defaults to 1
--- 2) fix stashed (pre-fix code):
FAIL: KeyError: 'qty'
(exit=1)
--- 3) fix restored:
PASS: qty defaults to 1
```

**Interpretation:** pass→fail→pass with the SAME failure signature in the middle is E2-grade causal evidence. Record all three outputs in your Done Statement (`codofable-verified-done-campaign` Phase 4).

**Failure modes of the method:** stashing the wrong scope (stash the fix file only, or you revert unrelated state); cached/compiled artifacts serving the fixed code at step 3 (clean build artifacts if the language caches); a test polluted by prior runs (run each step from the same clean starting state).

## Recipe 2 — Automated bisection (`git bisect run`)

**When:** a check that passed at some old commit fails now, and the culprit is unknown. Bisection is O(log n): 1,000 commits ≈ 10 probes.

**Procedure:**
1. Write a check script that exits 0 on good, non-zero on bad, using ONLY committed state. Verify it by hand at the known-good and known-bad endpoints first — an unverified oracle bisects garbage.
2. `git bisect start <bad-rev> <good-rev>`
3. `git bisect run ./check.sh`
4. Read "X is the first bad commit"; `git bisect reset`.
5. The culprit commit is a HYPOTHESIS about mechanism, not the proof — read its diff, explain the failure from it (N4), then confirm with Recipe 1 logic (revert just that change if feasible).

**Worked example (executed 2026-07-05):** scratch repo, 8 commits; commit 6 flips `app.conf` from `VALUE=ok` to `VALUE=broken`; check script greps for the good value.

```text
$ git bisect start HEAD "$(git rev-list --max-parents=0 HEAD)"
[50adb2d] commit 4
$ git bisect run ./bisect_check.sh
Bisecting: 1 revision left to test after this (roughly 1 step)
Bisecting: 0 revisions left to test after this (roughly 0 steps)
d0e5208... is the first bad commit
$ git show --no-patch --format=%s d0e5208
commit 6
```

Three probes over 8 commits found the planted culprit exactly.

**Failure modes of the method:** flaky check script (bisect assumes determinism — stabilize first, or wrap the check in "run 10×, bad if any fail", accepting the Recipe-3 error rates); the failure has multiple contributing commits (bisect finds one boundary, not the interaction); commits that don't build (exit 125 in the check script tells bisect to skip that commit — this is documented bisect behavior, re-verify with `git help bisect`); mutating working-tree state the check depends on.

## Recipe 3 — Flakiness statistics (how many clean runs is evidence?)

**When:** a test sometimes fails; someone says "I ran it twice, it passed, it's fixed."

**Model [craft, standard statistics]:** treat each run as an independent Bernoulli trial with unknown failure probability p. If a test passed N consecutive runs, the largest p still consistent with that at the 5% significance level satisfies (1−p)^N = 0.05, so p_upper = 1 − 0.05^(1/N) ≈ 3/N for N ≥ 30 (the "rule of three"). To CLAIM p < P at 95% confidence you need N = ⌈ln 0.05 / ln(1−P)⌉ consecutive passes.

**Procedure:** decide the p you need to claim BEFORE running (threshold-before-measurement — `codofable-validation-and-qa`); compute required N with the script; run N times; ANY failure restarts the count and, more importantly, hands you a reproduction to debug.

**Worked example (executed 2026-07-05):**

```text
$ python3 scripts/flaky_bound.py passes 2
after 2 consecutive passes: p <= 0.7764 (77.6%) at 95% confidence; rule of three: 3/2 = 1.5000
$ python3 scripts/flaky_bound.py passes 30
after 30 consecutive passes: p <= 0.0950 (9.5%) at 95% confidence; rule of three: 3/30 = 0.1000
$ python3 scripts/flaky_bound.py passes 100
after 100 consecutive passes: p <= 0.0295 (3.0%) at 95% confidence; rule of three: 3/100 = 0.0300
$ python3 scripts/flaky_bound.py need 0.05
to claim p < 0.05 at 95% confidence: need 59 consecutive passes (rule of three approximation: 60)
$ python3 scripts/flaky_bound.py need 0.01
to claim p < 0.01 at 95% confidence: need 299 consecutive passes (rule of three approximation: 300)
```

"Ran it twice, passed twice" is consistent, at 95% confidence, with a test that fails **78% of the time**. That is why it proves almost nothing.

Reality check against a known truth: a deliberately flaky script with true p = 0.30 was run 100 times → 25 observed failures (binomial noise around 30 is expected; a single batch of 100 gives roughly ±9 at 95%).

**Interpretation:** the bound is one-sided and assumes independence and a fixed p. Failures correlated with load, ordering, or time of day violate the model — the bound is then optimistic. Quarantine rules for flaky tests live in `codofable-validation-and-qa` (never delete — N2).

## Recipe 4 — Performance claims

**When:** before saying "faster", "slower", "no regression", or any latency/throughput number.

**Procedure:**
1. Pre-register the threshold that counts as a win (e.g. "median ≥ 10% lower"), per `codofable-research-methodology`.
2. Warm up (caches, JIT), then take N ≥ 20 repetitions. Report MEDIAN and spread; never a single run, and never the mean alone (one outlier poisons it).
3. Measure baseline and candidate under identical conditions: same machine, same load, interleaved or back-to-back runs, same input.
4. A difference smaller than the observed run-to-run spread of the baseline is NOISE, not a result.

**Worked example (executed 2026-07-05)** — even a trivial constant command has 1.4× run-to-run spread:

```text
$ python3 scripts/bench_median.py --warmup 3 --reps 20 -- git --version
samples_ms: 1.7 1.6 1.7 1.7 1.6 1.6 1.7 1.6 1.6 2.2 1.6 1.6 1.7 1.6 1.8 1.6 1.8 1.7 1.7 1.7
min=1.6  median=1.7  p90=1.8  max=2.2  mean=1.7
spread: max/min = 1.40x
```

**Interpretation:** if `git --version` varies 1.4× between identical runs, a claimed 5% improvement from one run of each variant is meaningless. Compare medians; sanity-check that the medians differ by more than each side's own spread.

**Failure modes of the method:** measuring on a loaded/shared machine (this sandbox included — note it when reporting); warmup too short; comparing runs taken at different times; letting the measured command fail silently (the script aborts on non-zero exit for this reason).

## Recipe 5 — Minimal-repro construction (delta debugging)

**When:** the failing input/program/config is too large to reason about. The invariant: EVERY accepted removal preserves the failure — you always hold a failing case (N5).

**Procedure:**
1. Write an oracle script: exit non-zero iff the failure of interest is present. Guard against "different failure counts as interesting" by matching the failure signature, not just any non-zero exit.
2. Run `python3 scripts/ddmin_lines.py <input> -- ./oracle.sh`. It tries subsets and complements by halves (Zeller's ddmin), only ever keeping candidates that still fail, and writes `<input>.min`.
3. If the full input does not fail, the script refuses to start ("nothing to minimize") — fix your repro first.
4. The minimal repro is the input to hypothesis formation in `codofable-debugging-playbook`.

**Worked example (executed 2026-07-05):** 16-line file where the failure needs BOTH `TRIGGER_A` (line 5) and `TRIGGER_B` (line 12):

```text
$ python3 scripts/ddmin_lines.py input.txt -- ./check.sh
  trial 0(sanity: full input): 16 lines -> STILL FAILS (keep)
  ...
  trial 36b(complement of 2): 2 lines -> STILL FAILS (keep)
  ...
minimized: 16 -> 2 lines, written to input.txt.min
$ cat input.txt.min
TRIGGER_A
TRIGGER_B
```

40 trials, fully automatic, and the two-element interaction was found — exactly the case where "delete halves by hand" stalls, because neither half fails alone.

**Failure modes of the method:** non-deterministic oracle (stabilize first or the reduction lies); oracle accepts a DIFFERENT bug as interesting (match the signature); semantic units that span lines (reduce at a coarser granularity first — files, then sections, then lines).

## Recipe 6 — Differential debugging (works on A, fails on B)

**When:** the same code behaves differently in two environments/configs, and the diff between them has many axes.

**Procedure:**
1. Materialize both configurations as comparable text (env dumps, config files, version lists): `diff <(sort a.env) <(sort b.env)`.
2. Enumerate the differing axes. Starting from the WORKING configuration A, flip exactly ONE axis per run to B's value. One axis per run is the entire method — flip two and a discriminating result identifies nothing.
3. The flip that makes A fail is the discriminating axis. (If no single flip fails: an interaction — flip pairs, or bisect the axis set by halves like Recipe 5.)
4. The axis is a mechanism HYPOTHESIS; explain WHY it matters (N4) before fixing.

**Worked example (executed 2026-07-05, procedure shape):** two 3-axis configs:

```text
$ diff config_A config_B | grep '^[<>]'
< TZ=UTC          > TZ=PST8PDT
< LANG=C          > LANG=de_DE
< SORT=stable     > SORT=quick
```

Three single-flip runs: A+TZ(B) works, A+LANG(B) works, A+SORT(B) fails → `SORT` is the discriminating axis. (Illustrative fixture: the per-flip pass/fail here demonstrates the bookkeeping, not a real program under test.)

**Failure modes of the method:** axes that are not independent (changing one silently changes another — verify the effective config after each flip); hidden axes not in your diff (hardware, kernel, clock); starting from B and flipping toward A (equally valid, but pick one direction and stay consistent).

## Choosing a recipe

| Situation | Recipe |
|---|---|
| "My fix works" | 1 (then `codofable-verified-done-campaign`) |
| "It broke somewhere in the last 200 commits" | 2 |
| "It passed when I re-ran it" | 3 |
| "This is faster now" | 4 |
| "The repro is 4,000 lines" | 5 |
| "Works in CI, fails locally" | 6 (after `codofable-debugging-playbook` triage) |

## Provenance and maintenance

- Authored 2026-07-05. All transcripts above are real output from fixtures run in a throwaway workspace on that date; temporary paths were shortened and long trial logs trimmed, numbers unaltered. [repo: the scripts in `scripts/`; the fixtures themselves were ephemeral by design]
- The statistics in Recipe 3 are standard results (Bernoulli / rule of three) [craft]; re-derive or spot-check: `python3 -c "print(1-0.05**(1/30))"` → 0.0950.
- Script health re-verification one-liners (run from this skill's directory):
  - `python3 scripts/flaky_bound.py passes 30` → expect `p <= 0.0950`.
  - `python3 scripts/bench_median.py --reps 5 -- git --version` → expect a 5-sample report, exit 0.
  - `seq 1 4 > /tmp/dd.txt && printf '#!/bin/sh\ngrep -q 3 "$1" && exit 1\nexit 0\n' > /tmp/dd.sh && chmod +x /tmp/dd.sh && python3 scripts/ddmin_lines.py /tmp/dd.txt -- /tmp/dd.sh && cat /tmp/dd.txt.min` → expect a single line `3`.
- `git bisect` exit-125 skip semantics: stated from git's documented behavior, not exercised here — re-verify with `git help bisect` [doc].
- Volatile: absolute timing numbers in Recipe 4 are machine-specific snapshots; the LESSON (spread exists) is the durable content.
