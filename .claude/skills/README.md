# The codofable skill library

Authored 2026-07-05 by the retiring distinguished fellow (Fable 5) so that junior/mid-level
engineers and Sonnet-class model sessions can carry this project's standard forward.
Built per the manifest in the repository README: 16 parallel authoring agents working from
one canonical brief, then three specialized reviewers (factual / doctrine / usability) and
one fixer. Every runnable command was executed before being written down; evidence classes
are labeled [repo] / [doc] / [craft] throughout.

Start here:

- New to the library or to agentic sessions → `agentic-engineering-reference`
- About to change anything → `codofable-change-control`
- About to say "done" → `codofable-verified-done-campaign`

## Inventory

| Skill | One line |
|---|---|
| `codofable-change-control` | Doctrinal root: the ten non-negotiables (N1–N10) and change classes R/1/2/3 with gates, rationale, and escalation rules. |
| `codofable-debugging-playbook` | The debugging loop for any codebase: reproduce → shrink → discriminating experiments → proven mechanism; triage tables and fixation traps. |
| `codofable-failure-archaeology` | Settled decisions and the catalog of agentic failure modes (symptom → root cause → evidence → status), so no battle is re-fought. |
| `codofable-architecture-contract` | The library's own load-bearing design decisions, invariants, and openly stated weak points. |
| `agentic-engineering-reference` | Domain theory: skill/loading mechanics, context and compaction, subagents, permissions — doc-verified, every term defined. |
| `codofable-repo-onboarding` | Arrive in an unknown repo: recon sequence, CI-as-ground-truth, history mining, bootstrap traps, "you are oriented when" checklist. |
| `codofable-config-mapping` | Map any repo's seven configuration axes with tested search patterns; prod-vs-experimental heuristics; safe flag-add checklist. |
| `codofable-diagnostics-and-tooling` | Measure, don't eyeball — ships `validate_skills.sh` (library invariant checker) and `repo_recon.sh` (ecosystem detector), both tested. |
| `codofable-validation-and-qa` | The evidence hierarchy E1–E4, acceptance-threshold discipline, the golden inventory, adding tests, flaky-test rules. |
| `codofable-docs-and-writing` | House style, the SKILL.md template, description-writing guide, and the library's maintenance/retirement protocol. |
| `codofable-orchestration` | Multi-agent craft: spawn decisions, shared-brief pattern, write-scope isolation, the author→reviewer→fixer pyramid. |
| `codofable-external-positioning` | Novelty ledger (KNOWN / CANDIDATE / UNPROVEN), claim-discipline table, and reproducibility standards for public claims. |
| `codofable-verified-done-campaign` | Flagship: the decision-gated protocol that makes a false "done" claim structurally impossible. |
| `codofable-proof-and-analysis-toolkit` | Proof recipes with real transcripts: revert test, automated bisect, flakiness statistics, benchmark discipline, ddmin, differential debugging. |
| `codofable-research-frontier` | Open problems P1–P5 toward measurable model uplift, each with concrete first steps and a falsifiable milestone. Zero achieved results. |
| `codofable-research-methodology` | Hunch → pre-registered hypothesis → adversarial refutation → adopted or retired: the scientific method as procedure. |

## Health check

From the repo root:

```sh
sh .claude/skills/codofable-diagnostics-and-tooling/scripts/validate_skills.sh
```

Expected: `16 skill(s) checked — 16 PASS, 0 WARN, 0 FAIL`. Editing any skill? Load
`codofable-docs-and-writing` first; edits are classified per `codofable-change-control`.
