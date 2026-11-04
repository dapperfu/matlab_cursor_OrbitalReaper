# Validation report

MATLAB R2025b ran these checks on 2026-11-04. The contest page was fetched the same day. The prohibited list is `docs/PROHIBITED_FUNCTIONS.md`.

## Compliance

| Check | Result |
| --- | --- |
| `submission/orbitalReaper.m` characters | 9978 |
| UTF-8 bytes | 9978 |
| CR-stripped length | 9978 |
| At most 10000 characters | Pass |
| Internal target of 9000 | Not met, by 978 |
| Bang operator | Absent |
| Prohibited identifiers, whole word, including comments | None |
| External images, toolboxes, or other source files | None |
| `orbitalReaper(4, 7, 3)` figure loop | Returned |
| Frame timing | `drawnow`, `tic`, `toc`. No `pause` |

The development tests use `addpath`, `regexp`, and the unit-test framework. Those calls are not in the contest file.

## Tests

`runtests` on `tests/` reported 36 passed and 0 failed:

- `testInput` 9
- `testPhysics` 7
- `testDeterminism` 5
- `testGameplay` 8
- `testSubmission` 7

`testSubmission` checks the character cap, the prohibited list, a seed-7 scripted clear, a 400-step hold that never fires, taps under 0.12 seconds that never fire, a four-frame figure, and an exact match against the development simulation.

## Scripted level 1

Seed 7, schedule `[1 1; 0 1142; 1 33; 0 1; 1 33; 0 20]`:

- Development and submission both reach mode 2 (level clear).
- Score 2156, one kill, hull still at 100.
- Player position and fuel match. Difference in x and y is 0.

## Automated players

Development only. Seeds 1 through 8, 32 seconds, level 1. Names in order: random, tap, hold, rhythm, heuristic.

| Policy | Score | Kills | HP sum | Fired | Hits | Clears |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Random | 2445 | 1 | 476 | 156 | 11 | 1 |
| Rapid tap | 0 | 0 | 526 | 0 | 0 | 0 |
| Permanent hold | 0 | 0 | 380 | 0 | 0 | 0 |
| Fixed rhythm | 5333 | 3 | 526 | 224 | 17 | 2 |
| Heuristic | 11078 | 6 | 768 | 17 | 14 | 4 |

Heuristic accuracy is 14/17. Rhythm accuracy is 17/224. Taps are shorter than the 0.12 second minimum, so they never fire. A hold never releases, so it never fires, and the tank empties. Seeds 1, 4, 5, and 6 give the heuristic no lock above 0.72 inside 32 seconds, so it scores 0 on those seeds. That is not a claim that every seed is winnable.

## Physics choice

Symplectic Euler, `dt = 1/60`, `mu = 0.40`, circular start at `r = 1.60`. Thrust is radial, acceleration 0.25, `kTan = 0`. The thrust-law experiment chose radial over blends because a 0.6 second burn raises apoapsis, lowers periapsis, and shifts phase. A 180 second coast drifted 0.00419 in radius under symplectic Euler. Fuel burns at 0.40 per second and refills at 0.16 per second only while SPACE is up.

## Known limits

- The 9000-character target was not met. The contest limit was.
- The contest file drops the plume, lock line, hit flash, and extra orbit rings. Enemy silhouettes are marker shapes. Telegraph timing still runs; the contest draw does not recolor the warning.
- There is no focus-lost callback. The watchdog can treat a long stall as a release and will not fire on that release.
- The catch-up cap is 5 steps, so a stall shortens game time relative to the wall clock. Edges are latched, so a press is not dropped.
- A seed is reproducible. It is not a solvability proof. Some seeds have no good shot inside half a minute.
- A heavy burst that does not fit in the 16 enemy-shot slots drops the extra rounds.
- No audio.
- `git config` was not changed. Commit identity is supplied with environment variables. There is no `upstream` remote, so an upstream merge was not run.
