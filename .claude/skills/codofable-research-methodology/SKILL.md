---
name: codofable-research-methodology
description: The discipline that turns a hunch into an accepted result — the project's scientific method as procedure. Load this skill when a session is about to investigate WHY something behaves as it does, propose a mechanism or root cause, run an experiment, claim "X causes Y", accept or reject a hypothesis, or decide whether an idea should be adopted or retired. Trigger phrases and situations - "I think the cause is...", "let's test whether...", "my hypothesis is...", "this proves...", "the experiment shows...", designing a benchmark or A/B comparison, deciding what to do with a stalled or disproven idea, or noticing an anomaly worth chasing. Provides the evidence bar (one mechanism explains ALL observations including negatives, plus assigned adversarial refutation), the pre-registration template (predict numbers BEFORE running), the idea lifecycle state machine (hunch to ADOPTED or RETIRED), and a scan list for finding good research questions.
---

# codofable-research-methodology

This skill is the project's scientific method, stated as procedure. It defines when a hunch becomes a claim, when a claim becomes an accepted result, and what happens to ideas that do not survive. Two commitments do most of the work: (1) a result is accepted only when one mechanism explains **all** observations including the negatives, and (2) every result must survive **assigned** adversarial refutation before adoption. Everything else here — pre-registration, the lifecycle state machine, the idea-scan list — exists to make those two commitments executable by a zero-context session.

## When to use this skill

- You are about to claim a mechanism: "X happens because Y."
- You are designing any experiment, benchmark, comparison, or measurement whose outcome will change what the project believes or does.
- You have a hunch and need to know what to do with it before it evaporates or, worse, gets stated as fact.
- You are reviewing someone else's claimed result and need the checklist for whether it clears the bar.
- An idea has been sitting as "candidate" and you need to drive it to ADOPTED or RETIRED.
- You just saw an anomaly — a number that is right when it shouldn't be, or wrong when the story says it should be right.

## When NOT to use this skill

