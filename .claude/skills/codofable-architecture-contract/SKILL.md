---
name: codofable-architecture-contract
description: The codofable skill library's own architecture contract - its load-bearing design decisions with rationale, the invariants every skill must satisfy, and its known weak points stated plainly. Load this skill when editing, adding, removing, or reviewing ANY skill in this library; when deciding where a new fact should live; when two skills seem to contradict each other; when tempted to restate doctrine (N1-N10, change classes, evidence levels) instead of citing it; when renaming or renumbering anything other skills reference; or when proposing a structural change to the library itself (new skill, merged skills, changed taxonomy). Trigger phrases - "where should this go", "which skill owns this", "add a new skill", "restructure the library", "why is the library built this way", "is this a breaking change to the skills".
---

# codofable-architecture-contract

The system being architected in this repository IS the skill library itself: there is no application codebase here [repo]. This skill is the library's architecture contract. It records the load-bearing design decisions and WHY they were made, the invariants that must always hold (and how to check them mechanically), and the known weak points - stated plainly and labeled open, per N8. If you change the library's structure without reading this, you will probably break an invariant that another skill depends on.

Jargon, defined once:
- **Skill**: a directory under `.claude/skills/` containing a `SKILL.md` whose YAML frontmatter `description` tells a Claude Code session when to load it [doc].
- **Doctrine**: the canonical rules shared across the library - the ten non-negotiables N1-N10, change classes R/1/2/3, and evidence levels E1-E4. Defined in full in `codofable-change-control` (N1-N10, classes) and `codofable-validation-and-qa` (E1-E4); cited by number everywhere else.
- **Routing layer**: the set of all frontmatter descriptions. A session sees only descriptions until it decides to load a skill's body [doc].

## When to use this skill

- You are about to edit, add, remove, rename, or merge any skill in this library.
- You are reviewing skills (Phase-3-style factual/doctrine/usability review) and need the invariant list to check against.
- You cannot decide which skill should own a new fact or section, or you found the same fact stated in two places.
- You are considering changing anything that other skills cite by name or number: skill names, N-numbers, class labels, evidence levels.
- You want to understand or challenge a design decision ("why do skills repeat context instead of assuming the reader knows the library?").

## When NOT to use this skill

| If you need... | Use instead |
|---|---|
| House style, the skill template, sentence-level writing rules, the library maintenance protocol | `codofable-docs-and-writing` |
| How skill loading, frontmatter, context, and subagents mechanically work in Claude Code | `agentic-engineering-reference` |
| The full text and rationale of N1-N10 and change classes R/1/2/3 | `codofable-change-control` |
| The evidence hierarchy E1-E4 in full | `codofable-validation-and-qa` |
| The record of how the library's scope was settled and other resolved questions | `codofable-failure-archaeology` |
| The validator script that mechanically checks the invariants below | `codofable-diagnostics-and-tooling` |

This skill governs changes to the LIBRARY. For changes to any other system, use `codofable-change-control` directly.

## Design decisions

