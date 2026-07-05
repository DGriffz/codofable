# Rehearsed transcripts for the Gate B and refutation git patterns

Every command pattern in SKILL.md's Gate B (failed-before check) and the harness-mutation refutation was executed end-to-end on 2026-07-05 in a throwaway scratch repository (Linux, git 2.x, Python 3). Output below is pasted from the actual runs, trimmed only of scratch-directory absolute paths (shown as `.../rehearsal/...`). Evidence class: [craft] rehearsal — the commands and observed behavior are real; the toy repo is illustrative, not this project's history.

Scratch repo setup: one commit containing a deliberately buggy `calc.py` (`add` returns `a - b`), then an uncommitted fix (`a + b`) plus a new untracked `test_calc.py` asserting `add(2, 3) == 5` — the typical "agent just fixed a bug" working-tree state.

```
--- git status after fix (uncommitted) ---
 M calc.py
?? test_calc.py
--- run test on FINAL (fixed) state ---
test_add PASSED
exit=0
```

## Pattern B-2: stash round-trip (fix is UNCOMMITTED)

```
$ git stash push -m "verify-failed-before" -- calc.py
Saved working directory and index state On main: verify-failed-before

$ git status --porcelain          # tracked fix shelved; untracked test kept
?? __pycache__/
?? test_calc.py
$ grep -n "return" calc.py        # pre-fix code is back
2:    return a - b  # BUG: subtracts

$ python3 test_calc.py            # EXPECT failure at pre-fix state
Traceback (most recent call last):
  File ".../rehearsal/proj/test_calc.py", line 6, in <module>
    test_add()
  File ".../rehearsal/proj/test_calc.py", line 3, in test_add
    assert add(2, 3) == 5
           ^^^^^^^^^^^^^^
AssertionError
exit=1

$ git stash pop                   # restore the fix — mandatory
...
Dropped refs/stash@{0} (25cf5dd023d72a8ff8206f5f294c391f74ca5eff)

$ python3 test_calc.py            # re-run on restored FINAL state
test_add PASSED
exit=0
$ git status --porcelain          # tree matches pre-Gate-B state
 M calc.py
?? __pycache__/
?? test_calc.py
```

Notes observed during rehearsal:

- `git stash push -- <pathspec>` shelves only the named tracked files; the untracked test file stays put, which is exactly what lets the new test run against old code. This is why the pathspec form is used, not bare `git stash`.
- Interpreter/build caches can appear (`__pycache__/` above). Harmless here, but this is why Gate D reads real `git status` output instead of trusting memory.
- Net effect on history: none. No refs moved; the stash was created and dropped. Class R.

## Pattern B-1: worktree (fix is COMMITTED)

Continuing in the same scratch repo after committing the fix + test (`fix add + regression test` on top of `buggy add`):

```
$ git log --oneline
23a6cb3 fix add + regression test
c44c747 buggy add

$ git worktree add --detach ../prefix-check HEAD~1
Preparing worktree (detached HEAD c44c747)
HEAD is now at c44c747 buggy add

$ cp test_calc.py ../prefix-check/        # only the NEW test goes back in time

$ (cd ../prefix-check && python3 test_calc.py); echo "exit=$?"
Traceback (most recent call last):
  File ".../rehearsal/prefix-check/test_calc.py", line 6, in <module>
    test_add()
  File ".../rehearsal/prefix-check/test_calc.py", line 3, in test_add
    assert add(2, 3) == 5
           ^^^^^^^^^^^^^^
AssertionError
exit=1

$ git worktree remove --force ../prefix-check
$ git worktree list                        # only the main worktree remains
.../rehearsal/proj  23a6cb3 [main]
$ git status --porcelain                   # main tree untouched
?? __pycache__/

$ python3 test_calc.py; echo "exit=$?"     # final-state run — the citable one
test_add PASSED
exit=0
```

Notes observed during rehearsal:

- `--detach` avoids creating or moving any branch; the worktree checks out the commit directly. `--force` on remove is needed because the copied test file makes the worktree dirty.
- The main working tree's status is byte-identical before and after. Class R.

## Refutation: harness mutation check (prove the test CAN fail)

Used for the "test passes vacuously" refutation in Phase 3 and as the obligation for Solution Menu option 1 (new harness must be seen red once).

```
$ sed -i 's/== 5/== 999/' test_calc.py     # deliberate wrong assertion
$ python3 test_calc.py; echo "exit=$?"
...
    assert add(2, 3) == 999
           ^^^^^^^^^^^^^^^^
AssertionError
exit=1                                      # RED observed — harness is live
$ git checkout -- test_calc.py              # revert the mutation immediately
$ python3 test_calc.py; echo "exit=$?"
test_add PASSED
exit=0
```

Note: in the rehearsal the mutation was reverted with `git checkout -- <file>` because the test was committed there. If your test file is uncommitted, revert the mutation by re-editing it back (and re-run to confirm green). Either way the mutation must not survive into the final state — Gate A would void your evidence if it did.

## Side-effect sweep commands (Gate D), as run

```
$ git status --porcelain=v1
?? __pycache__/
$ git diff --stat HEAD
(empty — no unstaged changes to tracked files at that point)
```

## Provenance

Rehearsed 2026-07-05 in a scratch repo under the session scratchpad (not part of this repository). To re-rehearse from scratch anywhere: create a temp dir, `git init`, commit a buggy function, add an uncommitted fix + untracked test, then follow the transcripts above; every EXPECTED observation should reproduce modulo hashes and paths.
