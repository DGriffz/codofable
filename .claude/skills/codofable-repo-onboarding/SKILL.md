---
name: codofable-repo-onboarding
description: Runbook for arriving in an unknown repository and becoming oriented, bootstrapped, and able to run it. Load this skill when a session starts in a codebase it has never seen, when asked to "set up", "get running", "build", "install dependencies", "onboard", or "figure out this repo", when an environment must be recreated from scratch, or after context loss forces re-orientation (per N10). Provides a numbered reconnaissance sequence (manifest → docs → CI-as-ground-truth → baseline test run), git-history mining commands with expected output shapes, a catalog of environment bootstrap traps (version managers, lockfiles, monorepos, proxies, Docker, postinstall scripts) each with a detection command and fix, and a checklist defining when you count as oriented. Not for cataloging config options (codofable-config-mapping) or diagnosing something broken (codofable-debugging-playbook).
---

# Repo Onboarding: Orient, Bootstrap, Run

This skill is the runbook for the first hour in a repository you have never seen. Its output is a working environment plus four facts you can state with evidence: the build command, the test command, CI's definition of green, and the baseline test result before you changed anything. Everything here follows one principle: **the repository's executable artifacts (CI config, lockfiles, manifests) outrank its prose (READMEs, wikis)** — prose describes intent, artifacts describe reality. [craft]

Definitions used below: a *manifest* is the file that declares a project's dependencies and metadata (e.g. `package.json`); a *lockfile* pins exact resolved dependency versions (e.g. `package-lock.json`); *CI* (continuous integration) is the automated pipeline that builds and tests every change (e.g. GitHub Actions workflows).

## When to use this skill

- You have been dropped into an unfamiliar repository and must make any change to it.
- You are asked to "get this running", "set up the dev environment", or "run the tests" in a project you have not bootstrapped in this session.
- A session restart or compaction wiped your environment knowledge — re-run the orientation sequence rather than trusting memory (per N10).
- You are about to install dependencies, and want to avoid the traps in Section 3 (wrong runtime version, mutated lockfile, broken sandbox network).
- You need to find out who knows a codebase, what its hotspots are, or whether an approach was already tried and reverted (Section 2).

## When NOT to use this skill

- You need a systematic catalog of the repo's configuration axes, flags, and defaults → `codofable-config-mapping`. This skill only gets you running; it does not enumerate config.
- Something that used to work is now broken, or the build/tests fail in a way you must diagnose → `codofable-debugging-playbook`. Onboarding *records* a failing baseline; debugging *explains* it.
- You want reusable measurement scripts (including automated repo recon) → `codofable-diagnostics-and-tooling`.
- You are deciding whether a change you plan is safe to make → `codofable-change-control`.

## 1. The reconnaissance sequence

Run these steps in order. Do not skip ahead to installing things — Step 5's traps assume Steps 1–4 happened.

### Step 1 — Identify the ecosystem from manifest files

Run at the repo root (pattern — adjust `-maxdepth` for monorepos):

```bash
ls package.json pyproject.toml setup.py Cargo.toml go.mod pom.xml \
   build.gradle build.gradle.kts Gemfile Makefile CMakeLists.txt 2>/dev/null
find . -maxdepth 2 -name node_modules -prune -o -type f \
  \( -name 'package.json' -o -name 'pyproject.toml' -o -name 'Cargo.toml' \
     -o -name 'go.mod' -o -name 'pom.xml' -o -name 'Gemfile' \) -print
```

In THIS repository that first command matches nothing (exit 2, verified 2026-07-05) — codofable is a documentation-only repo with no manifest, no build, no test suite [repo]. That is itself a valid recon result: record "no build system" and stop bootstrapping.

Map what you find (all commands in this table are ecosystem-generic patterns, not run here):

