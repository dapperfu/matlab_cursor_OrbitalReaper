function S = orCombat(S, action)
%ORCOMBAT Aim update or a single release shot.
%   'aim'  refreshes the lead solution from current geometry.
%   'fire' spawns one projectile from the current charge and aim.
%   A hold never calls 'fire'. Release instant picks the direction.
%   Charge picks power. Outside the cone the shot leaves along the nose,
%   so a bad release misses.

if strcmp(action, 'aim')
    S = aimAt(S);
else
    S = fireShot(S);
end
end

function S = aimAt(S)
% The weapon bore is radial. A solved lead is used only when that lead
% lies near the radial axis and the flight time is short. Otherwise the
% shot leaves straight out or in and the curved target is missed.
C = orConst();
r = max(hypot(S.px, S.py), 1e-8);
rhx = S.px / r;
rhy = S.py / r;
c = 0.55;
muzzle = C.muzzle0 + C.muzzle1 * c;
best = -inf;
bestAlign = 0;
bestT = inf;
bestSign = 1;
bx = rhx;
by = rhy;
found = false;
for i = 1:C.maxE
    if S.E(i, 1) <= 0
        continue
    end
    rx = S.E(i, 3) - S.px;
    ry = S.E(i, 4) - S.py;
    wx = S.E(i, 5) - S.vx;
    wy = S.E(i, 6) - S.vy;
    qa = wx * wx + wy * wy - muzzle * muzzle;
    qb = 2 * (rx * wx + ry * wy);
    qc = rx * rx + ry * ry;
    tHit = leadTime(qa, qb, qc);
    if isempty(tHit)
        continue
    end
    ux = (rx / tHit + wx) / muzzle;
    uy = (ry / tHit + wy) / muzzle;
    un = hypot(ux, uy);
    if un < 1e-6
        continue
    end
    ux = ux / un;
    uy = uy / un;
    signed = ux * rhx + uy * rhy;
    align = abs(signed);
    score = align - 0.22 * tHit;
    if score > best
        best = score;
        bestAlign = align;
        bestT = tHit;
        bestSign = sign(signed);
        if bestSign == 0
            bestSign = 1;
        end
        bx = ux;
        by = uy;
        found = true;
    end
end
if ~found || bestAlign < C.cone || bestT > C.maxTof
    S.aimx = bestSign * rhx;
    S.aimy = bestSign * rhy;
    if found
        S.lock = bestAlign * max(0, 1 - bestT / 3) * 0.45;
    else
        S.lock = 0;
    end
    return
end
S.aimx = bx;
S.aimy = by;
S.lock = bestAlign * max(0, 1 - 0.25 * bestT);
end

function tHit = leadTime(qa, qb, qc)
% Smallest positive flight time for |R + W t| = muzzle * t.
tHit = [];
if abs(qa) < 1e-9
    if abs(qb) < 1e-9
        return
    end
    t = -qc / qb;
    if t > 0.02
        tHit = t;
    end
    return
end
disc = qb * qb - 4 * qa * qc;
if disc < 0
    return
end
root = sqrt(disc);
t1 = (-qb - root) / (2 * qa);
t2 = (-qb + root) / (2 * qa);
best = inf;
if t1 > 0.02
    best = t1;
end
if t2 > 0.02 && t2 < best
    best = t2;
end
if isfinite(best)
    tHit = best;
end
end

function S = fireShot(S)
C = orConst();
if S.holdDt < C.minHold || S.charge <= 0
    S.charge = 0;
    return
end
c = min(1, S.charge);
dmg = 3.2 * (0.50 * c + 1.85 * c * (1 - c));
spd = C.muzzle0 + C.muzzle1 * c;
vx = S.vx + spd * S.aimx;
vy = S.vy + spd * S.aimy;
spawned = false;
for i = 1:C.maxP
    if S.P(i, 1) <= 0
        S.P(i, :) = [1, S.px, S.py, vx, vy, dmg, 0, C.shotR];
        spawned = true;
        break
    end
end
if spawned
    S.shotsFired = S.shotsFired + 1;
    S.fuel = max(0, S.fuel - (0.10 + 0.28 * c * c));
end
S.charge = 0;
end
