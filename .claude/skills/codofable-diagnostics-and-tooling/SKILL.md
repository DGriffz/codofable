---
name: codofable-diagnostics-and-tooling
description: Measure instead of eyeball — the codofable library's executable tooling and measurement discipline. Load this skill when you are about to claim anything quantitative or comparative ("faster", "smaller", "all skills valid", "the repo builds this way") without a number; when you need to check the skill library's structural invariants (run scripts/validate_skills.sh); when you land in an unknown repository and need its manifests, lockfiles, CI config, and likely install/build/test commands (run scripts/repo_recon.sh); when you need standard measurement one-liners (timing, line counts, diff size, test-count deltas); or when you want to add a new script to the library's tooling. Trigger phrases - "seems faster", "looks fine", "validate the skills", "check the library", "what kind of repo is this", "how do I build/test this repo", "measure", "benchmark", "add a diagnostic script".
---

# codofable-diagnostics-and-tooling

This skill ships the codofable library's executable diagnostic tooling and the discipline for using it: never characterize code, performance, or library health by eye when a command can produce a number. It contains two tested scripts — `scripts/validate_skills.sh` (mechanical invariant checker for `.claude/skills/`) and `scripts/repo_recon.sh` (fast reconnaissance of any repository) — with interpretation guides, plus a table of universal measurement commands and the protocol for extending the toolset.

## When to use this skill

- You are about to write "seems fine", "looks faster", "should be smaller", "probably passes" — stop and pick the measuring command first (see the doctrine section).
- You changed, added, or reviewed anything under `.claude/skills/` and need to check the library's mechanical invariants → run `validate_skills.sh`.
- You have been dropped into an unfamiliar repository and need to know what ecosystem it is, which installer its lockfile expects, and what the candidate build/test commands are → run `repo_recon.sh` (then continue with `codofable-repo-onboarding` for the full orientation runbook).
- You need a copy-pasteable measurement one-liner: wall-clock timing, line/file counts, diff size, test-count delta.
- You want to add a new script to this skill's `scripts/` directory (see the extension protocol section).

## When NOT to use this skill

| If you need... | Use instead |
|---|---|
| The evidence hierarchy (E1–E4), what counts as proof of "done", acceptance thresholds | `codofable-validation-and-qa` |
| Statistics on your measurements: flakiness math, sample sizes, significance, performance-comparison methodology | `codofable-proof-and-analysis-toolkit` |
| The full orientation/bootstrap runbook for an unknown repo (recon is only step one) | `codofable-repo-onboarding` |
| The invariant list itself — WHY each library rule exists, and invariants that are not mechanically checkable | `codofable-architecture-contract` |
| Debugging a failure (hypothesis discipline, discriminating experiments) | `codofable-debugging-playbook` |
| Gating rules before you change any script here | `codofable-change-control` |

## The doctrine: measure, don't eyeball

Rule [craft]: **every comparative or state claim must name its metric and the command that produced it.** "Faster", "smaller", "cleaner", "fixed", "all passing" are banned as bare adjectives — each one is either backed by a pasted command-plus-output, or rewritten as a labeled guess ("candidate: likely faster; unmeasured", per N8).

This is the quantitative half of the evidence rules: a claim backed only by reading the code is E4 (reasoning); a claim backed by a command you ran in-session on the final state is E1/E2 (see `codofable-validation-and-qa` for the full hierarchy, and N1 in `codofable-change-control`). Eyeballing is how the project's named hardest failure mode — the false "done" claim — gets written.

Before/after discipline [craft]: for any claim of improvement, capture the metric **before** the change, make the change, capture it **after** with the identical command, and paste both. A lone "after" number is not evidence of improvement; there is nothing to compare it to.

| You are about to say... | Instead run... | And report... |
|---|---|---|
| "the skill library is valid" | `scripts/validate_skills.sh` | the PASS/FAIL table + exit code |
| "this script is faster now" | timing pattern from the table below, before AND after | both timings, same input |
| "the change is small" | `git diff --stat` | files changed, insertions, deletions |
| "tests still pass" / "no tests broke" | the suite in-session; count pass/fail before and after | the two counts and the delta |
| "the file isn't too long" | `wc -l FILE` | the number vs the limit |

