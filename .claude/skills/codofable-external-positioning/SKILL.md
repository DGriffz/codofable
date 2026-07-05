---
name: codofable-external-positioning
description: Load before making ANY externally visible claim about the codofable project — writing a README section for outsiders, a release note, a blog post, a paper, a talk, a repo description, a social post, or answering "is this novel?", "has anyone done this before?", "can we say it works?". Provides the verified ecosystem map (Claude Code skills, anthropics/skills, AGENTS.md, CLAUDE.md memory, cookbooks, distillation), an honest novelty ledger (KNOWN vs CANDIDATE-NOVEL vs UNPROVEN), a claim-discipline table stating what evidence must exist before each public claim, and the reproducibility standard for any performance claim. Trigger phrases: "announce", "publish", "position", "compare to prior art", "state of the art", "novel", "we improved model performance", "write the pitch". This skill guards against oversell (N8) at the project boundary.
---

# Codofable external positioning

This skill defines where the codofable project sits in the AI-agent ecosystem, what may and may not be claimed about it publicly, and the evidence bar each claim must clear first. The core discipline: every public statement is either backed by an artifact you can point to, or it is labeled "candidate"/"open" (per N8, defined in `codofable-change-control`). Publishing anything external is a Class 3 action (outward-facing) and requires explicit human authorization per N6 — this skill governs the *content* of such statements; `codofable-change-control` governs the *gate*.

Jargon, defined once:
- **Skill**: a directory containing a `SKILL.md` file (YAML frontmatter + markdown instructions) that an agent loads on demand. See `agentic-engineering-reference` for mechanics.
- **Uplift**: a measured improvement in task performance of a model session *with* this library versus an identical session *without* it.
- **Prior art**: any published work that already does what you are about to claim is new.
- **Pre-registration**: writing down metrics, success thresholds, and analysis plan *before* running an experiment, so results cannot be cherry-picked afterward.

## When to use this skill

