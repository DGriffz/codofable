---
name: codofable-config-mapping
description: Load this skill before touching any configuration in a repository you did not write — adding a feature flag, changing a default, renaming an env var, editing a config file, wiring a new option, or answering "what settings does this app have?" / "where is X configured?" / "is this flag still used?" / "which config wins?". Provides a taxonomy of the seven configuration axes (env vars, config files, build-time constants, feature flags, CLI args, per-environment overrides, secrets), tested grep/glob patterns to find every instance of each, a runbook that produces a config inventory with verified precedence order, heuristics to tell production knobs from experimental ones, and a safe flag-add checklist (Class 2 change). Trigger phrases include "add a flag", "add a config option", "feature flag", "environment variable", "config precedence", "dead flag", "map the config surface".
---

# Config mapping: catalog a repo's configuration surface before touching it

Configuration is the part of a system that changes behavior without changing code, so it is also the part where a "small" edit silently changes production. This skill teaches you to MAP a repository's entire configuration surface — every axis, every option, its default, where it is read and where it is set — before you add, change, or remove anything, and then to add a flag safely. The mapping procedure is Class R (read-only); the flag-add is Class 2 minimum (see `codofable-change-control` for change classes).

Definitions used throughout:
- **Option / knob**: any named value that alters runtime behavior and is settable outside the code path that reads it.
- **Feature flag**: a boolean-ish option whose purpose is to gate a feature on/off (in-code constant, env var, or a flag service like LaunchDarkly).
- **Precedence order**: which source wins when the same option is set in several places (e.g. CLI arg vs env var vs config file vs built-in default).

## When to use this skill

- You are about to add, rename, re-default, or remove any configuration option or feature flag.
- Someone asks "what can be configured here?", "where does setting X come from?", or "is flag Y dead?".
- A task requires knowing whether a knob is production-load-bearing or experimental.
- You changed code that reads config and need to know every place the value could be set.
- Before a `codofable-repo-onboarding` handoff deepens into real work: onboarding gets you running; this skill gets you a config inventory you can safely edit against.

## When NOT to use this skill