| Manifest file | Ecosystem | Install command (lockfile-safe) | Default test command |
|---|---|---|---|
| `package.json` | Node.js | `npm ci` (or `pnpm install --frozen-lockfile` / `yarn install --immutable`, per which lockfile exists) | `npm test` |
| `pyproject.toml` | Python (modern) | `pip install -e .` in a fresh venv; `poetry install` or `uv sync` if their lockfiles exist | `pytest` |
| `setup.py` | Python (legacy) | `pip install -e .` in a fresh venv | `pytest` or `python setup.py test` |
| `Cargo.toml` | Rust | `cargo build` (respects `Cargo.lock` automatically) | `cargo test` |
| `go.mod` | Go | `go mod download` | `go test ./...` |
| `pom.xml` | Java (Maven) | `mvn install -DskipTests` | `mvn test` |
| `build.gradle` / `.kts` | Java/Kotlin (Gradle) | `./gradlew build -x test` (use the wrapper, never a global gradle) | `./gradlew test` |
| `Gemfile` | Ruby | `bundle install` (with `Gemfile.lock` present, Bundler pins to it) | `bundle exec rake test` or `bundle exec rspec` |
| `Makefile` | Any (task runner) | `make` — but read it first: `make help` or open the file (per N7) | `make test` if that target exists |
| `CMakeLists.txt` | C/C++ | `cmake -B build && cmake --build build` | `ctest --test-dir build` |

