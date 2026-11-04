# Orbital Reaper Implementation Plan

Project name: `matlab_cursor_OrbitalReaper`. Game title: Orbital Reaper.

This plan is the project deliverable for the MATLAB Central 25th Anniversary One-button Game Mini Hack. It is written before the game modules. Implementation follows the phases below. Development code stays readable and modular. Only `submission/orbitalReaper.m` counts toward the contest character limit.

## Contest constraints

Source: MathWorks 25th Anniversary contest rules, One-button Game Mini Hack, retrieved 2026-11-04.

- One gameplay button. This game uses SPACE only. Opening and focusing the figure is setup, not a second control.
- Submitted MATLAB source is at most 10,000 characters of complete source text (comments and whitespace included). Internal target is 9,000 characters, leaving about 1,000 characters of margin. UTF-8 byte size is recorded separately.
- The entry is one self-contained function file with local functions. No images, toolboxes, config files, or other source files are required to play.
- No prohibited function and no bang (`!`) operator. The official list is stored in `docs/PROHIBITED_FUNCTIONS.md`. Notable traps for a game loop: `pause`, `error`, `delete`, `input`, `uicontrol`, `eval`, `feval`, `str2func`, `load`, `save`, `fopen`, `imread`, `addpath`, `run`, `regexp`, `audio`/`sound`/`beep`, `web`/`webread`, Java, Python, and .NET.
- `drawnow` is allowed. The frame loop uses `drawnow` plus measured elapsed time. Physics uses fixed `dt = 1/60` with at most 5 catch-up steps per frame.
- Base MATLAB only. Verified host: MATLAB R2025b (25.2). Java is not enabled in this installation, so Java focus hooks are unavailable even before the contest ban.

There are no StrictDoc `.sdoc` requirements in this repository. Commit messages omit the `Requirements:` section.

## Resolved design questions

The design brief already fixes the product. These questions record edge cases and the choice used in code.

1. Radial-only thrust versus a radial/tangential blend? A MATLAB experiment (`experiments/experimentThrustLaw.m`) measures whether a finite radial burn can raise apoapsis, lower periapsis, and shift phase relative to a coast. If it can, thrust is radial (`kTan = 0`). If it cannot, thrust direction is `normalize(radial_hat + kTan * tangential_hat)` with the smallest tested `kTan` that changes semi-major axis and phase in a learnable way. Coasting is how a burn stops adding energy. The chosen law is recorded in the validation report.
2. When does aim update? While SPACE is held, thrust changes the orbit, charge grows, and the aim solution updates from current geometry. Release instant selects the shot. Charge amount selects power. Aim is a lead point inside a cone, not a homing projectile.
3. Do projectiles feel gravity? No. They are short-lived inertial bodies. Enemies stay on orbital trajectories. The player can miss.
4. SPACE held across a mode change? The press that leaves Title, Level Clear, or Game Over is consumed as the menu action. Gameplay then ignores SPACE until a release, and the next new press edge is the first real press. That press does not fire a charged shot.
5. Focus lost while thrusting? Thrust clears, charge is discarded, and no shot is fired. MATLAB R2025b figures expose `WindowKeyPressFcn` and `WindowKeyReleaseFcn` and do not expose a focus-lost callback. Recovery is a watchdog: after key-repeat has been observed, a silence longer than 0.22 s clears the held key; before the first repeat, silence longer than 1.25 s does the same. This covers a missed release when the window loses focus on Windows. Limitation: a figure stall longer than the threshold can also clear thrust.
6. Minimum hold to fire? 0.12 s of game time and a nonzero charge. Shorter presses are taps: little impulse, no shot.
7. What stops infinite hold from being best? Fuel burns only while thrusting and regenerates only while SPACE is released. Empty fuel cuts thrust and stops charge growth. Damage per charge peaks before full charge, and the shot's fuel cost rises with charge. A hold never auto-fires. Releasing is the only way to shoot and the only way to refuel.
8. Default seed versus tests? A no-argument launch derives a seed from `now`. Every simulated world is a pure function of `(seed, level, input schedule)` via an owned LCG. Tests pass explicit seeds. MATLAB global `rng` is not used.
9. Integrator? Symplectic Euler unless a 180 s unthrusted run drifts by more than 3 percent of the initial radius. In that case the experiment switches the ship and enemies to velocity Verlet and the validation report says so.
10. How is keyboard auto-repeat suppressed? `WindowKeyPressFcn` on Windows repeats while SPACE is down. A device state machine counts a press only on the transition into down. Further press callbacks set a repeat flag and do not create press events, shots, or extra timestamps. Release callbacks count once. The feasibility script and `tests/testInput.m` prove this with repeated synthetic callbacks.
11. Entity caps? At most 8 enemies, 16 player projectiles, and 16 enemy projectiles. Graphics objects are created once and updated.
12. What is fair on early levels? Levels 1–5 use a fixed class roster. Angles and interceptor phase come from the seed. Attacks are telegraphed. Shots are unguided. Placement enforces separation from the planet, the player, and other enemies. That is a constraint, not a solvability proof.

