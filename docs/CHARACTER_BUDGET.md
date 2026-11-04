# Character budget

Measured from `submission/orbitalReaper.m` after the final MATLAB run.

| | Characters |
| --- | ---: |
| Total source | 9905 |
| UTF-8 bytes | 9905 |
| Hard limit | 10000 |
| Internal target | 9000 |
| Margin under the hard limit | 95 |
| Over the internal target | 905 |

`tests/testSubmission.m` rejects a file whose raw length, CR-stripped length, or UTF-8 byte length exceeds 10000. The current file is ASCII, so those three counts match.

## Per function

| Function | Characters | Role |
| --- | ---: | --- |
| orbitalReaper | 351 | Headless dispatcher and play entry |
| play | 1334 | Figure, fixed-step loop, drawnow |
| key, key0, watch, onP, onR | 437 | SPACE edges and focus watchdog |
| stepG | 702 | Four-event step and the hold-time charge |
| menu | 399 | Title, clear, and restart |
| phys, wall | 724 | Gravity, radial thrust, boundaries |
| aim, lead | 798 | Radial-cone intercept at the current response |
| fire | 287 | One release shot, damage `6*(1-exp(-t))` |
| foes, shoot, addQ | 927 | Three enemy classes |
| hit, award, sweep | 1378 | Swept hits, ram, score |
| newG, roster | 1361 | Seeded levels |
| drawG, alive, stars | 816 | HUD and vector scene |
| lcg, K | 365 | Owned RNG and constants |

## What the last thousand characters would have removed

The file is 905 characters over the 9000 target and 95 under the contest limit. The first-order damage law replaced the 0.12 s gate and the old peaked damage polynomial, and that replacement is smaller than the code it removed. Further cuts that were tried either changed the seed-7 trajectory or deleted a mechanic the design requires. The pieces that still cost more than their visuals:

- Swept collision and the two projectile tables. They are why a fast shot cannot tunnel, and they are the largest block.
- The quadratic lead. A shorter pure-radial gun missed the verified level-1 window.
- Level rosters and the level-6 generator. The tables are already compact.
- Distinct enemy markers, the planet, and the starfield. The plume, lock line, hit flash, and extra orbit rings were removed from the contest file. The development renderer in `dev/orRender.m` still draws them.

Renaming the player coordinate off `py` and the cooldown off `cd` was required so a whole-identifier scan does not flag the prohibited names `py` and `cd`. Those renames also saved a few characters.