Which lockfile is present decides the package manager: `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `poetry.lock` → poetry, `uv.lock` → uv. Do not use a different manager than the lockfile implies — you will regenerate the lockfile as a side effect (Trap 3.2, forbidden by N3).

### Step 2 — Read the prose (but hold it loosely)

```bash
ls README* CONTRIBUTING* HACKING* docs/ .github/ 2>/dev/null
```

Read README and CONTRIBUTING for stated setup steps, required services, and vocabulary. Treat every command in them as a *claim to verify*, not a fact — READMEs go stale because nothing executes them. [craft]

### Step 3 — Mine CI as ground truth

```bash
ls .github/workflows/ 2>/dev/null && cat .github/workflows/*.yml
cat .gitlab-ci.yml .circleci/config.yml Jenkinsfile azure-pipelines.yml .travis.yml 2>/dev/null
```

(Pattern; in this repo there is no CI config — verified 2026-07-05 [repo].)

CI config shows how the project is ACTUALLY built and tested: exact runtime versions in `setup-node`/`setup-python` steps, the real install command, the real test invocation with its flags, required env vars and services (look for `services:` and `env:` blocks), and the set of jobs that must pass for a change to merge. When the README and CI disagree, CI wins — CI executes on every commit and cannot drift silently; the README can. **CI never lies; READMEs do.** [craft]

Extract from CI and write down: (a) the install command, (b) the build command, (c) the test command with flags, (d) the full list of gating jobs — that list is "CI's definition of green".

### Step 4 — Run the test suite BEFORE changing anything

After bootstrap (Step 5 / Section 3), run the exact test command CI runs and capture the output:

```bash
# pattern — substitute the command from Step 3
<ci-test-command> 2>&1 | tee /tmp/baseline-test-run.txt
tail -20 /tmp/baseline-test-run.txt   # record the summary line
```

This is the **baseline**. Record: pass/fail counts, skipped tests, runtime, and any pre-existing failures *by name*. Rationale: a pre-existing failure discovered after you start editing is indistinguishable from a failure you caused — discovered later, it looks like your fault, and proving otherwise costs a bisection you didn't need. The baseline is also what makes later E2 evidence meaningful (see `codofable-validation-and-qa`): "tests pass" only counts as evidence about your change if you know they passed before it too. [craft]

If the baseline is red: do not fix it as a side quest (N3). Record it, report it, and either get agreement to fix it first as its own change or scope your work to not depend on the failing area.

### Step 5 — Bootstrap the environment

Now, and only now, install things — using Section 3's trap checklist first. Check version managers (3.1) before any install command.

## 2. Git-history mining

Git history is the highest-density orientation source after CI. All commands below were RUN in this repository on 2026-07-05; outputs marked [repo] are real. This repo's history is tiny (two commits), so the outputs mainly demonstrate the output *shape* — the interpretation notes tell you what to look for in a real codebase.

**Recent activity** — what is this project busy with right now:

```bash
git log --oneline -20
```
Output here [repo]:
```
c321e16 Enhance README with skill library development phases
c30ac04 Initial commit
```
In a live repo, read the last 20 subjects as a narrative: active subsystems, ongoing migrations, release cadence.

**Hotspots** — which files change most (change frequency correlates with both importance and bug density [craft]):

```bash
git log --format= --name-only | sort | uniq -c | sort -rn | head
```
Output here [repo]:
```
      2 README.md
      1 LICENSE
```
In a live repo, the top ten files are where you should expect complexity, conflicts, and reviewers' attention.

**Reverts** — approaches that were tried and rolled back (do not re-fight settled battles; see `codofable-failure-archaeology`):

```bash
git log --grep=revert -i --oneline
```
Output here [repo]: empty — zero reverts (verified: `| wc -l` → 0). In a live repo, read each revert's message and the reverted commit before attempting anything similar.

**Branches and their freshness** — stale branches mark stalled or abandoned work:

```bash
git for-each-ref --sort=-committerdate \
  --format='%(committerdate:short) %(refname:short) %(subject)' refs/remotes/
```
Output here [repo]:
```
2026-07-02 origin/claude/skill-library-continuity-17geoa Enhance README with skill library development phases
2026-07-02 origin/main Enhance README with skill library development phases
```
Interpretation: both remote branches point at the same commit; there are no dead branches in this repo. In a live repo, branches months behind the default branch with unmerged work are archaeology sites, not starting points.

**Who knows what** — commit counts per author:

```bash
git shortlog -sn HEAD
```
Output here [repo]:
```
     2  Darko Tomic
```
Note the `HEAD` argument: without a revision, `git shortlog` reads from stdin when not attached to a terminal and appears to hang in scripted/agent environments — this bit us during authoring [repo]. Scope to a subsystem with `git shortlog -sn HEAD -- path/` (pattern) to find the owner of the code you are about to touch.

## 3. Environment bootstrap traps

Each trap: what it is, a detection command, and the fix. Detection commands are generic patterns unless marked [repo]. All trap selections and fixes are [craft].

### 3.1 Version managers — check BEFORE installing anything

The repo may pin a runtime version. Installing dependencies with the wrong runtime produces failures that look like broken code.

```bash
ls .nvmrc .node-version .python-version .ruby-version .tool-versions \
   rust-toolchain.toml rust-toolchain .java-version 2>/dev/null
grep -E '"node"|"npm"' package.json 2>/dev/null   # "engines" field
grep -E 'requires-python|python_requires' pyproject.toml setup.py setup.cfg 2>/dev/null
```

Fix: activate the pinned version first (`nvm use`, `pyenv install $(cat .python-version)`, `rustup show` — rustup auto-respects `rust-toolchain.toml`; `asdf install` for `.tool-versions`). If no manager is available, verify your system version satisfies the pin (`node --version`, `python --version`) before proceeding, and record the mismatch if it doesn't.

### 3.2 Lockfile discipline — never regenerate a lockfile as a side effect

A regenerated lockfile is an unrequested, behavior-changing diff smuggled into your change (violates N3, and is a Class 2 change per `codofable-change-control` that you did not classify).

Detection — after ANY install step, before you consider bootstrap done:

```bash
git status --porcelain -- '*lock*' '*.lock'
```

If a lockfile shows as modified and you didn't intend to update dependencies: `git checkout -- <lockfile>` and redo the install with the pinning form:

| Manager | Wrong (may rewrite lockfile) | Right (respects lockfile exactly) |
|---|---|---|
| npm | `npm install` | `npm ci` |
| pnpm | `pnpm install` (older versions) | `pnpm install --frozen-lockfile` |
| yarn | `yarn install` | `yarn install --immutable` (v2+) / `--frozen-lockfile` (v1) |
| poetry | `poetry update` | `poetry install` (add `--sync` to match exactly) |
| uv | `uv lock` then sync | `uv sync --frozen` |
| bundler | `bundle update` | `bundle install` |

### 3.3 Monorepos and workspaces

Installing or testing in a subdirectory of a workspace silently does the wrong thing (misses hoisted deps, runs zero tests).

```bash
grep -l workspaces package.json 2>/dev/null; ls pnpm-workspace.yaml lerna.json \
   turbo.json nx.json go.work 2>/dev/null
grep -E '^\[workspace\]' Cargo.toml 2>/dev/null; ls settings.gradle* 2>/dev/null
```

Fix: always install from the workspace ROOT. Run package-scoped commands with the workspace tool's own filter (`npm run test -w <pkg>`, `pnpm --filter <pkg> test`, `cargo test -p <crate>`, `./gradlew :module:test`) rather than `cd`-ing into the package.

### 3.4 Proxies and CA bundles in sandboxed environments

Sandboxed/agent environments often route HTTPS through a proxy with a custom CA (certificate authority). Symptoms: TLS verification errors, 403/407 from every registry.

```bash
env | grep -iE 'proxy|ca_bundle|ca_cert|extra_ca'
```

Fix: point each tool at the environment's CA bundle via its own knob — `NODE_EXTRA_CA_CERTS` (Node), `PIP_CERT` / `REQUESTS_CA_BUNDLE` (Python), `GIT_SSL_CAINFO` (git), `CARGO_HTTP_CAINFO` (cargo), `SSL_CERT_FILE` (generic). **Never disable TLS verification and never unset the proxy variables** — that trades a loud, honest failure for silent breakage and a security hole. If the environment ships its own proxy README, read it first (N7).

### 3.5 Docker-based dev environments

If development is containerized, host-side installs may be pointless or even harmful (wrong OS, wrong libc).

```bash
ls Dockerfile* docker-compose*.yml compose*.yml .devcontainer/ 2>/dev/null
```

Fix: check whether CI and CONTRIBUTING assume the container. If yes, either use it (`docker compose up`, or the devcontainer config) or consciously replicate its base image's runtime versions on the host — and note which one you did, because "works on host, fails in container" is a classic false-green.

### 3.6 Postinstall scripts

`npm install`/`npm ci` runs arbitrary lifecycle scripts; these can compile native modules (needing system toolchains), download binaries (needing network), or fail opaquely in sandboxes.

```bash
grep -E '"(pre|post)install"|"prepare"' package.json */package.json 2>/dev/null
```

Fix: read what the script does before running it (N7). In a restricted sandbox, `npm ci --ignore-scripts` gets dependencies installed; then run the specific required script manually once you understand it. Expect packages with native builds (`node-gyp` and friends) to need `python3`, `make`, and a C++ compiler present.

### 3.7 OS-specific dependencies

Native extensions and system libraries differ by OS; a Linux sandbox is not the maintainers' macOS laptop.

```bash
uname -a
# then look for native-dep markers:
grep -rl node-gyp package.json 2>/dev/null; ls -d */*.c */*.rs 2>/dev/null | head
grep -iE 'apt-get|brew install|apk add' README* CONTRIBUTING* .github/workflows/*.yml 2>/dev/null
```

Fix: the CI workflow's package-install steps (`apt-get install ...`) are the authoritative list of system prerequisites for Linux — copy them, don't guess from the README's `brew install` line.

## 4. You are oriented when

Do not claim "set up and ready" (that is a done-claim; N1 applies) until every box is checked:

- [ ] You can state the **build command**, copied from CI or verified by running it, not inferred from the README.
- [ ] You can state the **test command** with its flags, same standard.
- [ ] You can state **CI's definition of green**: which jobs gate a merge, from the CI config (or "no CI exists", recorded as a fact).
- [ ] The **baseline test result is recorded**: pass/fail counts and named pre-existing failures, captured to a file BEFORE any edit of yours.
- [ ] You know **where the entrypoint is**: the `main`/`bin`/`cmd`/server-start location for the artifact you will touch (from the manifest's `main`/`bin`/`scripts` fields, `cmd/` convention in Go, `[[bin]]` in Cargo, or `if __name__ == "__main__"` search).
- [ ] `git status --porcelain` shows **no unintended modifications** from bootstrap (especially lockfiles, per 3.2).
- [ ] You have skimmed the last 20 commits and know the top hotspot files (Section 2).

If any box cannot be checked, say so explicitly and label the gap "open" (N8) — an honest partial orientation beats a confident false one.

## Provenance and maintenance

- Date-stamped 2026-07-05. Volatile facts and their evidence class:
  - [repo] This repository has exactly two commits, two branches (local `claude/skill-library-continuity-17geoa` + `main`, matching remotes) all at the same commit, zero reverts, one author (Darko Tomic), no manifest files, and no CI config. All Section 1/2 outputs shown as `[repo]` were captured by running the printed commands in-session on 2026-07-05. Re-verify: `git log --oneline -20 && git shortlog -sn HEAD && ls .github/workflows 2>/dev/null`.
  - [craft] The trap catalog (Section 3), the CI-over-README principle, and all interpretation guidance are the fellow's professional judgment, marked pattern where not runnable here. The lockfile-pinning flag names (`npm ci`, `--frozen-lockfile`, `--immutable`, `uv sync --frozen`) are correct as of the 2026-07-05 authoring date but package managers rename flags across major versions — re-verify with `<tool> install --help` before relying on an exact flag in a new environment.
- Commands in the Section 1 table and Section 3 detection/fix blocks are ecosystem-generic patterns (not executable in this manifest-less repo); every command marked [repo] was executed here.
- Doctrine cited, not restated: N1/N3/N7/N8/N10 and change classes per `codofable-change-control`; evidence levels per `codofable-validation-and-qa`.
