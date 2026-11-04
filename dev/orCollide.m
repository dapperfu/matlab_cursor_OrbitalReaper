function S = orCollide(S)
%ORCOLLIDE Move projectiles and resolve swept hits.
%   A shot damages an enemy only when the segment between its old and new
%   position comes within the combined radius. Endpoint tests would miss
%   a fast shot that steps over the target.

C = orConst();
dt = C.dt;
hitThis = false;
expired = false;
for i = 1:C.maxP
    if S.P(i, 1) <= 0
        continue
    end
    ox = S.P(i, 2);
    oy = S.P(i, 3);
    nx = ox + S.P(i, 4) * dt;
    ny = oy + S.P(i, 5) * dt;
    S.P(i, 2) = nx;
    S.P(i, 3) = ny;
    S.P(i, 7) = S.P(i, 7) + dt;
    dmg = S.P(i, 6);
    struck = false;
    for e = 1:C.maxE
        if S.E(e, 1) <= 0
            continue
        end
        cls = S.E(e, 2);
        rad = C.shotR + C.enemyR(cls);
        if swept(ox, oy, nx, ny, S.E(e, 3), S.E(e, 4), rad)
            S.E(e, 7) = S.E(e, 7) - dmg;
            killed = S.E(e, 7) <= 0;
            if killed
                S.E(e, 1) = 0;
                S.E(e, 11) = 0;
            end
            S = award(S, dmg, killed);
            S.P(i, 1) = 0;
            struck = true;
            hitThis = true;
            S.flash = 1;
            break
        end
    end
    if ~struck
        rr = hypot(nx, ny);
        if S.P(i, 7) > C.shotLife || rr < C.rp || rr > C.ra + 0.6
            S.P(i, 1) = 0;
            expired = true;
        end
    end
end
for i = 1:C.maxQ
    if S.Q(i, 1) <= 0
        continue
    end
    ox = S.Q(i, 2);
    oy = S.Q(i, 3);
    nx = ox + S.Q(i, 4) * dt;
    ny = oy + S.Q(i, 5) * dt;
    S.Q(i, 2) = nx;
    S.Q(i, 3) = ny;
    S.Q(i, 7) = S.Q(i, 7) + dt;
    rad = C.shotR + C.shipR;
    if swept(ox, oy, nx, ny, S.px, S.py, rad)
        S.hp = S.hp - S.Q(i, 6);
        S.Q(i, 1) = 0;
        S.flash = 1;
        S.combo = 0;
    elseif S.Q(i, 7) > C.eShotLife || hypot(nx, ny) > C.ra + 0.8 || hypot(nx, ny) < C.rp
        S.Q(i, 1) = 0;
    end
end
S = ram(S, C);
if expired && ~hitThis
    S.combo = 0;
end
end

function S = ram(S, C)
for e = 1:C.maxE
    if S.E(e, 1) <= 0
        S.ram(e) = 0;
        continue
    end
    dx = S.E(e, 3) - S.px;
    dy = S.E(e, 4) - S.py;
    d = hypot(dx, dy);
    rad = C.shipR + C.enemyR(S.E(e, 2));
    if d < rad
        if S.ram(e) == 0
            S.hp = S.hp - 18;
            S.ram(e) = 1;
            S.flash = 1;
        end
        if d > 1e-8
            nx = dx / d;
            ny = dy / d;
        else
            nx = 1;
            ny = 0;
        end
        push = rad - d + 0.02;
        S.px = S.px - nx * push;
        S.py = S.py - ny * push;
    elseif d > rad + 0.06
        S.ram(e) = 0;
    end
end
end

function S = award(S, dmg, killed)
S.combo = S.combo + 1;
if S.combo > S.bestCombo
    S.bestCombo = S.combo;
end
S.score = S.score + (40 + round(25 * dmg)) * S.combo;
S.shotsHit = S.shotsHit + 1;
if killed
    S.score = S.score + 250 * S.combo;
    S.kills = S.kills + 1;
end
end

function hit = swept(x0, y0, x1, y1, cx, cy, rad)
dx = x1 - x0;
dy = y1 - y0;
L2 = dx * dx + dy * dy;
if L2 < 1e-14
    hit = (x0 - cx) ^ 2 + (y0 - cy) ^ 2 <= rad ^ 2;
    return
end
t = ((cx - x0) * dx + (cy - y0) * dy) / L2;
t = max(0, min(1, t));
qx = x0 + t * dx;
qy = y0 + t * dy;
hit = (qx - cx) ^ 2 + (qy - cy) ^ 2 <= rad ^ 2;
end
