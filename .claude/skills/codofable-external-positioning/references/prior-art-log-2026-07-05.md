# Prior-art search log — 2026-07-05

Purpose: the recorded search behind the novelty ledger in `../SKILL.md` (Section 2). Per the ledger rules, "candidate-novel" means only "no exact match found in THIS recorded search" — a negative cannot be proven. Append new dated logs as new files (`prior-art-log-<date>.md`); never edit a past log's findings, only add.

Method note: searches ran via WebSearch from the authoring sandbox. Several primary sources (arxiv.org, letta.com, claude.com/blog, agentskills.io) returned HTTP 403 through the sandbox's egress proxy, so those entries carry search-snippet evidence only and are marked UNVERIFIED. Rule inherited from SKILL.md Section 3: unverified entries may not be cited publicly with numbers until the full text is read.

## Queries run (2026-07-05)

1. `skill library authored by frontier model to improve smaller model performance "skills" agent uplift measured A/B`
2. `"Claude Code" skills library measure whether skills improve model performance benchmark`

## Hits and verdicts

| Hit | URL | What the search result stated | Verified? | Verdict |
|---|---|---|---|---|
| SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks | https://arxiv.org/html/2602.12670v1 | Benchmarks skills across harnesses/models; curated skills reported +16.2pp average; Claude Code + Opus 4.5 reported +23.3pp | NO (403) | ADJACENT — measures skill uplift generally; does not appear to be a doctrine/craft library or succession authoring. Read before citing. |
| SKILL-DISCO: Distilling and Compiling Agent Traces into Reusable Procedural Skills | https://arxiv.org/pdf/2606.26669 | Skills induced by GPT-4o transferred to other models; success-rate gains reported up to +80.8% (ALFWorld) / +85.3% (WebArena), largest on smallest models | NO (403) | CLOSEST PRIOR ART for the uplift thesis (frontier-authored skills lifting smaller models). Differences to confirm on read: trace-induced task skills vs deliberately authored process doctrine; agent benchmarks vs real-repo engineering. Until read, treat "frontier-authored skills lift smaller models" as KNOWN. |
| Can Any Model Use Skills? Adding Skills to Context-Bench (Letta) | https://www.letta.com/blog/context-bench-skills/ | Measured skill usability across models | NO (403) | ADJACENT — measurement prior art. |
| A Framework for Evaluating Agentic Skills at Scale | https://arxiv.org/pdf/2606.17819 | Relevant skill access reported +5.5 to +22 point gains across models | NO (403) | ADJACENT — measurement prior art. |
| Claude Code skills docs — skill-creator benchmark mode | https://code.claude.com/docs/en/skills | With-skill vs without-skill pass rate/time/tokens into benchmark.json; blind A/B between skill versions | YES (fetched 2026-07-05) | ADJACENT, VERIFIED — per-skill uplift measurement is vendor-standard tooling. |
| Improving skill-creator (Anthropic blog) | https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills | Announcement behind benchmark/comparison modes | NO (403); indirectly confirmed by the docs page that links it | ADJACENT. |
| Misc. tooling/blog hits (mcpmarket, claudedirectory, mindstudio, nathanonn) | (various) | Skill benchmarking how-tos and marketplaces | NO | ADJACENT, low-weight — confirms measurement culture exists. |

## Not found in this search (basis for CANDIDATE-NOVEL)

No hit matched the composite: a process-discipline/doctrine skill library (verification gates, change classes, evidence hierarchy — not task capabilities), authored end-to-end by a retiring frontier model as explicit succession for cheaper models AND human juniors, with falsifiable uplift criteria pre-registered before any measurement. Two queries is a shallow search; re-run with more terms (SKILL.md Section 5) before any public novelty claim.
