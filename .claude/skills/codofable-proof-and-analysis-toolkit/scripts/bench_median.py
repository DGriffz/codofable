#!/usr/bin/env python3
"""bench_median.py — time a command with warmup and report median + spread.

Usage: python3 bench_median.py [--warmup W] [--reps N] -- <cmd> [args...]
Defaults: --warmup 3 --reps 20. Prints every sample (ms), then
min / median / p90 / max / mean and the max/min spread ratio.
Non-zero exit of the measured command aborts the benchmark (you would be
timing a failure, not the behavior).
"""
import argparse
import statistics
import subprocess
import sys
import time


def main() -> None:
    if "--" not in sys.argv:
        sys.exit(__doc__)
    sep = sys.argv.index("--")
    ap = argparse.ArgumentParser()
    ap.add_argument("--warmup", type=int, default=3)
    ap.add_argument("--reps", type=int, default=20)
    opts = ap.parse_args(sys.argv[1:sep])
    cmd = sys.argv[sep + 1:]
    if not cmd:
        sys.exit(__doc__)
    for _ in range(opts.warmup):
        subprocess.run(cmd, check=True, capture_output=True)
    samples = []
    for _ in range(opts.reps):
        t0 = time.perf_counter()
        subprocess.run(cmd, check=True, capture_output=True)
        samples.append((time.perf_counter() - t0) * 1000)
    s = sorted(samples)
    p90 = s[min(len(s) - 1, int(round(0.9 * len(s))) - 1)]
    print("samples_ms:", " ".join(f"{x:.1f}" for x in samples))
    print(f"min={s[0]:.1f}  median={statistics.median(s):.1f}  p90={p90:.1f}  "
          f"max={s[-1]:.1f}  mean={statistics.mean(s):.1f}")
    print(f"spread: max/min = {s[-1] / s[0]:.2f}x")


if __name__ == "__main__":
    main()