| Situation | Use instead |
|---|---|
| First arrival in an unknown repo — you just need to build/run it | `codofable-repo-onboarding` |
| A bug that happens to involve config (wrong value at runtime, works-on-my-machine) | `codofable-debugging-playbook` (this skill's inventory can feed it, but triage comes first) |
| Deciding what gate/evidence your config change needs | `codofable-change-control` (classes) and `codofable-validation-and-qa` (evidence levels) |
| Recreating an environment or diagnosing env/tooling breakage | `codofable-repo-onboarding` |

## The seven configuration axes

Every repo's configuration surface decomposes into these axes. A mapping is complete only when you have swept ALL seven — repos routinely use four or five at once, and the bugs live in the interactions. [craft]

| # | Axis | What it is | Typical carriers |
|---|---|---|---|
| 1 | Environment variables | Values read from the process environment at runtime | `process.env.*`, `os.environ`, `os.Getenv`, `getenv()` |
| 2 | Config files | Values parsed from files at startup, by format and load order | `.env`, `*.yaml/yml`, `*.json`, `*.toml`, `*.ini`, `settings.py` |
| 3 | Build-time constants | Values baked in at compile/bundle time; changing them requires a rebuild | webpack `DefinePlugin`, Vite `import.meta.env`, Go `-ldflags -X`, C `#define` |
| 4 | Feature flags | Behavior gates; in-code (constants, env-derived booleans) or service-based (LaunchDarkly, Unleash, Statsig, Flagsmith, Split) | flag maps, `GetBool("features.*")`, SDK clients |
| 5 | CLI arguments | Values passed on the command line, usually highest precedence | argparse/click, Go `flag`/cobra, clap, yargs/commander |
| 6 | Per-environment overrides | dev/staging/prod variants of any of the above | `config/production.yaml`, `NODE_ENV`/`APP_ENV` switches, k8s overlays |
| 7 | Secrets | Config that must never be committed; often set only in deploy tooling | `secretKeyRef`, Vault, cloud secret managers, `*_API_KEY`/`*_TOKEN` vars |

## Finding every instance: tested search patterns

All patterns below were run on 2026-07-05 with ripgrep 14.1.0 against a small synthetic multi-language fixture (Node + Python + Go + C + webpack + k8s + GitHub Actions). The fixture files and the full raw outputs are in [references/pattern-test-fixture.md](references/pattern-test-fixture.md) so you can rebuild it and re-test. **The patterns are verified as patterns; hit lists in YOUR repo will differ — these are search recipes for target repos, not results.** [craft, verified-on-fixture]

**Blocking gotcha, verified on the fixture: plain `rg` skips hidden files and gitignored files by default.** `.env*`, `.github/workflows/`, and anything gitignored are exactly where config lives. Add `--hidden` to every config sweep (and `-uu` if you also need gitignored files, e.g. a local `.env`):

```bash
# WRONG for config work (misses .env.example, .github/):   rg "FLAG_NEW_CHECKOUT" .
# RIGHT:
rg -n --hidden "FLAG_NEW_CHECKOUT" .
```

On the fixture, the plain form missed 3 of 7 hits; `--hidden` found all 7. If a pattern below returns suspiciously little, this is the first thing to check.

### Axis 1 — environment variables

```bash
# Every env-var READ site (JS/TS, Python, Go, C/shell-style):
rg -n --hidden "process\.env\.[A-Z0-9_]+|os\.environ|os\.getenv|getenv\(|os\.Getenv|viper\.BindEnv|ENV\[" .

# Extract the deduplicated NAME list (feed this into your inventory table):
rg -oI --hidden --no-filename \
  "process\.env\.([A-Z0-9_]+)|os\.environ(\.get)?\([\"']([A-Z0-9_]+)|os\.getenv\([\"']([A-Z0-9_]+)|getenv\([\"']([A-Z0-9_]+)|os\.Getenv\([\"']([A-Z0-9_]+)|BindEnv\([^,]+, ?[\"']([A-Z0-9_]+)" . \
  | rg -o "[A-Z][A-Z0-9_]{2,}" | sort -u
```

Fixture output of the extraction (11 names from 5 languages/files): `APP_TIMEOUT CACHE_TTL DATABASE_URL DEBUG_PANEL FLAG_NEW_CHECKOUT GITHUB_TOKEN GIT_SHA HTTP_PROXY NODE_ENV PORT STRIPE_API_KEY`.

Known blind spots of this sweep (record them as unknowns, per N8): dynamic access (`process.env[name]`, `os.environ[key_var]`), framework auto-binding (pydantic-settings `env_prefix` and viper `AutomaticEnv` create env readers with **no literal name in the code** — find the prefix declaration instead: `rg -n --hidden "env_prefix|AutomaticEnv|SetEnvPrefix" .`).

### Axis 2 — config files and their loaders

```bash
# Find the files (by format):
find . -maxdepth 4 \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.toml' \
  -o -name '*.ini' -o -name '.env*' -o -name '*.env' \) -not -path './node_modules/*' -not -path './.git/*' | sort

# Find the LOADERS (this tells you load order and which files are actually read):
rg -n --hidden "dotenv|BaseSettings|pydantic_settings|viper\.(SetConfigName|AddConfigPath|ReadInConfig|SetDefault)|ConfigParser|yaml\.(safe_)?load|json\.load|toml\.load|convict|node-config|config\.get" .
```

A config file that no loader reads is documentation, not configuration — verify each discovered file has a loader before putting it in the inventory. On the fixture this pairing correctly matched `dotenv → .env`, `BaseSettings → env/.env`, `viper → config/*.yaml`.

### Axis 3 — build-time constants

```bash
rg -n --hidden "DefinePlugin|import\.meta\.env|ldflags|-X main\.|-X '?[a-z_./]+\.[A-Z]|#define|BUILD_(SHA|VERSION|TIME)|__BUILD" .
```

Mark these separately in the inventory: they cannot be changed by ops at runtime, so a "just flip the env var in prod" plan silently fails for them. (Fixture: caught webpack `DefinePlugin` and Go `-ldflags -X main.Version`.)

### Axis 4 — feature flags

```bash
# In-code flags + common flag-service SDKs:
rg -ni --hidden "FLAG_[A-Z0-9_]+|feature[s]?\.|enable_[a-z_]+|launchdarkly|ldclient|unleash|flagsmith|statsig|split\.io|GetBool\(" .
```

This pattern is deliberately noisy (it will hit `features.md` etc.) — skim and keep real gates. Service-based flags mean part of your config surface lives OUTSIDE the repo; record the SDK + project key in the inventory and mark actual flag states as unknown until you read them from the service (N8).

### Axis 5 — CLI arguments

```bash
rg -n --hidden "add_argument\(|@click\.option|flag\.(String|Int|Bool|Duration)\(|cobra\.Command|clap|yargs|commander|\.option\(" .
```

### Axis 6 — per-environment overrides

```bash
# Environment-named files and the switch variable:
find . -maxdepth 4 \( -iname '*prod*' -o -iname '*staging*' -o -iname '*dev*' -o -iname '*local*' \) -not -path './.git/*' -not -path './node_modules/*'
rg -n --hidden "NODE_ENV|APP_ENV|ENVIRONMENT|RAILS_ENV|DJANGO_SETTINGS_MODULE|GO_ENV|MIX_ENV" .
```

### Axis 7 — secrets

```bash
rg -ni --hidden "secretKeyRef|vault|secretsmanager|secret_manager|sops|_API_KEY|_SECRET|_TOKEN|PASSWORD|PRIVATE_KEY" .
```

Secrets are read like env vars but SET only in deploy tooling or a manager. Never print their values; inventory the *names* and the *setting mechanism* only. If a real secret value appears in the repo, stop and report it — remediation is Class 3 territory (history rewrite, rotation) requiring human authorization per N6.

### Where values are SET (all axes)

Reads are half the map. Sweep the setters — deploy manifests, CI, compose, Dockerfiles, Makefiles:

```bash
rg -n --hidden "SOME_VAR_NAME" deploy/ k8s/ helm/ .github/ .gitlab-ci.yml docker-compose* Dockerfile* Makefile Procfile 2>/dev/null
```

(Adjust the path list to what exists; `ls` the repo root first. On the fixture this correctly located `FLAG_NEW_CHECKOUT` set in both `deploy/k8s.yaml` and `.env.example`, with different values — exactly the kind of divergence the inventory must surface.)

## The mapping runbook

This whole procedure is Class R — read-only. Do not "fix" anything you find mid-sweep (N3); note it and finish the map.

1. **Sweep all seven axes** with the patterns above (plus repo-specific ones you derive from its stack). Keep raw outputs.
2. **Build the inventory table.** One row per option:

   | Name | Axis | Type | Default | Read at (file:line) | Set at (file:line or "runtime/external") | Prod or experimental? | Notes/unknowns |
   |---|---|---|---|---|---|---|---|
   | `FLAG_NEW_CHECKOUT` | env/flag | bool-string | `false` (absent ⇒ false) | `src/server.js:4` | `deploy/k8s.yaml:9` (=true), `.env.example:4` (=false) | prod (set in deploy) | prod and example disagree |

   "Default" means the effective behavior when the option is unset — read the consuming code to determine it; do not assume the example file's value is the default.
3. **Determine precedence — by reading the loader code, never by assumption.** `CLI > env > file > default` is the *common* convention, but it is per-library and per-repo: dotenv's Node package does not override existing env vars by default, while some loaders and `override:true` modes do; viper has its own documented order; a hand-rolled loader can do anything. Find the load sequence in the entrypoint, then **prove it with a probe** when the app is runnable: set the same option to different values at two sources, run, and observe which wins (that is E1 evidence; reading the loader alone is E3/E4). Generic probe shape (pattern, adapt per repo):

   ```bash
   # pattern — set env AND file to different values, see which the app reports:
   SOME_OPT=envval ./app --print-config | rg SOME_OPT
   ```

4. **Record unknowns as unknowns (N8).** Dynamic env access, external flag services, values set by infrastructure you cannot see — write "unknown: set outside repo (suspect Terraform/console)" in the row rather than guessing. An honest hole beats a confident fabrication; the next session will trust your table.
5. **Cross-check reads vs sets.** Options read but never set anywhere = running on defaults everywhere (fine, but confirm the default is what prod actually wants). Options set but never read = drift candidates (next section).

## Production vs experimental vs dead: discrimination heuristics

Apply in order; first match usually decides, but conflicts mean "unknown — ask". [craft]

| Signal | Verdict |
|---|---|
| Referenced in deploy/CI/infra config (k8s manifests, helm values, CI env blocks, Terraform) | **Production.** Ops depends on it; changing default or semantics is Class 2 with prod-realistic testing. |
| Read only inside `if dev/debug/test` guards (e.g. `NODE_ENV !== 'production'`, `DEBUG`, `#ifdef DEBUG`) | **Experimental/dev-only.** Lower blast radius, still Class 2 to change behavior. |
| Documented in README/ops docs or exposed in `--help` | Production-facing (users may set it even if your deploy doesn't). |
| Name carries `EXPERIMENTAL`, `BETA`, `UNSTABLE`, or lives in a flags/experiments module | Experimental — but verify: experiments get quietly promoted without renames. |
| Definition/setter exists, **zero read sites** after a `--hidden` sweep including dynamic-access spot-checks | **Dead-flag candidate.** Candidate only: dynamic reads, other repos, and external services can consume it invisibly. |

Verified fixture demonstration of the dead-check (counts read-sites, excluding setter locations — adapt the exclusion globs to the target repo):

```bash
for v in PORT FLAG_NEW_CHECKOUT UNUSED_KNOB; do
  n=$(rg -l --hidden -g '!.env*' -g '!deploy' -g '!.github' "$v" . | wc -l)
  echo "$v: read in $n code file(s)"
done
# fixture output:  PORT: 1   FLAG_NEW_CHECKOUT: 1   UNUSED_KNOB: 0   ← UNUSED_KNOB is the plant, correctly caught
```

**Deleting a dead-flag candidate is Class 2 minimum** (it changes config surface and can break external consumers) — confirm with the repo's owners before removal, and say "candidate for dead" not "dead" until then (N8).

## Safe flag-add checklist (Class 2 — per codofable-change-control)

Adding a flag alters runtime behavior and config surface: Class 2, evidence E2 or better on the final state. Work the list top to bottom; every box is required.

- [ ] **Inventory first.** You ran the mapping runbook (at least the axis the flag lives on) and confirmed the name is unused across reads AND setters (`rg -n --hidden "NEW_FLAG_NAME" .` returns nothing), and follows the repo's existing naming convention.
- [ ] **Default preserves current behavior.** With the flag unset, the system behaves byte-for-byte as before. Absent-vs-set-false must be explicit in the parsing code (beware truthy string parsing: `"false"` is truthy in JS/Python if you forget to compare).
- [ ] **Single read point.** The flag is read once and threaded through, not re-read ad hoc at N sites — future removal touches one place.
- [ ] **Both states tested, in-session, output captured (E2).** One test/exercise with the flag OFF proving old behavior, one with it ON proving new behavior. An E3-only check (it compiles) does not satisfy the gate; a "done" claim without E1/E2 violates N1.
- [ ] **Precedence honored.** The flag is wired through the repo's existing config loader at the right precedence layer — not a bare `getenv` bypassing the mechanism everyone else uses.
- [ ] **Documented where this repo documents flags.** Find that place first: `rg -ni --hidden "environment variable|configuration|feature flag" README* docs/ 2>/dev/null`. If example/env-template files exist (`.env.example`, `values.yaml`, config samples), add it there with the safe default.
- [ ] **Removal plan noted.** In the PR/commit description: what condition retires the flag (feature GA'd / experiment concluded) and roughly when. Flags without removal plans become the dead candidates the previous section hunts.
- [ ] **Deploy-side setters updated deliberately.** If prod should flip it, that is a separate, explicitly authorized step (touching deploy config is outward-facing — N6/Class 3 discipline applies to the rollout).

## Flag drift: why this map expires

Config drifts faster than code: deploy repos change without touching app code, flag services flip states with no commit at all, and example files rot. Treat any inventory older than the last deploy-config change as stale. Consequently this skill's own outputs are volatile by construction — **re-run the axis sweeps (the greps in "Finding every instance") before acting on a previously built inventory**, and diff against the old table rather than trusting it (N10 after context loss: re-verify from the repo, not from memory).

## Provenance and maintenance

- Evidence classes: search patterns and outputs quoted above — verified by running them on 2026-07-05 against a synthetic fixture (ripgrep 14.1.0, Python 3.11.15; fixture reproduced in `references/pattern-test-fixture.md`) [craft, verified-on-fixture]. Taxonomy, heuristics, checklist — [craft]. Change classes, non-negotiables (N1, N3, N6, N8, N10), evidence levels E1–E3 — cited from `codofable-change-control` and `codofable-validation-and-qa` [repo]. dotenv/viper precedence remarks — behavior of those libraries as of the authoring date; verify against the target repo's pinned versions [craft, unverified-here since neither library is installed in this repo].
- This repository itself has no application config surface as of 2026-07-05 (from the repo root, `rg -n --hidden "process\.env|os\.environ|getenv" .` outside `.claude/skills/` returns nothing) — every command here is a pattern for TARGET repos. [repo]
- Re-verification one-liners:
  - Patterns still work: rebuild the fixture from `references/pattern-test-fixture.md`, re-run each block, compare to the recorded outputs.
  - ripgrep hidden-file default unchanged: `rg --help | rg -A1 -- --hidden`
  - Inventory freshness in a target repo: re-run the seven axis sweeps and `git log -n 5 -- <deploy/CI paths>` to see if setters moved since the map was built.