## Script 1: `scripts/validate_skills.sh` — library invariant checker

Checks every directory under a skills root against the library's mechanically checkable invariants (the invariant list and its rationale live in `codofable-architecture-contract`; this script enforces the subset a program can decide).

### Usage

```sh
# From the repo root (default root is .claude/skills):
.claude/skills/codofable-diagnostics-and-tooling/scripts/validate_skills.sh

# Or point it at any skills root:
.claude/skills/codofable-diagnostics-and-tooling/scripts/validate_skills.sh path/to/skills
```

Exit codes: `0` = no failures (WARNs allowed) · `1` = at least one skill FAILs · `2` = usage error (root missing or contains no skill directories).

### What it checks, per skill directory

| # | Check | On violation |
|---|---|---|
| 1 | `SKILL.md` exists | FAIL |
| 2 | Line 1 is exactly `---` and a closing `---` follows (YAML frontmatter) | FAIL |
| 3 | Frontmatter has `name:` and `description:` keys | FAIL |
| 4 | `name:` value equals the directory name exactly | FAIL |
| 5 | `description:` is non-empty and ≤ 1024 characters | FAIL |
| 6 | Headings present (case-insensitive prefix match): `## When to use`, `## When NOT to use`, `## Provenance` | FAIL |
| 7 | Length: > 450 lines | WARN (soft limit) |
| 8 | Length: > 500 lines | FAIL |

### Expected output (run in-session 2026-07-05 against a synthetic fixture set — real, unedited)

```text
SKILL                                         STATUS DETAIL
-----                                         ------ ------
bad-name                                      FAIL   name 'wrong-name' != dir 'bad-name'; description empty; missing '## When to use' heading; missing '## When NOT to use' heading; missing '## Provenance' heading
good-skill                                    PASS   ok
long-skill                                    WARN   470 lines > 450 (soft limit)
no-skillmd                                    FAIL   SKILL.md missing

Summary: 4 skill(s) checked — 1 PASS, 1 WARN, 2 FAIL (root: skills-mixed)
```
Exit code for that run: `1` (captured in-session).

A healthy library run looks like `N skill(s) checked — N PASS, 0 WARN, 0 FAIL` with exit code `0` (verified in-session on a passing fixture set, 2026-07-05).

### What to do about each finding

| DETAIL says | Meaning | Fix |
|---|---|---|
| `SKILL.md missing` | Directory exists but has no skill file (or the skill is still being authored) | Author it, or delete the empty directory — through `codofable-change-control` |
| `file must open with --- on line 1` | Anything before the frontmatter (BOM, blank line, comment) breaks skill loading | Make `---` byte-one of the file |
| `frontmatter has no closing ---` | YAML block never terminated; body is being parsed as frontmatter | Add the closing `---` line after the last key |
| `frontmatter missing name:` / `missing description:` | Required key absent | Add it; description must state WHEN to load the skill |
| `name 'X' != dir 'Y'` | Loader identity mismatch | Make `name:` equal the directory name exactly |
| `description empty` / `description N chars > 1024` | Trigger text unusable or over budget | Write/trim it; keep every trigger phrase, cut filler |
| `missing '## ...' heading` | A required section is absent | Add the section; the required set is in `codofable-docs-and-writing` |
| `N lines > 450 (soft limit)` | WARN only — approaching the cap | Move detail into `references/*.md` inside the skill's directory |
| `N lines > 500` | Over the hard cap | Split content out to `references/` until under 450 |

Note: while the library is under construction, sibling skills being authored concurrently will show as `SKILL.md missing` — that is a true report of the current filesystem state, not a script bug. Re-run after authoring completes; the whole-library gate is exit code `0`.

## Script 2: `scripts/repo_recon.sh` — repository reconnaissance

Points at any repository and prints, read-only, what a person would otherwise eyeball from a directory listing: manifests, lockfiles, version pins, CI config, agent config, and candidate install/build/test commands. It scans only the top two directory levels and prunes `node_modules/` and `.git/` (deeper hits are usually vendored dependencies).

### Usage

