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

- Press edge: start thrusting and charging. The aim solution keeps updating while the key is down.
- Hold: radial thrust changes the orbit, fuel burns, and charge grows with game time. Two seconds is not the same maneuver as half a second. The tank empties in about 2.5 seconds and thrust stops. Charge stops accumulating when the tank is empty.
- Release edge: thrust stops and, if the hold lasted at least 0.12 seconds, exactly one projectile is fired. Holding never sprays.
- Coast: gravity carries the orbit, and fuel refills only while SPACE is up.

A press that starts the title, a level-clear screen, or a restart is consumed. The next press, after a release, is the first press that can thrust or fire. Losing the figure's key stream clears thrust and does not fire. MATLAB on Windows has no focus-lost callback, so that recovery is a watchdog: after key-repeat has been seen, 0.22 seconds of silence counts as a release; before the first repeat, the wait is 1.25 seconds so a normal key-repeat delay is not a focus loss. A long stall can trip the watchdog.

## Weapons

Charge is `min(hold / 1.0 s, 1)`. Damage is `3.2 * (0.50*c + 1.85*c*(1-c))`, which peaks near a charge of 0.63 and is worse at a full charge. Muzzle speed is `0.40 + 3.60*c`. The shot's velocity is the ship's velocity plus that speed along the aim direction.

Aim is a radial cone, not a homing missile. While SPACE is held, a constant-speed lead is solved at a reference charge of 0.55. The lead is used only when it lies inside a cone of about 35 degrees of the radial axis and the flight time is at most 1.4 seconds. Otherwise the shot leaves radially and can miss. Release timing picks the geometry. Charge picks the power and the fuel cost `0.10 + 0.28*c^2`.

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

Fuel makes a permanent hold lose the orbit and the gun, because a shot is fired on release and thrust dies on an empty tank. A tap shorter than 0.12 seconds does not fire. On seeds 1 through 8, a 32-second level-1 sample gave the heuristic 11078 points and 4 clears, a fixed rhythm 5333 points and 2 clears, random firing 2445 points and 1 clear, and both rapid tapping and permanent hold 0 points.