## Architecture

Development modules under `dev/` are the readable game. They share one state struct and one step function so tests do not need the figure.

| Module | Responsibility |
| --- | --- |
| `dev/orConst.m` | Tunable parameters. Mechanisms read them; this file is policy. |
| `dev/orLcg.m` | Numerical Recipes LCG, `mod 2^32`, owned state. |
| `dev/orNewGame.m` | Seed plus level to player orbit, roster, and fresh input. |
| `dev/orStep.m` | Mode logic, then one fixed timestep. |
| `dev/orInputDevice.m` | Press/repeat/release latch and focus watchdog. |
| `dev/orCombat.m` | Charge, cone aim, one projectile on a valid release. |
| `dev/orEnemies.m` | Drone, interceptor, and heavy motion and attacks. |
| `dev/orCollide.m` | Swept circle tests, planet, arena, rams. |
| `dev/orRender.m` | Create-once vector scene and HUD. |
| `dev/orbitalReaperDev.m` | `drawnow` loop. |
| `dev/orBots.m` | Scripted and heuristic players. |
| `experiments/` | Feasibility, thrust-law, and level-1 schedule search. |
| `tests/` | MATLAB `functiontests` suites. Not part of the character budget. |
| `submission/orbitalReaper.m` | Self-contained entry. |

Playable development entry, from the repository root on the MATLAB path:

```matlab
addpath('dev');
orbitalReaperDev
```

Contest entry, with only the submission folder required:

```matlab
addpath('submission');
orbitalReaper
```

Headless hooks on the submission (so compliance tests can run that file alone):

- `orbitalReaper` with no arguments plays.
- `orbitalReaper(1, seed, level)` returns a new title state.
- `orbitalReaper(2, state, down)` advances one step. `down` is 0 or 1.
- `orbitalReaper(3, state, schedule)` runs an `N x 2` schedule of `[down, stepCount]`.
- `orbitalReaper(4, seed, nFrames)` runs the real figure loop for `nFrames` frames and closes.

No-argument play is the game. The numeric hooks exist so the packaged file can be smoked without the development tree. They do not add a second gameplay button.

## Character budget

Counts are characters of `submission/orbitalReaper.m` only. Development files are free. Reallocate as the file takes shape. Do not spend input correctness or orbit stability on visuals.

| Region | Target |
| --- | ---: |
| Init, play loop, headless dispatch | 900 |
| Input edges, focus watchdog, mode latch | 750 |
| Physics and fuel | 700 |
| Aim, charge, firing | 900 |
| Enemies and enemy shots | 1100 |
| Level generation | 650 |
| Collision and scoring | 700 |
| Rendering and HUD | 1700 |
| Contingency | 600 |
| Total target | 9000 |
| Hard stop | 10000 |

`dev/orBudget.m` splits the submission on local `function` lines and writes the measured sizes into `docs/CHARACTER_BUDGET.md`.

## Four-event SPACE control

Game time `S.t` advances by `dt` only inside an active-play step. Hold and coast durations are differences of `S.t`, not counts of key-repeat callbacks.