```sh
.claude/skills/codofable-diagnostics-and-tooling/scripts/repo_recon.sh [REPO_PATH]   # default: .
```

Exit codes: `0` = ran (empty sections are normal) · `2` = path is not a directory.

### How to read each section

| Section | What it means | What to do with it |
|---|---|---|
| `MANIFESTS` | Ecosystem declarations found (package.json, pyproject.toml, Cargo.toml, Makefile, Dockerfile, ...). Multiple entries in different subdirs = polyglot/monorepo; onboard each component separately. | Tells you which toolchains the repo needs |
| `LOCKFILES` | Pinned dependency snapshots. The lockfile identifies the ONE installer the project expects (`package-lock.json`→npm, `yarn.lock`→yarn, `pnpm-lock.yaml`→pnpm, `uv.lock`→uv, `poetry.lock`→poetry). | Use that installer's frozen mode; using a different one silently drifts versions |
| `VERSION PINS` | Version-manager files (`.nvmrc`, `.python-version`, `.tool-versions`, `rust-toolchain`, ...). | Match the pinned runtime BEFORE installing; wrong-runtime installs produce misleading failures |
| `CI CONFIG` | Pipeline definitions. CI is the repo's executable ground truth for how it actually builds and tests. | Read these files next — trust them over the README when they disagree |
| `AGENT CONFIG` | `CLAUDE.md` / `.claude/` presence, with a skill-directory count. | If skills exist, load the relevant ones before working |
| `LIKELY COMMANDS` | Heuristic candidates inferred from the above (npm scripts and Makefile targets are parsed from the real files, not guessed). | These are E4 candidates, not verified facts — confirm against README/CI, then RUN them before writing them into any doc (per Brief-level ground-truth rules) |

### Expected output A — this repo, sparse (run in-session 2026-07-05, real, unedited)

```text
repo_recon: /home/user/codofable

== MANIFESTS ==
  (none found)

== LOCKFILES ==
  (none found)

== VERSION PINS ==
  (none found)

== CI CONFIG ==
  (none found)

== AGENT CONFIG ==
  .claude/
  .claude/skills/ (12 skill dir(s))

== LIKELY COMMANDS (candidates — verify against README/CI before trusting) ==
  (none found)
```
Exit code: `0`. Interpretation: codofable has no application build system — correct, the project is a skill library [repo]. The skill-dir count is volatile while authoring is in progress (it was 12 at run time; re-run for the current number).

### Expected output B — synthetic polyglot fixture, rich (run in-session 2026-07-05, real, unedited)

The fixture: a Node app (package.json + package-lock.json + .nvmrc + Makefile + Dockerfile + GitHub Actions workflow) with a Python service in `api/` (pyproject.toml + uv.lock + .python-version).

```text
repo_recon: recon-repo

== MANIFESTS ==
  package.json
  api/pyproject.toml
  Makefile
  Dockerfile

== LOCKFILES ==
  package-lock.json
  api/uv.lock

== VERSION PINS ==
  .nvmrc
  api/.python-version

== CI CONFIG ==
  .github/workflows/ci.yml

== AGENT CONFIG ==
  (none found)

== LIKELY COMMANDS (candidates — verify against README/CI before trusting) ==
  npm ci                            # install (npm lockfile present)
  npm run <script>                  # scripts in package.json: build test lint 
  uv sync                           # install (uv lockfile present)
  pytest                            # test (convention; check pyproject [tool.pytest])
  make <target>                     # Makefile targets: all build test deploy 
```
Exit code: `0`. Note that `npm run <script>` lists the repo's actual script names and `make <target>` its actual targets — parsed from the files, so you never guess at script names.

## Universal measurement commands

All rows are [craft] patterns — ecosystem-generic, not verified against a specific project here. Substitute your paths/commands; run in-session before citing any number.