Each entry: decision → rationale → what breaks if violated. Rationale entries are [craft] (the retiring fellow's design judgment) unless tagged otherwise.

### D1. One home per fact; everyone else cross-references by skill name

**Decision.** Every fact, rule, table, and procedure has exactly one owning skill (the inventory in the repo `README.md` plus the authoring brief fixes ownership). Other skills refer to it by skill name (e.g. "see `codofable-validation-and-qa`") and, for numbered doctrine, by number only.

**Rationale.** Skills are edited independently, by different sessions, at different times. Two copies of the same rule WILL diverge - not might, will - because no editor reliably knows about the second copy. A cross-reference cannot fork; a restatement can.

**What breaks if violated.** Doctrinal fork: two skills give a Sonnet-class session different answers to the same question (e.g. two conflicting definitions of what counts as "done"). The session cannot tell which is canon, and the library's core promise - one consistent standard - is dead. Reviewers then have to diff prose across 16 files instead of checking one home.

### D2. Canonical doctrine lives in two homes; cited by number everywhere else

**Decision.** N1-N10 and change classes R/1/2/3 live in full (text + rationale) ONLY in `codofable-change-control`. Evidence levels E1-E4 live in full ONLY in `codofable-validation-and-qa`. Every other skill cites them bare: "per N2", "this is a Class 2 change", "requires E1/E2".

**Rationale.** This is D1 applied to the highest-stakes content. Doctrine is cited from nearly every skill; it has the most copies-waiting-to-happen and therefore the most fork risk. Numbering makes citations short, greppable, and unambiguous - `grep -rn "N2" .claude/skills/` finds every dependent of a rule before you touch it.

**What breaks if violated.** If a skill restates N2 in its own words and the wording drifts, sessions get a weakened or contradictory rule with the same number - worse than no rule, because it carries canon's authority. See also weak point W4: the numbering itself is now load-bearing.

### D3. Every skill is a self-contained runbook for a zero-context reader

**Decision.** Each skill must be executable by a reader who has loaded ONLY that skill: jargon defined at first use, commands copy-pasteable, no step that silently assumes another skill's body is in context. Cross-references (per D1) point elsewhere for depth, but the skill's own procedure must work standalone.

**Rationale.** Claude Code loads skill bodies individually and on demand - the description sits in context, the body loads only when the skill is invoked [doc: https://code.claude.com/docs/en/skills, "full skill content only loads when invoked"]. There is no moment when a session holds the whole library. A skill that says "as explained earlier" or leans on a sibling's definitions is broken for its actual runtime audience, even if it reads fine to a human browsing the repo.

**What breaks if violated.** A session loads the skill, hits an undefined term or an assumed prior step, and either stalls or - worse - improvises the missing piece from its own priors, which is exactly the behavior the library exists to replace.

**Tension with D1, resolved.** D1 forbids restating another skill's CANON; D3 requires defining TERMS locally. The line: a one-line definition of a term ("Class 2 = behavior-changing; see `codofable-change-control`") is D3-compliant context. Reproducing the rule's rationale, gate details, or full text is a D1 violation. Define, then point.

### D4. Frontmatter descriptions are the routing layer - a skill that doesn't trigger doesn't exist

**Decision.** Every description is written trigger-rich: third person, states exactly when a session should load the skill, includes concrete trigger phrases and situations, front-loads the key use case.

**Rationale.** The description is the ONLY part of a skill a session sees before deciding to load it; Claude uses it to decide when to apply the skill, and the listing text is truncated at 1,536 characters [doc: https://code.claude.com/docs/en/skills, frontmatter reference]. A brilliant body behind a vague description is unreachable knowledge - operationally identical to the skill not existing. Routing quality, not body quality, is the first bottleneck on the library's measured uplift (see `codofable-research-frontier`).

**What breaks if violated.** Silent failure, the worst kind: the session never loads the skill, follows its default behavior, and nobody sees an error. The library appears to "not work" with no diagnosable fault. Note this whole mechanism is untested at scale here - weak point W3.

### D5. Executable knowledge ships as scripts; judgment knowledge ships as checklists

**Decision.** Anything a machine can check is shipped as a runnable, tested script (in a skill's `scripts/` directory - see `codofable-diagnostics-and-tooling`, which owns the library validator and repo-recon scripts). Prose is reserved for judgment calls, and even then structured as checklists and decision tables, not essays.

**Rationale.** Prose instructions degrade under paraphrase, partial reading, and compaction; a script's behavior does not. "Run the validator and paste its output" produces E2-grade evidence; "carefully check the invariants" produces E4-grade intentions. Per the evidence hierarchy in `codofable-validation-and-qa`, only the former supports a "done" claim.

**What breaks if violated.** Checks silently decay into vibes. A reviewer "eyeballs" the invariants, misses one, and the library drifts while everyone believes it is being checked.

### D6. Every skill carries a Provenance section with re-verification one-liners

**Decision.** Every SKILL.md ends with `## Provenance and maintenance`: a date stamp for volatile facts, evidence-class notes, and one-line commands to re-verify anything that may drift.

**Rationale.** Facts drift - doc URLs move, platform behavior changes, repo state advances - but the prose recording them stays frozen and keeps asserting them with unearned confidence. A dated, re-runnable check converts "trust this sentence" into "run this command", which is the only honest offer a static document can make. This is N10's discipline applied to the library itself: re-verify from the world, not from memory.

**What breaks if violated.** Stale claims become indistinguishable from current ones. The first time a session follows a dead instruction, it learns to distrust the library wholesale - and per the repo manifest, wrong runbooks are worse than none [repo: README.md, "GROUND TRUTH ONLY" rule].

### D7. Every factual claim carries an evidence class: [repo] / [doc] / [craft]

**Decision.** Claims are tagged [repo] (verifiable in this repository's files or git history), [doc] (verifiable against a cited external document, URL given), or [craft] (professional judgment / first-principles reasoning, labeled as such).

**Rationale.** This library was authored WITHOUT a host codebase: the repository contains only a LICENSE, the README manifest, and these skills - two commits of history [repo: `git log --oneline` shows `c321e16`, `c30ac04`]. So the usual source of authority - "this is how this codebase demonstrably works" - is unavailable for most content. The tags keep the three very different confidence levels from blurring: a reader can weigh a [craft] heuristic differently from a [doc]-backed fact, and a reviewer knows exactly what to re-verify and where. This is N8 (label uncertainty) made mechanical.

**What breaks if violated.** Judgment calls masquerade as verified facts. The failure catalog especially (see W2) would read as lived history when it is not, which in this repo would also violate the no-invented-history rule (Invariant I4).

### D8. Scope is general craft, not repo documentation (settled)

**Decision.** Skills teach Fable-grade engineering discipline usable on ANY repository a session is dropped into. They do not document a specific application codebase.

**Rationale.** This was the owner's explicit Phase-1 answer (2026-07-05): the project is knowledge transfer from a retiring model to cheaper models and junior/mid engineers, and there is no application code here to document [repo: README.md]. The decision record lives in `codofable-failure-archaeology`; this contract states only the consequence: repo-specific detail belongs in examples and worked demonstrations, never as a skill's load-bearing content.

**What breaks if violated.** A skill hard-couples to this repo's incidental details and becomes useless in the target deployment (an arbitrary host repo). Worse, it invites invented "project history" to fill the documentation-shaped hole - see Invariant I4.

## Invariants

These must ALWAYS hold, for every skill, at every commit. Each is mechanically checkable; the library validator script in `codofable-diagnostics-and-tooling` is the canonical check - run it before and after any library change. The spot-check one-liners below are the fallback if you cannot locate the validator. Run all commands from the repo root.

| # | Invariant | Spot-check |
|---|---|---|
| I1 | Frontmatter `name` equals the directory name exactly. (In Claude Code the directory name, not `name`, sets the command [doc]; the library requires them equal so citations, paths, and commands can never disagree.) | `for d in .claude/skills/*/; do n=$(sed -n 's/^name:[[:space:]]*//p' "$d/SKILL.md" | head -1); [ "$n" = "$(basename "$d")" ] || echo "MISMATCH: $d has name '$n'"; done` |
| I2 | Every skill has a `## When NOT to use` section naming the sibling to use instead. | `grep -rLi '^## When NOT to use' .claude/skills/*/SKILL.md` (any output = violation) |
| I3 | Every skill ends with a `## Provenance and maintenance` section. | `grep -rL '^## Provenance and maintenance' .claude/skills/*/SKILL.md` (any output = violation) |
| I4 | No invented repo history: no incident, metric, revert, or commit is attributed to this repo beyond what `git log` shows. Every repo-history claim must be [repo]-verifiable. | `git -C . log --oneline` and compare against any skill text citing commits/incidents; there is no fully mechanical check - this one needs a human/model reviewer per the Phase-3 FACTUAL pass. |
| I5 | No skill contradicts N1-N10 or describes a path that routes around change classification (N9). In particular: no skill may tell a reader to skip gates, weaken verification (N2), or claim done below E1/E2. | Doctrinal review against `codofable-change-control` and `codofable-validation-and-qa`; greppable prefilter: `grep -rn 'skip.*test\|no need to verify\|trivial.*no class' .claude/skills/` then judge hits in context. |
| I6 | Cross-references name only skills that exist on disk. | `grep -rhoE 'codofable-[a-z][a-z-]*[a-z]\|agentic-engineering-reference' .claude/skills/*/SKILL.md \| sort -u \| while read s; do [ -d ".claude/skills/$s" ] \|\| echo "DANGLING: $s"; done` |
| I7 | Doctrine text (full N-rules, class gates, E-level definitions) appears only in its home skill (D2); elsewhere only bare citations. | `grep -rn 'N[0-9]\|Class [R123]\|E[1-4]' .claude/skills/*/SKILL.md` and inspect any hit outside the two home skills that includes rule text rather than a bare citation. |

If the validator and this table ever disagree about what the invariants are, that is itself a Class 2 defect in the library: fix one of them through the process in the next section, in the same change.

## Known weak points (all OPEN as of 2026-07-05)

Stated plainly, per N8. Do not paper over these when describing the library to anyone.

- **W1 - Zero measured uplift. The library's central claim is unproven.** The project's stated success criterion is measurable model uplift: a Sonnet-class session with this library outperforming one without [repo: README.md and the owner's Phase-1 answers]. As of 2026-07-05 no such experiment has run. Every "this makes sessions better" statement in this library is a candidate, not a result. The experiment design and falsifiable milestones live in `codofable-research-frontier`. Status: OPEN until the frontier experiment produces numbers.

- **W2 - No real incident base.** This repo's entire history is two commits [repo]. The failure catalog in `codofable-failure-archaeology` and the traps in `codofable-debugging-playbook` rest on [doc] and [craft] evidence - the fellow's cross-project experience and cited external material - not on incidents lived in this repository. They are plausible and honestly labeled, but they have not been validated against this project's own future failures. Status: OPEN; tightens only as real incidents accumulate and get recorded.

- **W3 - Description-based routing is untested at scale.** D4 bets the library on frontmatter descriptions triggering correctly. That bet is untested with 16 sibling skills competing in one listing: descriptions may overlap, shadow each other, or fail to fire on real phrasings. The failure mode is silent (see D4). No routing-accuracy measurement exists yet. Status: OPEN; a routing test belongs in the `codofable-research-frontier` experiment set.

- **W4 - Numbered doctrine makes renumbering a breaking change.** Because skills cite "N2" or "Class 2" bare (D2), the numbers are an API. Renumbering or redefining an existing number silently changes the meaning of every citation across the library. Amendment rule, binding: **append, never renumber.** New non-negotiables become N11, N12, ...; retired ones keep their number, marked retired in `codofable-change-control`, never reused. Any doctrine amendment is at least a Class 2 change to the library and routes through `codofable-change-control`. Status: OPEN as a permanent structural risk - the rule mitigates it, nothing eliminates it.

## How to propose an architectural change to the library

A change to the library's structure - adding/removing/renaming/merging skills, moving a fact's home, amending doctrine, changing an invariant - is a change to a behavior-carrying system and gets no exemption from the library's own rules (N9: nothing is too trivial to classify).

1. **Classify it** per `codofable-change-control`. Typical mapping: fixing a typo in one skill = Class 1; moving a fact's home, editing doctrine text, changing a description (it alters routing behavior), or adding/removing a skill = Class 2; publishing/pushing the library outward = Class 3 (N6: needs explicit human authorization).
2. **Check blast radius before editing.** Grep for every citation of the thing you are changing: `grep -rn '<skill-name-or-N-number>' .claude/skills/` - every hit is a dependent you must update in the same change (D1, D2).
3. **Respect the amendment rule** for numbered doctrine: append, never renumber (W4).
4. **Update THIS contract in the same change** if the change touches any design decision, invariant, or weak point recorded here. An architectural change that leaves this contract stale is incomplete by definition - the contract would then violate its own D6.
5. **Verify**: run the library validator from `codofable-diagnostics-and-tooling` on the final state and capture its output. That is your E2 evidence; per N1, no "done" claim without it.
6. **Record** significant decisions (scope changes, taxonomy changes, retired doctrine) in `codofable-failure-archaeology` so the next editor does not re-fight a settled battle.

## Provenance and maintenance

Authored 2026-07-05. Evidence classes used throughout: [repo] = verifiable in this repository, [doc] = verifiable at the cited URL, [craft] = the retiring fellow's professional judgment, labeled as such. All design rationale in this file is [craft] unless tagged otherwise; all statements about Claude Code skill mechanics are [doc] against https://code.claude.com/docs/en/skills (fetched 2026-07-05); all statements about this repo's history and contents are [repo].

Volatile facts and their re-verification one-liners (run from the repo root):

- Repo history is still exactly two initial commits plus skill-library work (basis of D7, W2, I4): `git log --oneline` - as of 2026-07-05 this showed only `c321e16` and `c30ac04` [repo].
- Skill loading is description-routed and bodies load on demand; listing text truncates at 1,536 chars (basis of D3, D4): re-fetch https://code.claude.com/docs/en/skills and check the frontmatter reference and "full skill content only loads when invoked" [doc]. Platform behavior can change; re-verify before relying on exact limits.
- All 16 inventory skills exist on disk (basis of I6 and the cross-references in this file): `ls .claude/skills/` and compare against the inventory in the repo README/authoring records. As of authoring time, sibling skills were being written concurrently; if any referenced skill is missing, that is an I6 violation to fix, not a reason to edit this file's references.
- The library validator exists and covers I1-I3, I6, I7: check `ls .claude/skills/codofable-diagnostics-and-tooling/scripts/` and run the validator; if it is absent or covers a different invariant set, reconcile per the note under the Invariants table.
- Spot-check commands in the Invariants table were run against this library's state on 2026-07-05 and are POSIX-shell patterns; if a future skill uses frontmatter formatting these one-liners cannot parse (e.g. quoted `name:` values), prefer the validator script.
- W1 remains OPEN until `codofable-research-frontier`'s uplift experiment reports numbers; when it does, update W1 here in the same change (step 4 above).