- You are drafting anything an outsider will read: README positioning text, release notes, a paper, a blog post, a talk abstract, a repo tagline, a comment on someone else's forum thread.
- Someone asks "is this novel?", "hasn't X already done this?", or "what makes this different from prompt libraries / distillation / AGENTS.md?"
- You are about to write a sentence containing "improves", "outperforms", "first", "novel", "state of the art", "proven", or "verified" in an externally visible place.
- You need to compare codofable to a specific ecosystem artifact (Anthropic's skills repo, AGENTS.md, a benchmark paper) and want the verified facts and URLs.
- You are updating the novelty ledger after new prior art surfaces.

## When NOT to use this skill

| If you are... | Use instead |
|---|---|
| Designing or running the actual uplift experiment (harness, task set, metrics) | `codofable-research-frontier` |
| Deciding what counts as evidence for *internal* "done"/"fixed" claims | `codofable-validation-and-qa` |
| Formulating hypotheses, pre-registration mechanics, adversarial refutation | `codofable-research-methodology` |
| Classifying/gating the act of publishing itself (Class 3) | `codofable-change-control` |
| Writing or editing the skills themselves (style, template) | `codofable-docs-and-writing` |

## 1. The ecosystem map (verified 2026-07-05)

Each entry: what it is, the URL it was verified against, and what codofable takes from it or does differently. Evidence class [doc] unless noted. URLs marked ⚠ could not be fetched from the authoring sandbox (proxy 403) — the fact is sourced as stated and must be re-verified before public citation.

### 1.1 Claude Code Agent Skills (the substrate)

- **What**: Skills extend what Claude can do: "Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly." A skill's body loads only when used ("progressive disclosure"); only its `description` sits in context, and the combined `description` + `when_to_use` listing text is truncated at 1,536 characters. Claude Code skills follow the Agent Skills open standard (agentskills.io ⚠ — cited by the official docs; the site itself was unreachable from the sandbox).
- **URL**: https://code.claude.com/docs/en/skills [doc, fetched 2026-07-05]
- **Relation**: codofable is built *on* this mechanism, unmodified. Nothing about the delivery format is ours or novel. What codofable adds is the *content discipline*: doctrine (N1–N10), evidence classes, and cross-skill canon (one home per fact).
- **Critical adjacent fact**: the official docs already describe an evaluation loop for skills — the `skill-creator` plugin's benchmark mode "aggregates pass rate, time, and tokens for with-skill versus without-skill into `benchmark.json`" and runs "a blind A/B between two versions of the skill." [doc, same URL] **Consequence: "measuring whether a skill helps" is ecosystem-standard tooling, not a codofable invention. Never claim otherwise.**

### 1.2 anthropics/skills (the official skill library)

- **What**: Anthropic's public repository of Agent Skills — "Folders of instructions, scripts, and resources that Claude loads dynamically to improve performance on specialized tasks." Contains a skills catalog (docx, pdf, pptx, xlsx, and category-organized examples), the Agent Skills specification under `spec/`, and a skill template. ~158k stars as of 2026-07-05.
- **URL**: https://github.com/anthropics/skills [doc, fetched 2026-07-05]
- **Relation**: proof that curated skill libraries exist at scale, from the vendor itself. Anthropic's skills are predominantly *task-capability* skills (produce a .docx, edit a PDF). Codofable's skills are *process-discipline* skills (how to verify, classify, debug, claim). That difference in content type is real; the library *form* is fully KNOWN.

### 1.3 CLAUDE.md memory and .claude/rules (persistent-context conventions)

- **What**: Claude Code loads `CLAUDE.md` files (managed/user/project/local scopes) into every session as persistent instructions; `.claude/rules/` adds topic files, optionally path-scoped; "auto memory" lets the model accumulate its own notes. Docs explicitly route procedures away from CLAUDE.md: "If an entry is a multi-step procedure... move it to a skill."
- **URL**: https://code.claude.com/docs/en/memory [doc, fetched 2026-07-05]
- **Relation**: codofable deliberately chose skills over CLAUDE.md for its content because the doctrine is procedural and long; always-loaded memory would burn context and reduce adherence (docs recommend <200 lines per CLAUDE.md). The idea of "written-down persistent guidance for an agent" is KNOWN and vendor-documented.

### 1.4 AGENTS.md (the cross-tool convention)

- **What**: "A simple, open format for guiding coding agents" — a README-for-agents holding project context, environment tips, test instructions, PR guidelines. ~22.8k stars on the spec repo as of 2026-07-05. Claude Code reads CLAUDE.md, not AGENTS.md, but the official docs show how to import one into the other.
- **URLs**: https://github.com/agentsmd/agents.md (reached via redirect from github.com/openai/agents.md) [doc, fetched 2026-07-05]; https://agents.md ⚠ (403 from sandbox); Claude Code interop documented at https://code.claude.com/docs/en/memory [doc].
- **Relation**: AGENTS.md is per-repo orientation. Codofable is repo-agnostic craft: the library teaches discipline usable on *any* repository (owner's Phase-1 scope decision [repo]). "Instructions files for agents" as a category is KNOWN.

### 1.5 Prompt-library and cookbook traditions

- **What**: curated collections of reusable prompts and worked recipes. Anthropic's live exemplar is claude-cookbooks — "A collection of notebooks/recipes showcasing some fun and effective ways of using Claude" (formerly `anthropic-cookbook`; ~46k stars as of 2026-07-05). Note: Anthropic's old Prompt Library URL (`docs.claude.com/en/resources/prompt-library/library`) now redirects into platform.claude.com and served the "Prompting best practices" guide when fetched 2026-07-05 — treat the standalone Prompt Library as absorbed into the docs.
- **URLs**: https://github.com/anthropics/claude-cookbooks [doc, fetched 2026-07-05]; https://platform.claude.com/docs/en/resources/prompt-library/library [doc, fetched 2026-07-05 — serves prompting guidance, not a prompt library page].
- **Relation**: cookbooks are human-authored, human-audience recipes for *using* models. Codofable inverts authorship (a frontier model writes it) and audience (cheaper model sessions consume it). The recipe/runbook *tradition* is KNOWN — decades old in SRE culture, years old in prompt engineering.

### 1.6 Model distillation (what this project is NOT)

- **What**: knowledge distillation is a *training* technique — a large teacher model's outputs (often soft labels/probabilities) supervise the training of a smaller student model, changing the student's weights to approximate the teacher at lower cost. [doc — definition confirmed via WebSearch 2026-07-05 across standard ML sources; canonical reference is Hinton et al. 2015, "Distilling the Knowledge in a Neural Network", arXiv:1503.02531 ⚠ arxiv unreachable from sandbox]
- **Relation — the load-bearing distinction**: codofable transfers knowledge via **loadable procedure, not weight training**. No gradient touches any model. The "student" (a Sonnet-class session) is unchanged as an artifact; it reads documents at inference time. Consequences you must preserve in any public description:
  1. Transfer is inspectable and editable (it's markdown), unlike distilled weights.
  2. Transfer is revocable (unload the skill) and per-session.
  3. The correct analogy is *succession documentation* (a retiring expert writes runbooks), not distillation. If you use the word "distillation" publicly, you MUST immediately disambiguate, or drop the word.

### 1.7 Adjacent prior art on measured skill uplift (found 2026-07-05 — read before any novelty claim)

A prior-art search on 2026-07-05 (queries and results logged in [references/prior-art-log-2026-07-05.md](references/prior-art-log-2026-07-05.md)) surfaced work directly adjacent to this project's frontier goal:

| Work | What the search results state | Verification status |
|---|---|---|
| SkillsBench (arXiv 2602.12670) | Benchmarks how well Agent Skills improve task performance across harnesses/models; curated skills reported +16.2pp average, up to +23.3pp for Claude Code + Opus 4.5 | ⚠ Search-result summary only; arxiv 403 from sandbox. MUST fetch and read before citing publicly. |
| SKILL-DISCO (arXiv 2606.26669) | Skills induced by a frontier model (GPT-4o) transferred to other models incl. small open-source ones, with largest gains on the smallest models | ⚠ Same. This is the closest known prior art to codofable's uplift thesis. |
| Letta Context-Bench skills post | Measured whether various models can use skills | ⚠ Search hit only (letta.com 403 from sandbox). |
| skill-creator benchmark mode | With-skill vs without-skill pass-rate/token/time comparison, blind A/B between skill versions | Verified [doc] at https://code.claude.com/docs/en/skills. |

**Consequence**: "skills can lift smaller models, measurably" appears to be already demonstrated in the literature. Codofable's novelty surface is therefore NARROWER than the project's founding framing — see the ledger below. This is exactly why the search is recorded: honest positioning shrank the claim.

## 2. The novelty ledger

Rules: (a) you cannot prove a negative about prior art — "candidate-novel" means "no prior art found in the recorded search as of the stamp date", never "nothing exists"; (b) any new prior-art finding moves entries down the ledger, never up, without a new recorded search; (c) per N8, anything not in KNOWN is labeled when mentioned publicly.

### KNOWN (do not claim as new, ever)

- Skill libraries for agents exist, including vendor-official ones (anthropics/skills). [doc]
- Runbook/playbook culture exists (SRE tradition; cookbooks; prompt libraries). [doc/craft]
- Checklists and instruction files for AI agents exist (CLAUDE.md, AGENTS.md, rules files). [doc]
- Measuring with-skill vs without-skill performance is ecosystem-standard tooling (skill-creator benchmark) and an active research area (SkillsBench, SKILL-DISCO — pending full-text verification). [doc/⚠]
- Frontier-model-authored skills transferring benefit to smaller models has at least one apparent published demonstration (SKILL-DISCO). [⚠ — treat as KNOWN for claim-safety purposes until the paper is read and found materially different]

### CANDIDATE-NOVEL as of 2026-07-05 (label "candidate" in every public use)

The composite, not any ingredient: **a doctrine-first engineering-craft transfer library — process discipline (verification gates, change classes, evidence hierarchy) rather than task capabilities — authored end-to-end by a retiring frontier model explicitly as succession for cheaper models and junior engineers, with falsifiable uplift criteria declared before any measurement.** [craft — judgment call on the recorded search of 2026-07-05; no exact match found; a negative cannot be proven]

Sub-claims that remain candidate individually:
- The "retiring distinguished fellow" succession framing as an authoring methodology. [craft]
- Doctrine-canon architecture (numbered non-negotiables, one-home-per-fact, cross-referenced canon) as a skill-library design pattern. [craft]

### UNPROVEN (zero measurements exist — never state as fact, publicly or internally)

- **Any uplift at all.** As of 2026-07-05, no experiment has run. There is no evidence this library improves any model's performance on anything. The experiment that would change this line is specified in `codofable-research-frontier`; its methodology bar lives in `codofable-research-methodology`. Until that experiment produces results, the only honest public formulation is: "designed to lift cheaper-model performance; uplift is an open, falsifiable hypothesis — not yet measured." [repo — absence of any experiment artifacts in this repository]
- That doctrine-first skills outperform task-capability skills, or that model-authored skills outperform human-authored ones. [craft — open questions]

## 3. Claim discipline table

Before making a claim publicly, the listed artifact must EXIST and be citable. If the artifact does not exist, either build it first or degrade the claim to the "Until then, say" column. Any claim not in this table defaults to N8: label it "candidate" or "open", or do not make it. Publishing at all requires Class 3 authorization (N6).

| Public claim | Required artifact(s) before claiming | Until then, say |
|---|---|---|
| "This library improves Sonnet-class performance" | The frontier A/B experiment (see `codofable-research-frontier`) completed with pre-registered metrics (see `codofable-research-methodology`), published per Section 4 | "designed to; uplift not yet measured — open hypothesis" |
| "Skills are verified / ground-truth" | Library validator (see `codofable-diagnostics-and-tooling`) passing on the current tree + the Phase-3 review records | "authored under a verification doctrine; review records in repo" |
| "Novel approach" | The recorded prior-art search (Section 1.7 + references log), re-run within ~90 days of the claim, with the adjacent work cited and distinguished | "candidate-novel as of <date>; closest prior art: SKILL-DISCO, SkillsBench" |
| "Written by a frontier model (Fable 5)" | This repo's git history and README manifest | (claimable now — [repo]) |
| "N skills covering X" | `ls .claude/skills/` output at the cited commit | (claimable with commit hash) |
| "Outperforms <specific alternative>" | Head-to-head experiment against that alternative, same standard as row 1 | Do not say. No weaker form permitted. |
| "First to do <anything>" | Cannot be satisfied — you cannot prove a negative | Never say "first". Say "we found no prior art for <X> as of <date> (search log: <link>)" |
| Citing SkillsBench / SKILL-DISCO / Letta numbers | Full text fetched and read; numbers quoted from the paper, not from search summaries | Cite as "reported in <ref> (not independently verified)" or omit |

## 4. Reproducibility standard for public performance claims

Any public claim of measured uplift must ship enough artifact that a stranger can re-run it and get the same verdict. Checklist — ALL items required (this operationalizes E1/E2 evidence — hierarchy defined in `codofable-validation-and-qa` — at the project boundary):

- [ ] **Exact model identities**: full model ID strings and versions/snapshots for every model in the comparison (e.g. the precise `claude-*` API identifier, not "Sonnet"), plus harness name and version (e.g. Claude Code CLI version), plus date of runs.
- [ ] **Full task set published**: every task, its inputs, and its repo state (commit hashes) — not a sample, not "representative examples".
- [ ] **Prompts and harness published**: the exact session prompts, settings, skill-loading configuration for both arms (with-library vs without), and the driver scripts.
- [ ] **Success criteria pre-registered**: metrics, thresholds, and analysis plan committed (with timestamp) *before* the first measured run — mechanics per `codofable-research-methodology`. A post-hoc metric is a finding, never a claim.
- [ ] **Raw outputs retained**: complete transcripts/logs of every run, both arms, including failures — retained and linked, not summarized.
- [ ] **Independent re-run possible from published artifacts alone**: a third party with API access needs nothing that isn't in the release — no private paths, no "ask us for the harness". Dry-run test: could a stranger reproduce the headline number using only the published bundle? If no, the claim does not ship.
- [ ] **Variance addressed**: multiple runs per task-arm cell (models are stochastic); report the distribution, not the best run. Statistical recipes: `codofable-proof-and-analysis-toolkit`.

## 5. Maintaining the ledger and re-running the prior-art search

The ledger decays. Before ANY public novelty claim, re-run the search and append to the log:

1. Search (WebSearch or equivalent) at minimum: `"agent skills" benchmark uplift smaller models`, `skill library authored by frontier model transfer`, `doctrine process-discipline skills coding agents`, plus terms matching your specific claim.
2. Fetch and READ the top adjacent hits (do not cite from search snippets — see Section 3 last row).
3. Append findings to `references/prior-art-log-<date>.md` in this skill's directory: query, date, hits, verdict per hit (distinct / adjacent / prior art).
4. Move ledger entries DOWN if matched. Update the "as of" stamps. If an entry moves out of CANDIDATE-NOVEL, sweep other skills for stale claims of it (grep the library for the phrase).
5. Any resulting change to public-facing text is Class 3 (route through `codofable-change-control`).

## Provenance and maintenance

Authored 2026-07-05. Volatile facts and their evidence classes:

- [doc, fetched 2026-07-05] Claude Code skills mechanics and skill-creator benchmark mode: https://code.claude.com/docs/en/skills — re-verify: `curl -s https://code.claude.com/docs/en/skills | grep -io "benchmark"` (or WebFetch the URL).
- [doc, fetched 2026-07-05] CLAUDE.md/rules/auto-memory and AGENTS.md interop: https://code.claude.com/docs/en/memory.
- [doc, fetched 2026-07-05] anthropics/skills exists, structure and star count: https://github.com/anthropics/skills — star counts drift; re-check before quoting.
- [doc, fetched 2026-07-05] AGENTS.md spec repo: https://github.com/agentsmd/agents.md (github.com/openai/agents.md redirects there); the agents.md website itself returned 403 from the authoring sandbox and was NOT directly verified.
- [doc, fetched 2026-07-05] claude-cookbooks (ex anthropic-cookbook): https://github.com/anthropics/claude-cookbooks. Old Prompt Library URL now serves prompting-best-practices content — re-verify before describing the Prompt Library as a live standalone product.
- [⚠ unverified, search-only, 2026-07-05] SkillsBench (arXiv 2602.12670), SKILL-DISCO (arXiv 2606.26669), Letta Context-Bench post — arxiv.org and letta.com were unreachable (proxy 403) from the authoring sandbox. Summaries in Section 1.7 come from WebSearch result text. BLOCKING for public citation: fetch and read full texts first. Full search log: [references/prior-art-log-2026-07-05.md](references/prior-art-log-2026-07-05.md).
- [craft] The novelty judgments in Section 2 and the distillation-vs-procedure distinction's consequences (1.6) are the fellow's reasoning on the verified facts.
- [repo] "Zero uplift measurements exist" — re-verify from the repo root: `ls . && grep -ri "experiment\|benchmark\|results" . --include="*.json" -l` (expect no experiment artifacts; update Section 2 UNPROVEN if any appear).
- Re-verification one-liners (from the repo root): `git log --oneline c321e16` (project origin commits — expect exactly `c321e16`, `c30ac04`; later commits are library authoring); `ls .claude/skills/` (current skill inventory before quoting a count).