| Situation | Use instead |
|---|---|
| You want the project's specific open research problems, their SOTA context, and first-three-steps plans | `codofable-research-frontier` |
| You are verifying that a routine task is actually done (the "done"-claim gate) | `codofable-verified-done-campaign` |
| You are debugging a concrete failure with a reproducer in hand | `codofable-debugging-playbook` (its discriminating-experiment method is this skill's evidence bar applied to bug hunts) |
| You need statistical recipes (flakiness stats, bisection, performance measurement mechanics) | `codofable-proof-and-analysis-toolkit` |
| You need the evidence hierarchy E1–E4 itself defined | `codofable-validation-and-qa` (cite it; do not restate it) |

## 1. The evidence bar

A result is **accepted** only when BOTH of the following hold. These are verbatim commitments; do not weaken them situationally.

### 1a. One mechanism explains ALL observations, including the negatives (N4)

Per N4 (full rationale in `codofable-change-control`): one mechanism must explain ALL observations, including the negatives, before a root cause is accepted.

"Including the negatives" means, concretely:

- **The cases where the effect did NOT appear.** If your mechanism says "the cache causes the slowdown," it must also explain every run where the cache was hot and there was no slowdown. If it can't, you don't have the mechanism yet.
- **The anomaly you are ignoring is usually the refutation.** The observation you mentally filed under "weird, probably unrelated" is the single most likely disproof of your story. Before accepting, explicitly list every observation from the investigation — passing and failing, expected and odd — and check each one against the mechanism. One unexplained observation blocks acceptance; it either gets explained or it stays a labeled open question attached to the candidate, and the candidate stays a candidate (per N8).
- **A mechanism that explains only the positive cases is a story, not a result.** Almost any hypothesis can be made to fit the data that suggested it. The negatives are where hypotheses die, which is why they are the required part.

Operational check before you write "root cause" or "accepted": produce a two-column table — *observation* | *how the mechanism produces it* — covering every observation, then confirm no row is blank. [craft]

### 1b. It has survived ASSIGNED adversarial refutation

"Invited to comment" is not refutation. The practice is:

- A **fresh agent or person** — someone who did not build the claim and has no authorship stake in it — is **explicitly assigned** the job of breaking it. Assignment matters: an open invitation reliably produces polite nodding; a named refuter with a charter produces attacks. (Mechanics of spawning the fresh agent and isolating its write scope: the reviewer pattern in `codofable-orchestration`.)
- The refuter's success condition is finding a break, not confirming the result. Their report must either (a) present a concrete refutation — an observation the mechanism cannot produce, an alternative mechanism fitting all the same data, or a flaw in the experimental procedure — or (b) state which specific attacks were tried and failed. "Looks good to me" with no attacks listed is a failed refutation *run* (redo it), not a survived refutation.
- The claim survives only when the refuter's attacks were genuinely run (commands executed, per N1) and the result held.

**Refuter's charter template** — fill in and hand to the fresh agent verbatim:

```
REFUTATION ASSIGNMENT
Claim under attack: <the one-sentence claim, exactly as its author states it>
Pre-registration doc: <path to the hypothesis/prediction/decision-rule block>
Evidence offered: <paths/transcripts the author cites>

Your job is to BREAK this claim, not to review it. You succeed by refuting it.
Required attacks (run all that apply; add your own):
1. Alternative mechanism: propose >=1 different mechanism that fits every cited
   observation. If one exists, design and RUN a discriminating experiment whose
   predicted outcome differs between the two mechanisms.
2. Negative sweep: list every observation in the evidence, including anomalies
   mentioned in passing. Find one the mechanism cannot produce.
3. Procedure attack: re-run the author's experiment from their exact procedure.
   Any deviation between their transcript and yours is a finding.
4. Boundary attack: push one input to an edge (empty, huge, unusual encoding,
   different environment) where the mechanism makes a prediction, and test it.
Report format: for each attack — what you predicted, what you ran, actual
output, verdict (BREAK / HELD / INCONCLUSIVE). No attack run = no verdict.
Constraints: read-only outside your scratchpad (Class R per
codofable-change-control); you may not edit the claim or its evidence.
```

Anything that has not cleared BOTH 1a and 1b is at best a **candidate** (N8) and must be labeled as such everywhere it is mentioned.

## 2. Pre-registration: hypothesis predicts numbers BEFORE running

Before any experiment whose outcome will change a belief, write down — in this order, before executing anything:

1. **Hypothesis** — the mechanism, one sentence, falsifiable.
2. **Exact procedure** — the commands you will run, verbatim, including the fixture setup.
3. **Predicted observable** — a **number or exact output**, not a direction. "It will be faster" is void; "the second run prints `3`" is a prediction. If the hypothesis cannot yield a number or exact output, it is not ready to test — sharpen it first.
4. **Decision rule** — written before running: *if I observe A, I believe X; if I observe B, I believe Y; anything else → INCONCLUSIVE, and here is what I do next.* Every possible outcome must map to a belief update decided in advance.

**Pre-registration template** — copy this block into your working notes and fill it in before touching the shell:

```
PRE-REGISTRATION                                   date: <YYYY-MM-DD>
H:            <one-sentence falsifiable mechanism>
Procedure:    <exact commands, in order, incl. fixture setup>
Prediction:   <a number or exact output per command — not a direction>
Decision rule:
  - If <exact outcome A>  -> H supported; next: <action>
  - If <exact outcome B>  -> H refuted;   next: <action>
  - Anything else         -> INCONCLUSIVE; next: <the follow-up experiment>
Run AFTER filling in every line above. Paste raw output below the line.
--------------------------------------------------------------------
<raw transcript>
Verdict: <supported | refuted | inconclusive>, per the rule above.
```

**Why post-hoc thresholds are void.** If you pick the success threshold *after* seeing the data, you are not testing the hypothesis — you are decorating the data. This is the garden of forking paths [craft]: at every analysis step there are many defensible choices (which runs count, which metric, which cutoff, which outliers are "obviously" noise), and a motivated analyst — human or model — will unconsciously walk the path that reaches significance, without ever feeling dishonest at any single step. Enough forks guarantee *some* path yields a positive result even when there is nothing there. Pre-registration removes the forks: the path is chosen while you are still ignorant of the outcome, so the outcome can actually surprise you. The same rule appears as N2 in the verification context (never weaken verification to make it pass — thresholds and assertions are fixed before the run; see `codofable-validation-and-qa` for how N2 governs acceptance thresholds). N2 and pre-registration are the same commitment pointed at different targets: the standard is set before the evidence arrives, or the evidence is void.

A prediction that comes true is only informative in proportion to how easily it could have come out false. Predict exact numbers because exact numbers can fail. [craft]

## 3. The idea lifecycle — a state machine

Every idea in this project is in exactly one of these states. Ideas do not skip states, and both terminal states are legitimate outcomes.

```
hunch -> written hypothesis (pre-registered) -> candidate -> evidence gathered
      -> refutation assigned & survived -> ADOPTED
                                        \-> RETIRED (at any state after "hunch")
```

| State | Entry criteria | Exit criteria | Artifact produced |
|---|---|---|---|
| **Hunch** | A suspicion exists (see Section 4 for where to find them) | Written down as a falsifiable one-sentence hypothesis, or consciously dropped | One line in working notes; nothing claimed |
| **Written hypothesis** | Pre-registration block (Section 2) fully filled in BEFORE any run | Experiment executed per the exact registered procedure | Completed pre-registration doc with raw transcript |
| **Candidate** | Decision rule fired "supported" at least once | Evidence gathered to E1/E2 (per the hierarchy in `codofable-validation-and-qa`), or refuted | The claim, labeled `candidate` per N8, everywhere it appears; if the idea alters runtime behavior, it lives behind an experiment-labeled flag per `codofable-config-mapping` — never in the default path |
| **Evidence gathered** | E1 or E2 evidence in hand; every observation (incl. negatives) explained per Section 1a | Refuter assigned with the Section 1b charter | Observation-vs-mechanism table; evidence transcripts |
| **Refutation survived** | Refuter's report shows real attacks run, verdict HELD on all | Routed to adoption | Refuter's report, attached to the claim |
| **ADOPTED** (terminal) | Both bars of Section 1 cleared | — (may later be re-opened by new contradicting evidence) | The behavior change lands as a **Class 2 change through `codofable-change-control`** — adoption never routes around change control; the `candidate` label is removed |
| **RETIRED** (terminal) | Refuted by decision rule, broken by refuter, or overtaken — at any state past hunch | — | An entry in `codofable-failure-archaeology`: symptom/idea → why retired → **the evidence** → status: `retired`. Flag removed or marked dead per `codofable-config-mapping` |

**Retirement is a success state, not a failure.** A retired idea with recorded evidence is knowledge: it fences off a wrong path forever. An *unrecorded* retirement is the failure — the next session (or the next model) re-derives the same hunch, spends the same effort, and re-fights the same battle, because nothing says it was already fought. If you retire an idea without writing the archaeology entry, you have converted a completed experiment back into an open question at full price. [craft]

Rules of movement:
- No idea is discussed as fact while left of ADOPTED (N8).
- No experiment runs before its pre-registration block is complete (Section 2).
- No adoption without a refuter's HELD report (Section 1b).
- No retirement without the archaeology entry.

## 4. Where good ideas come from — a scan you can actually run [craft]

Good research questions are rarely summoned; they are noticed. When you want one — or when you finish a task with time to bank an observation — run this scan:

1. **Anomalies in passing runs.** The number that is right for the wrong reason: a test that passes faster than physically plausible, a metric that is suspiciously stable, an output that is correct although the code path you just traced shouldn't produce it. Passing-but-odd is a richer vein than failing, because nobody else is looking at it.
2. **Negative results and their boundary conditions.** Every "that didn't work" implies a boundary: it failed *here* — where exactly does it start failing? The boundary is usually where the real mechanism lives.
3. **Two things that "should" behave identically and don't.** Two environments, two flags, two code paths, two model classes documented as equivalent — any measured difference between them is a mechanism waiting to be named. (This is also the shape of the library's core frontier question — does a session WITH a skill behave differently from one without? — see `codofable-research-frontier`.)
4. **The failure catalog's open entries.** Read `codofable-failure-archaeology` for entries whose status is open or partially explained. Each is a pre-vetted question with prior evidence already attached.
5. **Provenance sections with drifted facts.** Re-run the one-line re-verification commands in other skills' "Provenance and maintenance" sections. Any command whose output no longer matches the recorded fact is both a maintenance task and, sometimes, a research question: *what changed, and why didn't we notice?*

