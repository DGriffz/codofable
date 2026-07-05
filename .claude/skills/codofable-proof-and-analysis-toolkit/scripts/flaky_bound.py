#!/usr/bin/env python3
"""flaky_bound.py — one-sided 95% bounds for a flaky test modeled as Bernoulli.

Usage:
  python3 flaky_bound.py passes N     # after N consecutive passes, upper bound on p
  python3 flaky_bound.py need P       # consecutive passes needed to claim p < P at 95%

Model: each run fails independently with fixed probability p. If a test passed
N consecutive runs, the largest p still consistent with that at the 5% level
satisfies (1-p)^N = 0.05, i.e. p_upper = 1 - 0.05**(1/N) (approx 3/N for N >= 30,
the "rule of three"). To claim p < P at 95%, need the smallest N with
(1-P)^N <= 0.05, i.e. N = ceil(ln 0.05 / ln(1-P)).
"""
import math
import sys


def main() -> None:
    if len(sys.argv) != 3 or sys.argv[1] not in ("passes", "need"):
        sys.exit(__doc__)
    mode, val = sys.argv[1], sys.argv[2]
    if mode == "passes":
        n = int(val)
        if n < 1:
            sys.exit("N must be >= 1")
        exact = 1 - 0.05 ** (1 / n)
        print(f"after {n} consecutive passes: p <= {exact:.4f} "
              f"({exact:.1%}) at 95% confidence; rule of three: 3/{n} = {3 / n:.4f}")
    else:
        p = float(val)
        if not 0 < p < 1:
            sys.exit("P must be in (0, 1)")
        n = math.ceil(math.log(0.05) / math.log(1 - p))
        print(f"to claim p < {p} at 95% confidence: need {n} consecutive passes "
              f"(rule of three approximation: {math.ceil(3 / p)})")


if __name__ == "__main__":
    main()