- Event A, press edge. Exactly once per depression: phase goes from Released to Held, `pressTime = S.t`, thrust is enabled, charge starts from 0, and the current aim cone is whatever geometry exists at that instant (it is not frozen).
- Event B, hold duration. Each held step applies thrust if fuel remains, burns fuel, and advances charge by `dt / chargeTime` while fuel remains. A 2.0 s hold is a different impulse and charge from a 0.5 s hold. Holding after the tank is empty applies neither thrust nor further charge.
- Event C, release edge. Exactly once, and only after a held phase: thrust stops, one projectile is spawned if `holdDt >= 0.12` and `charge > 0`, fuel is spent from the charge, charge returns to 0. A second shot cannot occur until a new press edge.
- Event D, coast. Phase is Released. Gravity keeps the orbit. Fuel regenerates. Weapons are idle. Aim and enemies keep moving, so a delayed re-press sees a new geometry and a fuller tank than an immediate re-press.

Input invariants, all tested:

1. One physical press produces one press event.
2. Repeated key-down callbacks during a hold do not produce another press.
3. A hold does not fire. Only the release fires, and only once.
4. One release produces one release event.
5. Different hold durations produce different thrust impulses.
6. Different coast durations produce different later orbital states.
7. Press while already pressed is a no-op.
8. Release while already released is a no-op.
9. Focus-loss recovery clears thrust and does not fire.
10. Restart clears phase, charge, thrust, and old timestamps, and does not fire.

Device callbacks only mutate `down`, `repeatSeen`, and a wall-clock stamp. `orStep` never sees raw repeats. Catch-up still uses the latched `down` flag, so a stalled frame does not invent extra edges. A stall can shorten game time relative to the wall clock because catch-up is capped at 5 steps. Edges are not dropped: the flag stays down until release or the watchdog.

## Game-state machine

`S.mode`: 0 Title, 1 Play, 2 Level clear, 3 Game over.

- Title shows the one-button instruction overlay. A SPACE press edge enters Play for the already generated level. If SPACE is still down, `fresh` stays set until release.
- Play runs the four-event model.
- Level clear freezes the sim and shows the clear line. SPACE builds the next level, keeps score, kills, and hit counts, refills fuel, restores a circular orbit, and requires a fresh press. HP carries over.
- Game over freezes the sim. SPACE builds level 1 of the same seed, clears score and input, and requires a fresh press. It does not fire.
- Restart and level advance both construct state through `orNewGame`, so timestamps and latches cannot leak.

## Physics

Normalized units. Gravity acceleration is `-mu * r / |r|^3`.

Initial circular orbit at radius `r0`: tangential speed `sqrt(mu / r0)`, counter-clockwise. Starting values before the experiment, adjusted if the 180 s run or the thrust survey says so: `mu = 0.40`, `r0 = 1.60`, planet collision radius `0.40`, arena radius `3.20`, ship radius `0.07`.

Integrator, symplectic Euler, applied to the player and to enemies:

```matlab
v = v + a * dt;
p = p + v * dt;
```

Thrust acceleration is `thrustA` along the chosen direction while phase is Held and fuel is positive. Otherwise the only acceleration is gravity. Fuel burn and regen are per second of game time. Projectiles do not use this integrator; they move in straight lines.

The ship must show: persistent orbit, altitude change under thrust, angular-rate change, momentum after thrust ends, collision with the planet, and collision with the outer arena. Cartesian state is the source of truth (`px, py, vx, vy`). Radius and angle are derived for aiming, HUD, and placement.

Boundary hits use a contact latch so HP falls once per contact, not once per frame. High-speed shots use a swept segment test so a projectile cannot tunnel through an enemy in one `dt`.

## Combat

`chargeTime = 1.0` s. Charge saturates at 1. Damage model:

```matlab
dmg = 3.2 * (0.50 * c + 1.85 * c * (1 - c));
```

That expression peaks near `c = 0.63` and is lower at `c = 1`. Muzzle speed is `0.95 + 2.1 * c`. Shot fuel cost is `0.10 + 0.28 * c^2`. A short hold above 0.12 s fires a weak, slow shot. A medium hold is the efficient kill. A full hold spends more fuel for less damage.

