function S = orPhysics(S)
%ORPHYSICS One symplectic-Euler step of the player, plus fuel.
%   Thrust is radial, plus an optional fixed tangential blend (C.kTan).
%   Fuel burns only while SPACE is held and the tank is not empty.
%   Fuel regenerates only while SPACE is released.

C = orConst();
dt = C.dt;
[ax, ay] = orGravity(S.px, S.py, C.mu);
S.burn = 0;
if S.phase == 1 && S.fuel > 0
    r = hypot(S.px, S.py);
    rhx = S.px / r;
    rhy = S.py / r;
    tx = rhx + C.kTan * (-rhy);
    ty = rhy + C.kTan * (rhx);
    tn = hypot(tx, ty);
    ax = ax + C.thrustA * tx / tn;
    ay = ay + C.thrustA * ty / tn;
    S.fuel = max(0, S.fuel - C.fuelBurn * dt);
    S.burn = 1;
elseif S.phase == 0
    S.fuel = min(1, S.fuel + C.fuelRegen * dt);
end
S.vx = S.vx + ax * dt;
S.vy = S.vy + ay * dt;
S.px = S.px + S.vx * dt;
S.py = S.py + S.vy * dt;
S = boundaries(S, C);
end

function S = boundaries(S, C)
r = hypot(S.px, S.py);
inner = C.rp + C.shipR;
if r < inner
    if r < 1e-8
        nx = 1;
        ny = 0;
    else
        nx = S.px / r;
        ny = S.py / r;
    end
    S.px = nx * (inner + 0.02);
    S.py = ny * (inner + 0.02);
    vr = S.vx * nx + S.vy * ny;
    if vr < 0
        S.vx = S.vx - 1.8 * vr * nx;
        S.vy = S.vy - 1.8 * vr * ny;
    end
    if S.planetLatch == 0
        S.hp = S.hp - 28;
        S.planetLatch = 1;
        S.flash = 1;
    end
elseif r > inner + 0.12
    S.planetLatch = 0;
end
r = hypot(S.px, S.py);
outer = C.ra - C.shipR;
if r > outer
    nx = S.px / r;
    ny = S.py / r;
    S.px = nx * (outer - 0.02);
    S.py = ny * (outer - 0.02);
    vr = S.vx * nx + S.vy * ny;
    if vr > 0
        S.vx = S.vx - 1.8 * vr * nx;
        S.vy = S.vy - 1.8 * vr * ny;
    end
    if S.arenaLatch == 0
        S.hp = S.hp - 16;
        S.arenaLatch = 1;
        S.flash = 1;
    end
elseif r < outer - 0.12
    S.arenaLatch = 0;
end
end
