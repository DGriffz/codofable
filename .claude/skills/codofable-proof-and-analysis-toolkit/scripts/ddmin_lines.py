#!/usr/bin/env python3
"""ddmin_lines.py — line-granularity delta debugging (Zeller's ddmin, by halves).

Usage: python3 ddmin_lines.py <input-file> -- <test-cmd> [args...]

Contract: <test-cmd> is run with one argument (a path to a candidate input).
It must exit NON-ZERO when the failure of interest is present ("interesting")
and ZERO when it is absent. The reducer only ever keeps a candidate that
still fails — that is the invariant: every accepted removal preserves the
failure. Output: the minimized input is written to <input-file>.min and every
trial is logged to stderr.
"""
import subprocess, sys, tempfile, os

def interesting(lines, cmd, log_tag):
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
        f.writelines(lines)
        path = f.name
    try:
        r = subprocess.run(cmd + [path], capture_output=True)
        fails = r.returncode != 0
        print(f"  trial {log_tag}: {len(lines)} lines -> "
              f"{'STILL FAILS (keep)' if fails else 'passes (discard trial)'}",
              file=sys.stderr)
        return fails
    finally:
        os.unlink(path)

def ddmin(lines, cmd):
    n = 2
    step = 0
    while len(lines) >= 2:
        chunk = max(1, len(lines) // n)
        subsets = [lines[i:i + chunk] for i in range(0, len(lines), chunk)]
        reduced = False
        for i, sub in enumerate(subsets):
            step += 1
            # try the subset alone
            if interesting(sub, cmd, f"{step}a(subset {i+1}/{len(subsets)})"):
                lines, n, reduced = sub, 2, True
                break
            # try its complement
            comp = [l for j, s in enumerate(subsets) if j != i for l in s]
            step += 1
            if comp and interesting(comp, cmd, f"{step}b(complement of {i+1})"):
                lines, n, reduced = comp, max(2, n - 1), True
                break
        if not reduced:
            if n >= len(lines):
                break
            n = min(len(lines), n * 2)
    return lines

def main():
    if "--" not in sys.argv:
        sys.exit(__doc__)
    sep = sys.argv.index("--")
    infile, cmd = sys.argv[1], sys.argv[sep + 1:]
    lines = open(infile).readlines()
    if not interesting(lines, cmd, "0(sanity: full input)"):
        sys.exit("FATAL: full input does not fail — nothing to minimize (N5).")
    result = ddmin(lines, cmd)
    out = infile + ".min"
    open(out, "w").writelines(result)
    print(f"minimized: {len(lines)} -> {len(result)} lines, written to {out}",
          file=sys.stderr)

if __name__ == "__main__":
    main()