Aim, recomputed every play step from live geometry:

- Nose is the velocity unit vector when speed is high enough, otherwise the counter-clockwise tangential unit vector.
- Each living enemy gets one lead estimate: time of flight `distance / muzzle`, predicted point `enemy position + enemy velocity * time`.
- The best target maximizes alignment with the nose minus a small distance penalty.
- If the best alignment is below `0.74`, the shot leaves along the nose and lock quality stays low. The enemy is not on that ray, so the player misses.
- If alignment is inside the cone, the shot direction is the lead unit vector. It is still unguided. Releasing late, or shooting an interceptor that is thrusting, misses.

Firing rule: projectile velocity = ship velocity + muzzle * fire direction. Enemies lose HP only when the swept segment meets their radius.

## Enemies

Deterministic given seed and level. Simple state, not a planner.

- Orbital Drone (class 1). Gravity only, spawned on a circular orbit, low HP, no weapon. Teaches interception.
- Interceptor (class 2). Limited radial and tangential acceleration toward the player's current orbital radius and a circular tangential speed. Telegraphed shot at a one-step lead of the player. The shot is unguided and slow enough that a thrust during the telegraph changes the intercept.
- Heavy Defense Platform (class 3). Slow orbit with a spring toward its home radius. High HP. Periodic telegraphed radial burst that does not home.

Telegraph: the enemy's cooldown below 0.70 s raises a warning flag. Rendering shows that flag before shots exist. Caps apply if a burst does not fit in the projectile table; extra shots are dropped rather than allocated.

## Levels and difficulty

LCG seed for a level:

```matlab
s = mod(seed * 10007 + level * 97 + 12345, 4294967296);
```

Roster (classes and home radii are fixed; angles come from the LCG):

| Level | Lesson | Roster |
| --- | --- | --- |
| 1 | One slow drone, generous time | 1 drone at r = 2.05 |
| 2 | Several drones, timing | 3 drones at r = 1.20, 1.80, 2.40 |
| 3 | Different altitudes, thrust to reposition | 4 drones at r = 1.05, 1.45, 2.10, 2.60 |
| 4 | Telegraphed enemy fire | 2 drones + 1 interceptor |
| 5 | Energy: charge versus thrust versus recovery | 1 drone + 1 interceptor + 1 heavy |
| 6+ | Density, mix, slightly shorter attack periods | `min(8, 2 + floor(level / 2))` enemies, class from the LCG |

Placement rejects samples that start inside the planet, within 0.75 of the player, or within 0.55 of another enemy, for up to 12 draws, then uses a deterministic angular fallback. `dev/orSolvability.m` checks those separations for a seed sweep. It does not claim that every seed is winnable. A successful scripted schedule for level 1 is stored in `tests/testGameplay.m` after `experiments/searchLevel1.m` finds one.

HP by class before level scaling: drone 4.2, interceptor 8.5, heavy 14. From level 6, HP grows by 8 percent per level above 5. Player HP starts at 100 and persists across clears. Planet contact hurts more than a graze from an enemy shot. Game over at HP <= 0.

## Scoring and HUD

Integer math only.

- Hit: combo increases by 1, then score increases by `(40 + round(25 * dmg)) * combo`.
- Kill: extra `250 * combo`, kill count increases.
- A player shot that expires or hits the planet without a hit resets combo, unless another hit landed on that same step.
- Level clear: `500 + max(0, round(1200 - 20 * levelTime)) + round(300 * fuel)`.

HUD, always visible during play, no extra input: score, level, HP, fuel, charge, lock quality. Title, clear, and game over replace the center overlay with a one-button instruction. Text plus a few updated rectangles. Readable at the default figure size.

## Visuals

Retro vector, base graphics only. Objects are created once.

- Background `[0.012 0.018 0.045]`, about 48 stars from a separate LCG stream seeded by `seed * 1009 + 7919` so star setup cannot change level generation.
- Planet: filled circle plus a larger faint atmospheric ring.
- Faint orbit guides at fixed radii.
- Player: cyan triangle. Nose follows velocity, blended toward the thrust axis while burning. Plume length follows thrust and remaining fuel. Face color brightens with charge.
- Drones are green wedges, interceptors are orange darts, heavies are purple diamonds.
- Player shots are yellow markers. Enemy shots are red markers.
- A single flash ring on damage.
- No images, no audio, no `sound`, `beep`, or `audiorecorder`.

