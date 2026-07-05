#!/bin/sh
# validate_skills.sh — mechanical invariant checker for the codofable skill library.
#
# Usage:   validate_skills.sh [SKILLS_ROOT]
#          SKILLS_ROOT defaults to .claude/skills relative to the current directory.
#
# Checks, per skill directory (invariants per codofable-architecture-contract):
#   1. SKILL.md exists.
#   2. Frontmatter: file opens with `---` on line 1 and has a closing `---`.
#   3. Frontmatter contains `name:` and `description:` keys.
#   4. `name:` value equals the directory name exactly.
#   5. `description:` value is non-empty and <= 1024 characters.
#   6. Required section headings present (case-insensitive prefix match):
#        ## When to use   ## When NOT to use   ## Provenance
#   7. Line count: > 500 lines = FAIL; > 450 lines = WARN (not a failure).
#
# Output:  one PASS/WARN/FAIL row per skill, then a summary line.
# Exit:    0 if no FAIL rows; 1 if any skill FAILs; 2 on usage error.
#
# Dependencies: POSIX sh, awk, grep, wc, sed (coreutils only).

set -u

ROOT="${1:-.claude/skills}"

if [ ! -d "$ROOT" ]; then
    echo "ERROR: skills root not found: $ROOT" >&2
    echo "Usage: $0 [SKILLS_ROOT]" >&2
    exit 2
fi

MAX_DESC=1024
FAIL_LINES=500
WARN_LINES=450

total=0
passed=0
warned=0
failed=0

printf '%-45s %-6s %s\n' "SKILL" "STATUS" "DETAIL"
printf '%-45s %-6s %s\n' "-----" "------" "------"

for dir in "$ROOT"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    total=$((total + 1))
    problems=""
    warnings=""
    md="$dir/SKILL.md"

    if [ ! -f "$md" ]; then
        problems="SKILL.md missing"
    else
        # --- frontmatter structure ---
        first=$(head -n 1 "$md")
        if [ "$first" != "---" ]; then
            problems="${problems}; file must open with --- on line 1"
        else
            # frontmatter = lines between line 1 `---` and the next `---`
            fm=$(awk 'NR==1 {next} /^---[ \t]*$/ {exit} {print}' "$md")
            if ! awk 'NR>1 && /^---[ \t]*$/ {found=1; exit} END {exit !found}' "$md"; then
                problems="${problems}; frontmatter has no closing ---"
            fi

            fm_name=$(printf '%s\n' "$fm" | sed -n 's/^name:[ \t]*//p' | head -n 1 | sed 's/[ \t]*$//')
            fm_desc=$(printf '%s\n' "$fm" | sed -n 's/^description:[ \t]*//p' | head -n 1 | sed 's/[ \t]*$//')

            if ! printf '%s\n' "$fm" | grep -q '^name:'; then
                problems="${problems}; frontmatter missing name:"
            elif [ "$fm_name" != "$name" ]; then
                problems="${problems}; name '$fm_name' != dir '$name'"
            fi

            if ! printf '%s\n' "$fm" | grep -q '^description:'; then
                problems="${problems}; frontmatter missing description:"
            elif [ -z "$fm_desc" ]; then
                problems="${problems}; description empty"
            else
                dlen=${#fm_desc}
                if [ "$dlen" -gt "$MAX_DESC" ]; then
                    problems="${problems}; description ${dlen} chars > ${MAX_DESC}"
                fi
            fi
        fi

        # --- required headings (case-insensitive prefix match) ---
        grep -qi '^## *when to use'     "$md" || problems="${problems}; missing '## When to use' heading"
        grep -qi '^## *when not to use' "$md" || problems="${problems}; missing '## When NOT to use' heading"
        grep -qi '^## *provenance'      "$md" || problems="${problems}; missing '## Provenance' heading"

        # --- length ---
        lines=$(wc -l < "$md")
        if [ "$lines" -gt "$FAIL_LINES" ]; then
            problems="${problems}; ${lines} lines > ${FAIL_LINES}"
        elif [ "$lines" -gt "$WARN_LINES" ]; then
            warnings="${warnings}; ${lines} lines > ${WARN_LINES} (soft limit)"
        fi
    fi

    problems=${problems#"; "}
    warnings=${warnings#"; "}

    if [ -n "$problems" ]; then
        failed=$((failed + 1))
        printf '%-45s %-6s %s\n' "$name" "FAIL" "$problems"
    elif [ -n "$warnings" ]; then
        warned=$((warned + 1))
        printf '%-45s %-6s %s\n' "$name" "WARN" "$warnings"
    else
        passed=$((passed + 1))
        printf '%-45s %-6s %s\n' "$name" "PASS" "ok"
    fi
done

echo ""
echo "Summary: $total skill(s) checked — $passed PASS, $warned WARN, $failed FAIL (root: $ROOT)"

if [ "$total" -eq 0 ]; then
    echo "ERROR: no skill directories found under $ROOT" >&2
    exit 2
fi

[ "$failed" -eq 0 ] || exit 1
exit 0
