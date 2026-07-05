---
name: codofable-docs-and-writing
description: House style, the SKILL.md template, and the maintenance protocol for the codofable skill library. Load this BEFORE adding a new skill, editing any existing SKILL.md, writing or fixing a skill description, retiring/deprecating a skill, or reviewing a skill for style compliance. Provides the binding house-style rules (imperative runbook voice, evidence labeling, no oversell), a copy-pasteable template (inline short form plus references/TEMPLATE.md full form), a description-writing guide with anti-patterns, the authoring runbook (inventory check, validator, three review lenses, change-control routing), and the provenance re-verification and retirement procedures. Trigger phrases - "add a skill", "new skill", "edit the skill", "update SKILL.md", "skill template", "house style", "fix the description", "deprecate/retire a skill".
---

# Docs and Writing: How to Add or Edit a Skill in This Library

This skill is the style guide, template, and maintenance manual for the
codofable skill library itself. Follow it whenever you create, edit, or retire
any file under `.claude/skills/`. A "skill" here means a directory containing a
`SKILL.md` file (plus optional `scripts/` and `references/`) that a future
Claude Code session loads to work at this library's standard. Skills are
behavior-changing artifacts: a wrong runbook is worse than none, so authoring
is gated exactly like a code change.

## When to use this skill

- You are about to create a new skill directory under `.claude/skills/`.
- You are editing any existing `SKILL.md`, `references/*.md`, or skill script.
- You are writing or repairing a skill's frontmatter `description`.
- You are reviewing a skill for style, template, or provenance compliance.
- You need to retire, deprecate, or rename a skill.
- You touched a skill for any reason and need the re-verification checklist.

## When NOT to use this skill

| If you need... | Use instead |
|---|---|
| WHY the library is designed this way (inventory, invariants, one-home-per-fact rationale) | `codofable-architecture-contract` |
| HOW skill loading mechanically works (descriptions in context, body on invoke, subagents, compaction) | `agentic-engineering-reference` |
| The change classes and non-negotiables in full | `codofable-change-control` |
| The evidence hierarchy (E1-E4) in full | `codofable-validation-and-qa` |
| Running the validator or other measurement scripts | `codofable-diagnostics-and-tooling` |
| Spawning reviewer agents over the library | `codofable-orchestration` |

## House style (binding rules, with rationale)

These rules restate the library's authoring contract. Their `[repo]` anchor is
the "AUTHORING RULES" section of the repo `README.md` (line 41;
re-verify from the repo root: `grep -n "AUTHORING RULES" README.md`). Where this skill tightens
the README, the tightening is library convention declared here and enforced by
the validator.

| # | Rule | Rationale |
|---|---|---|
| S1 | **Imperative runbook voice.** "Run X. If you see Y, do Z." Address the reader as the actor. | The audience is a zero-context mid-level engineer or a Sonnet-class model session. Both execute instructions well and infer intent poorly; narration and hedging create ambiguity that a weaker model resolves wrongly. |
| S2 | **Copy-pasteable commands only.** If a command is runnable in this repo, run it before writing it down. If it is ecosystem-generic (e.g. `cargo test`), mark it "(generic pattern, not verified in this repo)". | A command that fails on paste destroys trust in the whole skill and sends the reader down a debugging detour the skill was meant to prevent. |
| S3 | **Define every jargon term at first use.** Including this library's own terms (skill, evidence class, change class, provenance). | Zero-context readers by definition lack the fellow's vocabulary. An undefined term is a silent fork: the reader guesses, and per N4 an unexplained guess later poisons root-causing. |
| S4 | **Tables and checklists over prose.** Prose only for rationale that genuinely needs it. | Runbooks are consulted mid-task under context pressure. Tables scan; paragraphs get skimmed and half-applied. |
| S5 | **No oversell.** Unproven ideas are labeled "candidate" or "open" (per N8, home: `codofable-change-control`). No claim of "done"/"verified" without in-session evidence (per N1). | The project's named hardest failure mode is the false "done" claim. A skill that overstates certainty trains every future session to do the same. |
| S6 | **Every skill states when NOT to use it and names the sibling** to use instead, by exact inventory name. | Descriptions route sessions to skills (see next section). Without explicit negative routing, adjacent skills get loaded interchangeably and facts drift into duplicate homes. |
| S7 | **One home per fact.** Before writing a fact, check whether it already lives in another skill; if so, cross-reference by skill name instead of restating. | Duplicated facts diverge silently on the next edit. The inventory check in the authoring runbook below enforces this. |
| S8 | **No private or session-specific paths as load-bearing sources.** Repo-relative paths and public URLs only. | Skills outlive the session that wrote them; a scratchpad or user-home path is dead the moment the container recycles. |
| S9 | **Date-stamp volatile facts** ("as of YYYY-MM-DD") and give a one-line re-verification command in Provenance. | Facts drift; a dated fact with a re-check command degrades gracefully into a prompt to re-verify. An undated fact degrades into a lie. |
| S10 | **Length discipline: aim 150-450 lines for SKILL.md; hard fail over 500.** Overflow goes to `references/*.md` in your own directory, linked one level deep. | Official guidance: keep the body under 500 lines and references one level deep, because nested references get partially read `[doc]` (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices). The validator enforces the limits. |

