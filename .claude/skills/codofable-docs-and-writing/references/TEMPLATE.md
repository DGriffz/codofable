---
name: codofable-<topic>
description: <Third person. Sentence 1 — what the skill provides. Sentence 2 — exactly WHEN a session should load it, with concrete trigger phrases, e.g. "Use when the user asks to X, when you are about to Y, or when you see error Z." Hard limit 1024 characters; this library aims for under 1000. No first person, no XML tags.>
---

<!--
HOW TO USE THIS TEMPLATE
1. Copy this file to .claude/skills/<skill-name>/SKILL.md (path relative to
   the repo root)
   The frontmatter `name` MUST equal the directory name exactly (library rule,
   enforced by validate_skills.sh; official docs treat `name` as a display label
   that defaults to the directory name).
2. Replace every <placeholder>. Delete every HTML comment like this one.
3. Keep required sections in this exact order. Add your body sections between
   "When NOT to use" and "Provenance and maintenance".
4. Target 150-450 lines. Overflow goes to references/*.md in YOUR directory,
   linked one level deep from SKILL.md.
5. Before claiming done: run the library validator and re-run every Provenance
   one-liner (see codofable-docs-and-writing, "Authoring runbook").
-->

# <Skill Title in Plain English>

<One paragraph: what this skill lets a zero-context engineer or Sonnet-class
session do, and what standard it holds them to. No motivational filler. Define
any jargon term the paragraph itself uses.>

## When to use this skill

<Concrete triggering situations, as a bullet list. Write situations, not
topics: "You are about to X", "The user asked for Y", "You observed error Z".>

- <situation 1>
- <situation 2>
- <situation 3>

## When NOT to use this skill

<Every skill names at least one sibling. Use exact inventory names from the
library (see codofable-architecture-contract for the inventory).>

| If you need... | Use instead |
|---|---|
| <adjacent need 1> | `<sibling-skill-name>` |
| <adjacent need 2> | `<sibling-skill-name>` |

## <Body section 1 — your charter defines these>

<Rules of thumb for body sections:
- Imperative runbook voice: "Run X. If you see Y, do Z."
- Every command copy-pasteable. If runnable in this repo, RUN it first and show
  real output. If it is an ecosystem-generic pattern (e.g. `cargo test`), mark
  it: "(generic pattern, not verified in this repo)".
- Tables and checklists over prose.
- Cite doctrine, do not restate it: non-negotiables as "per N2" (home:
  codofable-change-control), evidence levels as "E1/E2" (home:
  codofable-validation-and-qa). One home per fact.
- Label unproven ideas "candidate" or "open" (per N8). Never oversell.>

## <Body section 2>

<...>

## Provenance and maintenance

<This section is LAST. It makes the skill re-verifiable after you are gone.>

Evidence classes used below (library convention):

- `[repo]` — verifiable in this repository's files or git history.
- `[doc]` — verifiable against a cited external document (give the URL).
- `[craft]` — professional judgment / first-principles reasoning, labeled as
  such; carries no external proof.

Volatile facts and how to re-verify them:

| Fact in this skill | Class | As of | Re-verify with |
|---|---|---|---|
| <fact that may drift 1> | [repo] | <YYYY-MM-DD> | `<one-line command>` |
| <fact that may drift 2> | [doc] | <YYYY-MM-DD> | `WebFetch <URL> and check <what>` |
| <judgment call presented as guidance> | [craft] | <YYYY-MM-DD> | <what observation would falsify it> |

Maintenance protocol (per `codofable-docs-and-writing`):

- On ANY edit to this skill, re-run every command in the table above and
  refresh the "As of" dates you re-checked.
- Editing this skill is a Class 2 change (it alters future sessions'
  behavior) — route through `codofable-change-control`.
- Do not silently delete this skill. To retire it, follow the retirement
  procedure in `codofable-docs-and-writing` and record the retirement in
  `codofable-failure-archaeology`.

Last full verification of this skill: <YYYY-MM-DD>, by <session/author id>.