Whatever the scan surfaces enters the lifecycle at **hunch** — one written line — and earns nothing more until pre-registered.

## 5. Worked micro-example: the full lifecycle on a real question

Executed in this session, 2026-07-05, in a throwaway fixture directory, GNU coreutils `wc` 9.4 on Linux. The transcripts are real captured output [craft-demo, run in-session]; the commands are ecosystem-generic and will behave identically on any GNU/Linux box. Everything below was written and run in the order shown — prediction first, execution second.

**Hunch** (from a Section-4 #3 scan — two things that "should" be the same): a 3-line file and `wc -l` "should" agree that it has 3 lines. Do they always?

**Pre-registration** (filled in before running anything):

```
PRE-REGISTRATION                                   date: 2026-07-05
H:            wc -l counts newline (\n) BYTES, not human-visible lines; so a
              3-line file whose last line lacks a trailing newline reports 2.
Procedure:    printf 'alpha\nbeta\ngamma'   > no-trailing-newline.txt
              printf 'alpha\nbeta\ngamma\n' > with-trailing-newline.txt
              wc -l no-trailing-newline.txt
              wc -l with-trailing-newline.txt      # negative control
Prediction:   first wc -l prints 2; control prints 3.
Decision rule:
  - If 2 and 3        -> H supported; promote to candidate, assign refuter.
  - If 3 and 3        -> H refuted (wc counts records, not \n bytes); retire
                         with evidence.
  - Anything else     -> INCONCLUSIVE; inspect bytes with wc -c and re-derive.
```

**Run** (raw transcript):

```
$ printf 'alpha\nbeta\ngamma' > no-trailing-newline.txt
$ printf 'alpha\nbeta\ngamma\n' > with-trailing-newline.txt
$ wc -l no-trailing-newline.txt
2 no-trailing-newline.txt
$ wc -l with-trailing-newline.txt
3 with-trailing-newline.txt
```

**Decision rule fires:** observed `2` and `3` — the first branch. H supported. Note what the negative control bought: if only the first file had been tested, "maybe printf dropped a line" would explain a `2` equally well; the control file, identical except for one final byte, eliminates that alternative. One mechanism (counting `\n` bytes: 2 in the first file, 3 in the second) explains both observations — Section 1a satisfied for the evidence in hand.

**Candidate → assigned refutation.** A refuter charter (Section 1b) was issued against the claim "wc -l counts `\n` bytes." The refuter's boundary attacks, each with its own pre-registered prediction *derived from the mechanism*:

- *Attack: CRLF line endings.* If wc counted "line records" it might treat `\r\n` specially; the byte-mechanism predicts `printf 'alpha\r\nbeta\r\ngamma' > f; wc -l f` → exactly `2` (two `\n` bytes).
- *Attack: content-free lines.* Byte-mechanism predicts `printf '\n\n\n' | wc -l` → `3` even though no line has content.
- *Attack: empty input.* Byte-mechanism predicts `printf '' | wc -l` → `0`.

Refuter's run (raw transcript):

```
$ printf 'alpha\r\nbeta\r\ngamma' > crlf-no-trailing.txt
$ wc -l crlf-no-trailing.txt
2 crlf-no-trailing.txt
$ printf '\n\n\n' | wc -l
3
$ printf '' | wc -l
0
```

Verdicts: HELD, HELD, HELD. Every attack's predicted number matched. The refuter also confirmed the mechanism is documented locally: `wc --help` (run in-session, coreutils 9.4) opens with "Print **newline**, word, and byte counts for each FILE" — `-l` is literally the *newline* count, not a line count. (POSIX additionally defines a line as requiring a terminating newline, which is the same mechanism; that source — pubs.opengroup.org, wc utility page — was NOT reachable from this sandbox and is cited from memory: verify it yourself before quoting onward.)

**Outcome: ADOPTED** as an accepted mechanism (as a piece of knowledge, this needs no Class 2 gate — nothing in the repo changes; had it implied a behavior change, e.g. "our line-count script must append a final newline before counting," that edit would route through `codofable-change-control` as Class 2 with this transcript as its E1 evidence).

Total cost: six commands. The point of the example is not `wc` trivia; it is the shape — number predicted before the run, a negative control that could have killed the hypothesis, a refuter with its own predicted numbers, and a decision rule that fired mechanically instead of being argued about afterward.

## Provenance and maintenance

- Doctrine cited (N1, N2, N4, N8, change classes, E1–E4) is canon owned by `codofable-change-control` and `codofable-validation-and-qa`; this skill cites and does not restate it. [repo — as of 2026-07-05]
- The Section 5 transcripts are real output captured in-session on 2026-07-05, GNU coreutils 9.4, Linux. `wc -l` semantics are POSIX-stable, but re-verify on a new platform with: `printf 'a\nb\nc' | wc -l` (expect `2`) and `wc --version | head -1`. [repo/doc]
- The `wc --help` "Print newline, word, and byte counts" wording was captured in-session (coreutils 9.4); re-verify with `wc --help | head -3`. [repo — as of 2026-07-05] The POSIX wc page (https://pubs.opengroup.org/onlinepubs/9699919799/utilities/wc.html) is cited from memory only — it was unreachable from this sandbox on 2026-07-05; treat it as unverified until you fetch it. [craft, pending doc]
- The refuter charter, pre-registration template, garden-of-forking-paths rationale, lifecycle table, and idea-scan list are the fellow's professional judgment, marked [craft] in place; they carry no repo history — this repository has no experiment log yet: its pre-library history is exactly two commits (`c30ac04` initial, `c321e16` manifest; verify with `git log --oneline c321e16`), and everything after those is library authoring, not experiments. [repo — as of 2026-07-05]
- Cross-referenced skills (`codofable-orchestration`, `codofable-config-mapping`, `codofable-change-control`, `codofable-failure-archaeology`, `codofable-validation-and-qa`, `codofable-research-frontier`, `codofable-verified-done-campaign`, `codofable-debugging-playbook`, `codofable-proof-and-analysis-toolkit`) are names from the library inventory (the 16-skill list in the repo `README.md` manifest, one directory per skill); re-verify existence with: `ls /path/to/repo/.claude/skills/`. [repo — as of 2026-07-05]