| To measure | Pattern | Reading it |
|---|---|---|
| Wall-clock time of a command | `time CMD` (coarse, 1 run) · better: `for i in 1 2 3 4 5; do /usr/bin/time -f '%es' CMD >/dev/null; done` · best: `hyperfine 'CMD_A' 'CMD_B'` if installed | Never compare single runs; take ≥5 and compare medians. Statistics for the comparison → `codofable-proof-and-analysis-toolkit` |
| File length vs a limit | `wc -l FILE` | The number, vs the stated limit — not "looks long" |
| Change size (N3 check) | `git diff --stat` · staged: `git diff --cached --stat` | Files touched beyond the task's scope = drive-by; revert them |
| Untracked/dirty state | `git status --porcelain \| wc -l` | 0 = clean tree; nonzero before "done" needs explaining |
| Test-count delta | Run the suite before and after; capture the runner's `N passed, M failed` summary lines and diff them | Passed-count DROPPING while the suite "passes" can mean tests were skipped/deleted — an N2 violation signal |
| Occurrences of a pattern | `grep -rn 'PATTERN' DIR \| wc -l` | Before/after count proves "removed all X" claims |
| Disk footprint | `du -sh DIR` | Before/after for "smaller" claims |
| Output equivalence | `CMD_A > a.out; CMD_B > b.out; diff a.out b.out && echo IDENTICAL` | Empty diff is the claim "behavior unchanged"; anything else is the counterexample |

## Adding a new script to this skill

A new script is a Class 2 change (it alters what future sessions execute) — gate it per `codofable-change-control`. Mechanical requirements [craft]:

1. **Header contract.** POSIX `sh` or `bash`; no dependencies beyond coreutils/git/awk/grep/sed/find. Top-of-file comment states usage, output format, and exit codes. `chmod +x` it.
2. **Exit-code contract.** `0` = success, nonzero = finding or error, distinct code for usage errors — scripts here are gates, and gates are read by exit code, not by vibes.
3. **Fixture requirement.** Build a synthetic fixture that exercises both the pass path and every failure path, OUTSIDE the repo (temp/scratch space — never committed, never referenced by path in the skill). A script whose failure mode was never triggered is unverified (N1).
4. **Evidence in the doc.** Run it in-session on the fixture(s); paste the real, unedited output into this SKILL.md as the expected-output example, with the exit code and a date stamp. E4 descriptions of what a script "would print" are not acceptable here.
5. **Document interpretation, not just invocation.** Add a "what each line means / what to do about each finding" table like the ones above. Output nobody can interpret is noise.
6. **Re-run the validator** (`scripts/validate_skills.sh`) on the library after editing this SKILL.md, and paste the summary line in your change evidence.

## Provenance and maintenance

- Date stamp: authored 2026-07-05. Evidence classes per the library convention: [repo] = verifiable in this repository, [doc] = cited external document, [craft] = professional judgment.
- Both scripts were written, executed, and debugged in-session on 2026-07-05 under both `dash` (`/bin/sh` here) and `bash`; every output block above is pasted verbatim from those runs [repo — re-runnable]. Validator fixtures covered: pass, WARN (470 lines), >500 lines, missing SKILL.md, name mismatch, empty description, >1024-char description, missing headings, unclosed frontmatter — exit codes 0/1/2 all observed.
- Volatile facts: the "12 skill dir(s)" count and the mid-build FAIL rows reflect the library DURING parallel authoring on 2026-07-05; the fixture outputs are stable. The invariant thresholds (450/500 lines, 1024 chars) mirror `codofable-architecture-contract` and `codofable-docs-and-writing` as of that date — if the contract changes its limits, update the constants at the top of `validate_skills.sh` in the same change.
- Re-verification one-liners (from the repo root):
  - `sh .claude/skills/codofable-diagnostics-and-tooling/scripts/validate_skills.sh; echo "exit=$?"` — library invariants now.
  - `sh .claude/skills/codofable-diagnostics-and-tooling/scripts/repo_recon.sh .` — recon output for this repo now.
  - `sh -n .claude/skills/codofable-diagnostics-and-tooling/scripts/*.sh && echo syntax-ok` — both scripts still parse as POSIX sh.
  - `ls -l .claude/skills/codofable-diagnostics-and-tooling/scripts/` — confirm the executable bit survived.
- The `hyperfine` mention is a [craft] pattern; it is NOT installed in this sandbox as of 2026-07-05 (`command -v hyperfine` returns nothing) — treat it as optional tooling.
