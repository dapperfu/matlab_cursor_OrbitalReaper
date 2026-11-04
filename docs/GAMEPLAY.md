# Orbital Reaper

Top-down arena shooter. The ship orbits a planetary defense station. The only gameplay control is SPACE.

## How to run

From the repository root in MATLAB:

```matlab
addpath('submission');
orbitalReaper
```

That opens the figure and plays. Headless calls, used by the tests:

- `orbitalReaper(1, seed, level)` returns a title state.
- `orbitalReaper(2, state, down)` advances one fixed step. A fourth argument requests focus-loss recovery.
- `orbitalReaper(3, state, schedule)` replays an N-by-2 `[down, stepCount]` schedule.
- `orbitalReaper(4, seed, nFrames)` runs the real `drawnow` loop and closes the figure when `nFrames` is finite.

The readable development build is `addpath('dev'); orbitalReaperDev`. It is not required to play the contest file.

## Objective

Clear each level by destroying every enemy. Health, score, and the seed carry forward. A hull breach ends the run. SPACE on the game-over screen restarts level 1 of the same seed and does not fire.

## Controls

SPACE is the only gameplay button.

- Press edge: start thrusting and start the weapon response at zero. The aim solution keeps updating while the key is down.
- Hold: radial thrust changes the orbit and fuel burns. The weapon response is the elapsed hold, not a key-repeat count. Two seconds is not the same maneuver as half a second. The tank empties in about 2.5 seconds and thrust stops. The response keeps rising from hold time after the tank is empty.
- Release edge: thrust stops and exactly one projectile is fired. A short tap is a very weak shot. Holding never sprays, and there is no timer that fires every 0.12 seconds.
- Coast: gravity carries the orbit, and fuel refills only while SPACE is up. Coasting does not fire.

A press that starts the title, a level-clear screen, or a restart is consumed. The next press, after a release, is the first press that can thrust or fire. Losing the figure's key stream clears thrust and does not fire. MATLAB on Windows has no focus-lost callback, so that recovery is a watchdog: after key-repeat has been seen, 0.22 seconds of silence counts as a release; before the first repeat, the wait is 1.25 seconds so a normal key-repeat delay is not a focus loss. A long stall can trip the watchdog.

## Weapons

Hold duration `t` is monotonic game time. With `tau = 1.0` s and `damageMax = 6`:

```text
u(t) = 1 - exp(-t / tau)
damage(t) = damageMax * u(t)
```

`u(0) = 0`, damage rises toward 6 and never reaches it, a 2 s hold outdamages a 0.5 s hold, and the gain from 1 s to 2 s is smaller than the gain from 0 s to 1 s. The HUD charge is that same `u(t)`, not a separate integrator. Muzzle speed is `0.40 + 3.60*u`. Projectile radius is `0.022 * (0.5 + u)`. The shot's velocity is the ship's velocity plus that speed along the aim direction. Firing spends fuel `0.10 + 0.28*u`.

Aim is a radial cone, not a homing missile. While SPACE is held, the lead is solved at the current `u`. It is used only when it lies inside a cone of about 35 degrees of the radial axis and the flight time is at most 1.4 seconds. Otherwise the shot leaves radially and can miss. Release timing picks the geometry. Hold duration picks the power.

## Enemies

Three classes, at most eight at once, and at most sixteen shots of each side:

- Orbital drone: gravity only, low health, no weapon.
- Interceptor: steers toward the player's orbital radius and fires a telegraphed aimed shot.
- Heavy platform: slow orbit and a telegraphed six-shot radial burst.

Shots use swept segment tests so a fast round cannot tunnel. Touching the planet costs 28 health, the outer arena costs 16, and ramming an enemy costs 18. Those hits latch so one contact is one hit.

## Scoring and levels

A hit scores `(40 + round(25*damage)) * combo`. A kill adds `250 * combo`. Clearing a level adds `500 + max(0, round(1200 - 20*levelTime)) + round(300*fuel)`.

Levels 1 through 5 use fixed rosters. Level 1 is one drone. Later levels add altitude splits, interceptors, then a heavy platform. Level 6 and above fill up to eight ships from the game's own linear congruential generator. That generator is not MATLAB `rng`, so drawing stars cannot change a level. The same seed and level rebuild the same layout. Placement rejects some overlaps, which is a constraint, not a proof that every seed is solvable.

## Physics

Gravity is `a = -mu * r / |r|^3` with `mu = 0.40`. The ship starts in a circular orbit at radius 1.60 with tangential speed `sqrt(mu/r)`. Integration is symplectic Euler at `dt = 1/60`. Thrust is purely radial, acceleration 0.25, and only while fuel remains. A MATLAB experiment compared radial thrust with tangential blends and compared symplectic Euler with velocity Verlet. Radial thrust at this acceleration both raises apoapsis and shifts phase, and the unthrusted orbit stays bounded, so the blend was not used.

## Difficulty

Fuel makes a permanent hold lose the orbit, because thrust dies on an empty tank and a shot is fired only on release. There is no minimum hold and no anti-spam cooldown. The response is concave, so several short holds can add more damage than one hold of the same total time if every shot hits. A 0.5 s shot deals about 2.36 damage and a 2 s shot about 5.19, while four separate 0.5 s shots add about 9.44. Each shot still has to intercept, and each spends fuel. On seed 7 for 32 seconds, rapid 0.08 s taps fired 192 shots and hit none. A permanent hold fired none. A lock-gated heuristic scored 2140 with 2 hits out of 2 shots. A fixed 0.6 s rhythm scored 3085, and random holds scored 4963. Repeated medium holds can outscore one careful long hold when they connect.