Evidence classes for factual claims (library convention; every volatile fact in
a Provenance section carries one):

- `[repo]` — verifiable in this repository's files or git history.
- `[doc]` — verifiable against a cited external document (give the URL).
- `[craft]` — professional judgment / first-principles reasoning, labeled as
  such; no external proof exists.

Binding rule for `[doc]` (library-wide): a source earns `[doc]` ONLY if it was
actually fetched and read in-session; a source known only from search snippets,
or unreachable from your environment, is tagged `⚠ unverified` /
`[craft, pending doc]` with the URL kept so the next maintainer can fetch it
and upgrade the tag.

## The template

Full form, with placeholder guidance and the provenance skeleton:
**[references/TEMPLATE.md](references/TEMPLATE.md)** — copy it to
`.claude/skills/<skill-name>/SKILL.md` and replace the placeholders.

Inline short form (structure only — the required sections, in required order):

```markdown
---
name: <skill-name>            # MUST equal the directory name exactly (library rule)
description: <third person; what it provides + exactly WHEN to load it + trigger phrases; <=1024 chars>
---

# <Title>

<One-paragraph purpose statement.>

## When to use this skill
- <concrete triggering situation>

## When NOT to use this skill
| If you need... | Use instead |
|---|---|
| <adjacent need> | `<sibling-skill-name>` |

## <Body sections — your charter defines them>

## Provenance and maintenance
| Fact | Class | As of | Re-verify with |
|---|---|---|---|
| <volatile fact> | [repo]/[doc]/[craft] | YYYY-MM-DD | `<one-line command>` |
```

Frontmatter facts, verified 2026-07-05 against the official docs:

| Fact | Source |
|---|---|
| `name`: max 64 chars; lowercase letters, numbers, hyphens only; no XML tags; must not contain the reserved words "anthropic" or "claude" | `[doc]` https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| `description`: non-empty, max 1024 chars, no XML tags; should say what the skill does AND when to use it | `[doc]` same URL |
| Claude Code treats frontmatter `name` as a display label defaulting to the directory name; the command name comes from the directory | `[doc]` https://code.claude.com/docs/en/skills |
| Malformed frontmatter YAML: the body still loads via `/skill-name`, but the description is empty so automatic triggering breaks; `--debug` shows the parse error | `[doc]` https://code.claude.com/docs/en/skills |
| In the skill listing, `description` (+ optional `when_to_use`) is truncated at 1,536 characters — put the key use case first | `[doc]` https://code.claude.com/docs/en/skills |
| This library additionally REQUIRES `name` == directory name and uses only `name` + `description` in frontmatter | `[repo]` library convention, declared here and checked by `validate_skills.sh` |

## Writing the description (the routing layer)

