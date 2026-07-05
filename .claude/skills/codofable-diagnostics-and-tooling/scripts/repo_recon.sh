#!/bin/sh
# repo_recon.sh — fast reconnaissance of an unknown repository.
#
# Usage:   repo_recon.sh [REPO_PATH]
#          REPO_PATH defaults to the current directory.
#
# Prints, in fixed sections (a section prints "(none found)" if empty):
#   MANIFESTS      — ecosystem manifests (package.json, pyproject.toml, Cargo.toml, ...)
#   LOCKFILES      — dependency lockfiles (tells you WHICH installer the project expects)
#   VERSION PINS   — version-manager pins (.nvmrc, .python-version, .tool-versions, ...)
#   CI CONFIG      — CI pipeline definitions (GitHub Actions, GitLab, CircleCI, ...)
#   AGENT CONFIG   — CLAUDE.md / .claude presence (skills, agent settings)
#   LIKELY COMMANDS— candidate install/build/test commands inferred from the above.
#                    These are CANDIDATES: confirm against README/CI before trusting.
#
# Exit:    0 on success, 2 if REPO_PATH is not a directory.
# Dependencies: POSIX sh, find, grep, sed, awk (coreutils only). Read-only: writes nothing.

set -u

REPO="${1:-.}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: not a directory: $REPO" >&2
    echo "Usage: $0 [REPO_PATH]" >&2
    exit 2
fi

# Search top 2 levels only: deep hits are usually vendored deps, not the project's own config.
scan() {
    # $1 = filename pattern
    find "$REPO" -maxdepth 2 \
        -path '*/node_modules' -prune -o \
        -path '*/.git' -prune -o \
        -name "$1" -print 2>/dev/null | sed "s|^$REPO/||" | sort
}

section() {
    echo ""
    echo "== $1 =="
    if [ -z "$2" ]; then
        echo "  (none found)"
    else
        printf '%s\n' "$2" | sed 's/^/  /'
    fi
}

hits=""
collect() {
    for pat in "$@"; do
        found=$(scan "$pat")
        [ -n "$found" ] && hits="${hits}${hits:+
}${found}"
    done
    printf '%s' "$hits"
}

echo "repo_recon: $REPO"

hits=""; manifests=$(collect \
    package.json pyproject.toml setup.py setup.cfg requirements*.txt Pipfile \
    Cargo.toml go.mod pom.xml build.gradle build.gradle.kts settings.gradle \
    Gemfile composer.json mix.exs Makefile CMakeLists.txt meson.build \
    '*.csproj' '*.sln' Dockerfile docker-compose.yml docker-compose.yaml pubspec.yaml)
section "MANIFESTS" "$manifests"

hits=""; locks=$(collect \
    package-lock.json yarn.lock pnpm-lock.yaml bun.lockb bun.lock \
    poetry.lock uv.lock Pipfile.lock Cargo.lock Gemfile.lock composer.lock \
    go.sum mix.lock flake.lock)
section "LOCKFILES" "$locks"

hits=""; pins=$(collect \
    .nvmrc .node-version .python-version .ruby-version .tool-versions \
    .terraform-version rust-toolchain rust-toolchain.toml .go-version \
    .java-version .sdkmanrc runtime.txt .envrc)
section "VERSION PINS" "$pins"

ci=""
for f in .gitlab-ci.yml .circleci/config.yml Jenkinsfile .travis.yml \
         azure-pipelines.yml .buildkite/pipeline.yml cloudbuild.yaml .drone.yml; do
    [ -e "$REPO/$f" ] && ci="${ci}${ci:+
}${f}"
done
if [ -d "$REPO/.github/workflows" ]; then
    wf=$(find "$REPO/.github/workflows" -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sed "s|^$REPO/||" | sort)
    [ -n "$wf" ] && ci="${ci}${ci:+
}${wf}"
fi
section "CI CONFIG" "$ci"

agent=""
[ -f "$REPO/CLAUDE.md" ] && agent="CLAUDE.md"
if [ -d "$REPO/.claude" ]; then
    agent="${agent}${agent:+
}.claude/"
    [ -d "$REPO/.claude/skills" ] && \
        agent="${agent}
.claude/skills/ ($(find "$REPO/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') skill dir(s))"
fi
section "AGENT CONFIG" "$agent"

# ---- Likely commands (heuristic; confirm against README/CI before running) ----
cmds=""
add() { cmds="${cmds}${cmds:+
}$(printf '%-33s # %s' "$1" "$2")"; }

case "$manifests" in *package.json*)
    case "$locks" in
        *pnpm-lock.yaml*) add "pnpm install --frozen-lockfile" "install (pnpm lockfile present)";;
        *yarn.lock*)      add "yarn install --frozen-lockfile" "install (yarn lockfile present)";;
        *bun.lock*)       add "bun install" "install (bun lockfile present)";;
        *package-lock*)   add "npm ci" "install (npm lockfile present)";;
        *)                add "npm install" "install (no lockfile found)";;
    esac
    # Pull real script names out of package.json rather than guessing.
    pj=$(printf '%s\n' "$manifests" | grep -m1 'package\.json$' || true)
    if [ -n "$pj" ] && [ -f "$REPO/$pj" ]; then
        scripts=$(awk '/"scripts"[ \t]*:/{f=1;next} f&&/}/{exit} f' "$REPO/$pj" \
                  | sed -n 's/^[ \t]*"\([^"]*\)".*/\1/p' | head -8 | tr '\n' ' ')
        [ -n "$scripts" ] && add "npm run <script>" "scripts in $pj: $scripts"
    fi
;; esac

case "$manifests" in *pyproject.toml*)
    case "$locks" in
        *uv.lock*)     add "uv sync" "install (uv lockfile present)";;
        *poetry.lock*) add "poetry install" "install (poetry lockfile present)";;
        *)             add "pip install -e ." "install (pyproject.toml, no py lockfile)";;
    esac
    add "pytest" "test (convention; check pyproject [tool.pytest])"
;; esac
case "$manifests" in *requirements.txt*)
    add "pip install -r requirements.txt" "install"
;; esac
case "$manifests" in *Cargo.toml*)
    add "cargo build" "build"
    add "cargo test" "test"
;; esac
case "$manifests" in *go.mod*)
    add "go build ./..." "build"
    add "go test ./..." "test"
;; esac
case "$manifests" in *pom.xml*)
    add "mvn -B verify" "build+test"
;; esac
case "$manifests" in *build.gradle*)
    add "./gradlew build" "build+test (use wrapper if present)"
;; esac
case "$manifests" in *Gemfile*)
    add "bundle install && bundle exec rake test" "install+test"
;; esac
case "$manifests" in *mix.exs*)
    add "mix deps.get && mix test" "install+test"
;; esac
case "$manifests" in *Makefile*)
    targets=$(grep -E '^[a-zA-Z0-9_.-]+:([^=]|$)' "$REPO/Makefile" 2>/dev/null \
              | sed 's/:.*//' | grep -Ev '^\.' | head -8 | tr '\n' ' ')
    add "make <target>" "Makefile targets: ${targets:-<none parsed>}"
;; esac

section "LIKELY COMMANDS (candidates — verify against README/CI before trusting)" "$cmds"

echo ""
exit 0
