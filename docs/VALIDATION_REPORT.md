# Validation report

MATLAB R2025b ran these checks on 2026-11-04. The contest page was fetched the same day. The prohibited list is `docs/PROHIBITED_FUNCTIONS.md`.

## Compliance

| Check | Result |
| --- | --- |
| `submission/orbitalReaper.m` characters | 9905 |
| UTF-8 bytes | 9905 |
| CR-stripped length | 9905 |
| At most 10000 characters | Pass |
| Internal target of 9000 | Not met, by 905 |
| Bang operator | Absent |
| Prohibited identifiers, whole word, including comments | None |
| External images, toolboxes, or other source files | None |
| `orbitalReaper(4, 7, 3)` figure loop | Returned |
| Frame timing | `drawnow`, `tic`, `toc`. No `pause` |

The development tests use `addpath`, `regexp`, and the unit-test framework. Those calls are not in the contest file.

## Tests

`runtests` on `tests/` reported 40 passed and 0 failed after the first-order damage change:

- `testInput` 10
- `testPhysics` 8
- `testDeterminism` 5
- `testGameplay` 8
- `testSubmission` 9

`testSubmission` checks the character cap, the prohibited list, a seed-7 scripted clear, a 400-step hold that never fires, one release after that hold, eight short taps that fire once each, damage at 0.5 s and 2.0 s, a four-frame figure, and an exact match against the development simulation.

## Scripted level 1

Seed 7, schedule `[1 1; 0 1142; 1 33; 0 1; 1 33; 0 20]`:

- Development and submission both reach mode 2 (level clear).
- Score 2148, one kill, hull still at 100, two shots fired.
- Player position and fuel match. Difference in x and y is 0.

The same schedule still clears. The score moved from 2156 because each shot now uses `6 * (1 - exp(-t))` with `tau = 1` s instead of the old peaked polynomial, and the shot spends `0.10 + 0.28*u` fuel.

## Automated players

Development only. Seed 7, 32 seconds, level 1, re-run after the damage change. Names in order: random, tap, hold, rhythm, heuristic.

| Policy | Score | Kills | HP | Fired | Hits | Clears |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Random | 4963 | 4 | 52 | 19 | 5 | 2 |
| Rapid tap | 0 | 0 | 68 | 192 | 0 | 0 |
| Permanent hold | 0 | 0 | 34 | 0 | 0 | 0 |
| Fixed rhythm | 3085 | 2 | 68 | 27 | 4 | 1 |
| Heuristic | 2140 | 1 | 82 | 2 | 2 | 1 |

The heuristic still beats a permanent hold (2140 to 0) and a rapid tap (0). Its two shots both hit. The 0.6 s rhythm and the random policy score higher on this seed because every release now fires and repeated medium holds add damage. There is no anti-spam cooldown. The earlier eight-seed table was measured with the peaked damage curve and is not this law.

## Physics choice

Symplectic Euler, `dt = 1/60`, `mu = 0.40`, circular start at `r = 1.60`. Thrust is radial, acceleration 0.25, `kTan = 0`. The thrust-law experiment chose radial over blends because a 0.6 second burn raises apoapsis, lowers periapsis, and shifts phase. A 180 second coast drifted 0.00419 in radius under symplectic Euler. Fuel burns at 0.40 per second and refills at 0.16 per second only while SPACE is up.

Weapon damage of the single release shot is `6 * (1 - exp(-t / 1))`, where `t` is the hold in game seconds. The old rule refused to fire when the hold was under 0.12 s, and its damage peaked near a charge of 0.63. That gate and that polynomial are gone. A short tap fires a weak shot. Holding does not fire again. Muzzle speed is at least 0.40, so the projectile is never stopped for lack of a fire period.

## Known limits

- The 9000-character target was not met. The contest limit was. The file is 9905 characters.
- The response `1-exp(-t/tau)` is concave. Split holds can add more damage than one hold of the same total time when the shots hit. Rapid taps on seed 7 did not hit. A permanent hold still never fires.
- Charge follows hold time after the fuel tank is empty. Thrust does not.
- The contest file drops the plume, lock line, hit flash, and extra orbit rings. Enemy silhouettes are marker shapes. Telegraph timing still runs; the contest draw does not recolor the warning.
- There is no focus-lost callback. The watchdog can treat a long stall as a release and will not fire on that release.
- The catch-up cap is 5 steps, so a stall shortens game time relative to the wall clock. Edges are latched, so a press is not dropped.
- A seed is reproducible. It is not a solvability proof. Some seeds have no good shot inside half a minute.
- A heavy burst that does not fit in the 16 enemy-shot slots drops the extra rounds.
- No audio.
- `git config` was not changed. Commit identity is supplied with environment variables. There is no `upstream` remote, so an upstream merge was not run.