## Automated players

`orBots` runs the same step function for a fixed game-time budget on levels 1–3.

| Policy | Behavior |
| --- | --- |
| Random | Geometric random holds and coasts from the LCG. |
| Rapid tap | 0.08 s down, 0.08 s up. Under the 0.12 s firing threshold. |
| Permanent hold | Down forever. Never releases, so it never fires, and fuel stays empty. |
| Fixed rhythm | 0.60 s down, 0.55 s up, ignoring aim. |
| Heuristic | Coasts to refuel below a fuel floor. Presses when a maneuver or an aligned shot is useful. Releases inside the damage peak when lock is high, or when charge gets too high, or when fuel is about to hit empty. |

The heuristic has to beat tap, permanent hold, random, and fixed rhythm on the combined score across the budget. If a degenerate policy wins, fuel burn, the damage peak, or muzzle speed changes. An artificial "spam penalty" is not added. Results land in `docs/VALIDATION_REPORT.md`.

## Tests

`tests/testInput.m`, `tests/testPhysics.m`, `tests/testDeterminism.m`, `tests/testGameplay.m`, `tests/testSubmission.m`.

Input covers the ten invariants. Physics covers a bounded 180 s orbit, thrust changing orbital elements, coast preserving motion, fuel accounting, projectile velocity, a tunneling geometry that a swept test catches, and an energy-drift bound. Determinism covers same seed, same schedule, step grouping, restart, and star generation not touching the level stream. Gameplay covers a scripted level-1 clear, a deliberate miss, a kill of each class, HP dropping only on a real contact, level-clear and game-over transitions, permanent hold failing to clear, and rapid tap losing to the heuristic. Submission covers character count `<= 10000`, the prohibited-function scan, no dependency on `dev/`, a headless schedule, a short figure run, SPACE-only key handling, and agreement with the development step on a shared schedule.

## Phases

1. Feasibility. Callback state machine, focus watchdog, `drawnow` loop without `pause`.
2. Orbital experiment and integrator choice. Then player physics and fuel.
3. Aim, charge curve, single projectile.
4. Three enemy classes and telegraphed attacks.
5. Level generation, score, HP, mode machine.
6. Vector scene and HUD.
7. Bots and scripted level 1. Retune fuel and damage if a degenerate policy wins.
8. Compress into `submission/orbitalReaper.m`, target 9,000 characters.
9. Prohibited-function scan, character count, run the submission file alone, smoke the same schedules.

## Acceptance checklist

- The game runs in MATLAB from `orbitalReaper` and from `orbitalReaperDev`.
- SPACE is the only gameplay control. All four events change the ship, the weapon, or both.
- A hold does not repeat shots. An orbit stays coherent for three minutes of game time without thrust.
- A shot can miss. A hit requires geometry.
- Infinite hold empties fuel, stops thrust and charge growth, and never fires until a release that comes too late to be a good strategy.
- The same seed rebuilds the same early levels.
- Level 1 has a stored scripted clear.
- Score, combo, and the level roster change difficulty.
- The figure loop stays on `drawnow` and fixed `dt`.
- The submission is one file, at most 10,000 characters, with no prohibited function and no bang operator. The count is an automated assertion. The submission is tested with the development folder off the path.

## Platform limitations

- Windows key auto-repeat is real. Suppression is by transition tracking, proven with synthetic repeats. This environment cannot inject OS key-repeat without Java or .NET, and both are banned or disabled, so the proof is the callback state machine rather than a robot typist.
- There is no focus-lost figure callback in R2025b. The watchdog is the recovery path.
- Catch-up is capped, so a long stall slows game time relative to the wall clock. Input edges still latch.
- Seeded placement is constrained, not a proof that every later level is winnable.
- Enemy bursts that do not fit in the 16-shot table are dropped.
- No audio, by contest rules.
