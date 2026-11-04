function S = orEnemies(S)
%ORENEMIES Move the roster one step and fire telegraphed attacks.
%   Class 1 drifts on gravity. Class 2 steers toward the player radius.
%   Class 3 holds a slow home orbit and throws a radial burst.
%   Shots are unguided. A full projectile table drops the extra shots.

C = orConst();
dt = C.dt;
for i = 1:C.maxE
    if S.E(i, 1) <= 0
        continue
    end
    x = S.E(i, 3);
    y = S.E(i, 4);
    vx = S.E(i, 5);
    vy = S.E(i, 6);
    cls = S.E(i, 2);
    [gx, gy] = orGravity(x, y, C.mu);
    ax = gx;
    ay = gy;
    r = max(hypot(x, y), 1e-6);
    rhx = x / r;
    rhy = y / r;
    thx = -rhy;
    thy = rhx;
    vt = vx * thx + vy * thy;
    if cls == 2
        desR = min(2.65, max(1.00, hypot(S.px, S.py)));
        ar = 0.22 * (desR - r);
        at = 0.16 * (sqrt(C.mu / r) - vt);
        ax = ax + ar * rhx + at * thx;
        ay = ay + ar * rhy + at * thy;
    elseif cls == 3
        desR = S.E(i, 9);
        ar = 0.35 * (desR - r);
        at = 0.20 * (0.55 * sqrt(C.mu / r) - vt);
        ax = ax + ar * rhx + at * thx;
        ay = ay + ar * rhy + at * thy;
    end
    vx = vx + ax * dt;
    vy = vy + ay * dt;
    x = x + vx * dt;
    y = y + vy * dt;
    [x, y, vx, vy] = keepInArena(x, y, vx, vy);
    S.E(i, 3) = x;
    S.E(i, 4) = y;
    S.E(i, 5) = vx;
    S.E(i, 6) = vy;
    per = S.E(i, 12);
    if per > 0
        S.E(i, 8) = S.E(i, 8) - dt;
        if S.E(i, 8) < C.telegraph && S.E(i, 8) > 0
            S.E(i, 11) = 1;
        elseif S.E(i, 8) > 0
            S.E(i, 11) = 0;
        end
        if S.E(i, 8) <= 0
            S.E(i, 11) = 0;
            S.E(i, 8) = per;
            S = fireEnemy(S, i, C);
        end
    end
end
end

function [x, y, vx, vy] = keepInArena(x, y, vx, vy)
r = hypot(x, y);
if r < 0.58
    nx = x / max(r, 1e-8);
    ny = y / max(r, 1e-8);
    x = nx * 0.60;
    y = ny * 0.60;
    vr = vx * nx + vy * ny;
    if vr < 0
        vx = vx - 1.5 * vr * nx;
        vy = vy - 1.5 * vr * ny;
    end
elseif r > 3.40
    nx = x / r;
    ny = y / r;
    x = nx * 3.35;
    y = ny * 3.35;
    vr = vx * nx + vy * ny;
    if vr > 0
        vx = vx - 1.5 * vr * nx;
        vy = vy - 1.5 * vr * ny;
    end
end
end

function S = fireEnemy(S, i, C)
cls = S.E(i, 2);
x = S.E(i, 3);
y = S.E(i, 4);
vx = S.E(i, 5);
vy = S.E(i, 6);
if cls == 2
    dx = S.px - x;
    dy = S.py - y;
    dist = max(hypot(dx, dy), 1e-6);
    muzzle = 0.70;
    tf = dist / muzzle;
    lx = S.px + S.vx * tf;
    ly = S.py + S.vy * tf;
    dx = lx - x;
    dy = ly - y;
    d = max(hypot(dx, dy), 1e-6);
    ux = dx / d;
    uy = dy / d;
    S = spawnQ(S, x, y, vx * 0.25 + muzzle * ux, vy * 0.25 + muzzle * uy, 12, C);
else
    for k = 0:5
        a = 2 * pi * k / 6 + S.t;
        ux = cos(a);
        uy = sin(a);
        S = spawnQ(S, x, y, vx * 0.20 + 0.48 * ux, vy * 0.20 + 0.48 * uy, 10, C);
    end
end
end

function S = spawnQ(S, x, y, vx, vy, dmg, C)
for k = 1:C.maxQ
    if S.Q(k, 1) <= 0
        S.Q(k, :) = [1, x, y, vx, vy, dmg, 0, C.shotR];
        return
    end
end
end