The `description` is the only part of a skill that is always in context; the
body loads only when the skill is invoked `[doc]`
(https://code.claude.com/docs/en/skills). Claude uses the description to decide
when to apply the skill — so the description is the library's routing layer,
and a weak description makes a perfect skill body unreachable. The library-wide
consequences of bad routing are covered in `codofable-architecture-contract`.

Rules:

1. **Third person, always.** "Provides X. Use when Y." The description is
   injected into the system prompt; inconsistent point-of-view causes discovery
   problems `[doc]` (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
2. **State WHEN to load it, not just what it contains.** A contents summary
   answers "what is this?"; routing needs "am I in the situation this solves?".
3. **Include concrete trigger phrases** — the literal words a user or session
   would use ("add a skill", "flaky test", "false done"). Official
   troubleshooting for a skill that never triggers is precisely "check the
   description includes keywords users would naturally say" `[doc]`
   (https://code.claude.com/docs/en/skills).
4. **Front-load the key use case** — truncation at 1,536 chars in the listing
   keeps the beginning `[doc]` (same URL). Stay under 1024 chars total (hard
   validation limit).

Anti-patterns (each has caused real routing failures in skill libraries;
classification is `[craft]` except where cited):

| Anti-pattern | Example | Why it fails |
|---|---|---|
| Vague "helps with X" | `description: Helps with documents` | Matches everything and nothing; cited as the canonical bad example in official docs `[doc]` (best-practices URL above) |
| First person | `description: I can help you write skills` | Point-of-view mismatch in the system prompt degrades discovery `[doc]` (same URL) |
| Missing triggers | `description: The library's style guide and template` | Says what it IS; a session asking "how do I add a skill?" has no keyword to match |
| Restating the title | `description: Docs and writing skill` | Zero routing information beyond the name |
| Oversell | `description: Guarantees perfect skills every time` | Violates S5/N8; also matches requests it cannot serve |
| Contents dump with no situations | A 900-char list of section headings | Keywords without "use when..." still leaves the load decision to guesswork |

Test after writing: ask "if a fresh session saw ONLY this description among 15
siblings, would it load this skill at the right moment — and NOT load it at the
wrong one?" If two sibling descriptions could both match a request, sharpen
both (and check `## When NOT to use` names the other).

## Authoring runbook: add or edit a skill

Editing a skill's content is a **Class 2 change** — it alters the behavior of
every future session that loads it. The library rule (shared with
`codofable-architecture-contract`): a formatting- or typo-only edit that
changes no content, description, doctrine, or command is **Class 1**; any
content, description, doctrine, or command change is **Class 2**. Either way
it gets classified — per N9 there is no "too trivial to classify" (classes and
gates: `codofable-change-control`). Work the steps in order.

**Step 0 — Read before you write (per N7).** Read the current `SKILL.md` in
full before editing it. For a new skill, read the inventory in
`codofable-architecture-contract` to confirm the skill belongs there and its
name is on the inventory (names are final; adding a NEW name to the inventory
is itself a Class 2 change to `codofable-architecture-contract`).

**Step 1 — Inventory check: one home per fact (S7).** For each fact you plan
to write, check whether it already lives somewhere:

```sh
# run from the repo root:
grep -rli "<keyword>" .claude/skills/ --include=SKILL.md
```

(Run 2026-07-05 with keyword `evidence`; returned five sibling skills — the
evidence hierarchy's home is `codofable-validation-and-qa`, so any other skill
cites "E1/E2" instead of restating levels.) If the fact has a home:
cross-reference by skill name. If it has two homes: that is a defect — fix it
by picking the home the inventory assigns and reducing the other to a
cross-reference.

**Step 2 — Write against the template.** New skill: copy
`references/TEMPLATE.md` from this directory into
`.claude/skills/<skill-name>/SKILL.md`, fill placeholders, delete the guidance
comments. Edit: preserve the required section order; keep the Provenance
section last and update it (Step 5).

**Step 3 — Run the validator** (ships with
`codofable-diagnostics-and-tooling`; interpretation guide lives there):

```sh
# run from the repo root:
sh .claude/skills/codofable-diagnostics-and-tooling/scripts/validate_skills.sh
```

Expected: one `PASS`/`WARN`/`FAIL` row per skill and a summary line; exit 0
means no FAILs. (Run in-session 2026-07-05: prints the table; checks
frontmatter structure, name == directory, description non-empty and <=1024
chars, required headings, and the 450/500 line thresholds.) Fix every FAIL for
the skill you touched. A validator pass is structural verification only — it
is necessary, never sufficient (the analogue of E3 in
`codofable-validation-and-qa`); it cannot tell you your facts are true.

**Step 4 — Self-review against the three review lenses.** These are the same
lenses the library's review phase uses; to run them as parallel reviewer
agents instead of a self-check, see `codofable-orchestration`.

- [ ] **FACTUAL** — Re-verify every command, path, flag, and citation against
      the repo or the cited URL, on the final text (per N1: run it in this
      session, on the final state). Anything invented or stale?
- [ ] **DOCTRINE** — Does anything contradict the README manifest, the
      non-negotiables (home: `codofable-change-control`), or a sibling skill?
      Any claim missing a "candidate"/"open" label? Any path around
      change-control?
- [ ] **USABILITY** — Would the description route a fresh session correctly
      (test in previous section)? Any fact duplicated from its home? Does the
      skill stand alone for a zero-context reader? Is it scannable (S4)?

**Step 5 — Update Provenance and re-verify (maintenance protocol below).**
Re-run every one-liner in the skill's Provenance table, refresh the "as of"
dates you re-checked, and add rows for any new volatile fact.

**Step 6 — Close out through change-control.** State explicitly what you
verified and how (validator output + re-run one-liners + lens checklist). Do
NOT claim "done" beyond that evidence (per N1). Sharing the change outward —
commit and push — is Class 3: it requires explicit human authorization (per
N6), and no skill edit is exempt.

## Maintenance protocol

**Re-verification cadence.** There is no calendar cadence; the trigger is
touch. On ANY edit to a skill — even a typo fix — re-run every one-liner in
that skill's Provenance table before closing out. Rationale `[craft]`: a
library this young has no background maintenance process, so verification must
piggyback on contact, or facts rot indefinitely between edits. If a one-liner
fails or its output changed, the fact has drifted: fix the fact in the same
edit, or label it "open" (per N8) with a note of what you observed.

**Date-stamp discipline.** Every volatile fact carries "as of YYYY-MM-DD".
Refresh the date ONLY for facts you actually re-verified in this session —
never blanket-update dates, because a fresh date on an unchecked fact is a
forged verification (the documentation form of a false "done" claim). Facts
that are definitional rather than volatile (e.g. section order) need no date.

**Retiring a skill. Never silent-delete.** A deleted skill leaves dangling
cross-references in siblings and erases the record of why it existed —
exactly the settled-battle amnesia `codofable-failure-archaeology` exists to
prevent. Procedure:

1. Classify: retirement is Class 2 (Class 3 once pushed/shared).
2. Edit the skill's frontmatter description to begin: `DEPRECATED as of
   YYYY-MM-DD - do not load; see <replacement-or-reason>.` — the description
   is the routing layer, so deprecation must be visible there first.
3. Add a one-line banner under the H1 stating the replacement skill (exact
   inventory name) or the reason there is none.
4. Update every sibling that cross-references the retired skill
   (find them: `grep -rln "<skill-name>" .claude/skills/ --include='*.md'`).
5. Record the retirement in `codofable-failure-archaeology` as
   symptom → root cause → evidence → status (status: retired), so nobody
   re-authors it from the inventory without knowing why it died.
6. Only after a human explicitly authorizes removal (per N6) may the
   directory be deleted; until then the deprecated stub stays.

**Renaming a skill** is a retirement of the old name plus authoring of the new
one — both procedures apply, because inventory names are load-bearing
cross-reference targets.

## Provenance and maintenance

Evidence classes: `[repo]` = verifiable in this repository; `[doc]` =
verifiable at the cited URL; `[craft]` = professional judgment, so labeled.

| Fact in this skill | Class | As of | Re-verify with |
|---|---|---|---|
| README "AUTHORING RULES" section is the in-repo anchor of the house style (line 41) | [repo] | 2026-07-05 | from the repo root: `grep -n "AUTHORING RULES" README.md` |
| Frontmatter limits: name <=64 chars lowercase/numbers/hyphens, no reserved words; description non-empty <=1024 chars, no XML tags; third-person warning; <500-line body guidance; one-level-deep references | [doc] | 2026-07-05 | WebFetch https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices and check "YAML frontmatter requirements" + "Writing effective descriptions" |
| Description is the always-in-context routing layer; body loads on invoke; 1,536-char listing truncation; malformed-YAML behavior; keyword troubleshooting advice | [doc] | 2026-07-05 | WebFetch https://code.claude.com/docs/en/skills and check "Frontmatter reference" + "Troubleshooting" |
| Validator path, invocation, checks, and exit codes as described in Step 3 | [repo] | 2026-07-05 | from the repo root: `sh .claude/skills/codofable-diagnostics-and-tooling/scripts/validate_skills.sh; echo "exit=$?"` |
| Inventory-check grep example output (five siblings mention "evidence") | [repo] | 2026-07-05 | from the repo root: `grep -rlic "evidence" .claude/skills/ --include=SKILL.md` — expect the sibling list to have GROWN as the library fills in; the point (multiple non-home mentions must cite, not restate) stands |
| Touch-triggered re-verification cadence (no calendar cadence) | [craft] | 2026-07-05 | Falsified if the library gains an automated scheduled verification job; then move cadence to that job's definition |
| "Name == directory" requirement and the [repo]/[doc]/[craft] tagging scheme are library conventions with their home HERE and enforcement in the validator | [repo] | 2026-07-05 | from the repo root: `grep -n "name" .claude/skills/codofable-diagnostics-and-tooling/scripts/validate_skills.sh \| head -5` |

Maintenance: this skill is subject to its own protocol. Any content edit here
is Class 2 (formatting/typo-only: Class 1, per the rule in the authoring
runbook); re-run the table above on touch; retirement routes through the
procedure this skill defines, recorded in `codofable-failure-archaeology`.

Last full verification: 2026-07-05 (all `[repo]` commands run in-session; both
`[doc]` URLs fetched in-session).
