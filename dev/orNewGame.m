function S = orNewGame(seed, level)
%ORNEWGAME Build a title-state world from a seed and a level number.
%   The same pair always rebuilds the same player orbit and roster.
%   The stream is the game LCG, not MATLAB rng.

if nargin < 1 || isempty(seed)
    seed = 1;
end
if nargin < 2 || isempty(level)
    level = 1;
end
seed = double(seed);
level = double(level);
C = orConst();
S.seed = seed;
S.level = level;
S.mode = 0;
S.t = 0;
S.levelTime = 0;
S.score = 0;
S.combo = 0;
S.bestCombo = 0;
S.hp = C.hp0;
S.fuel = 1;
S.charge = 0;
S.phase = 0;
S.fresh = 0;
S.thrust = 0;
S.burn = 0;
S.pressTime = 0;
S.releaseTime = 0;
S.holdDt = 0;
S.coastDt = 0;
S.presses = 0;
S.releases = 0;
S.focusAborts = 0;
S.lock = 0;
S.aimx = 1;
S.aimy = 0;
S.kills = 0;
S.shotsFired = 0;
S.shotsHit = 0;
S.flash = 0;
S.planetLatch = 0;
S.arenaLatch = 0;
S.rng = mod(seed * 10007 + level * 97 + 12345, 4294967296);
if S.rng == 0
    S.rng = 1;
end
[u, S.rng] = orLcg(S.rng, 1);
ang = 2 * pi * u;
r = C.r0;
v = sqrt(C.mu / r);
S.px = r * cos(ang);
S.py = r * sin(ang);
S.vx = -v * sin(ang);
S.vy = v * cos(ang);
S.E = zeros(C.maxE, 12);
S.P = zeros(C.maxP, 8);
S.Q = zeros(C.maxQ, 8);
S.ram = zeros(C.maxE, 1);
S = spawnRoster(S, C);
end

function S = spawnRoster(S, C)
level = S.level;
spec = roster(level, C);
if level >= 6
    n = size(spec, 1);
    spec = zeros(n, 3);
    for i = 1:n
        [u, S.rng] = orLcg(S.rng, 2);
        if u(1) > 0.84
            cls = 3;
        elseif u(1) > 0.55
            cls = 2;
        else
            cls = 1;
        end
        rad = 1.05 + 1.55 * u(2);
        per = 0;
        if cls >= 2
            per = max(1.8, 3.4 - 0.08 * level);
        end
        spec(i, :) = [cls, rad, per];
    end
end
for i = 1:size(spec, 1)
    cls = spec(i, 1);
    rad = spec(i, 2);
    per = spec(i, 3);
    placed = false;
    ang = 0;
    x = rad;
    y = 0;
    for attempt = 1:12
        [u, S.rng] = orLcg(S.rng, 1);
        ang = 2 * pi * u;
        x = rad * cos(ang);
        y = rad * sin(ang);
        if hypot(x - S.px, y - S.py) < 0.75
            continue
        end
        ok = true;
        for j = 1:i - 1
            if hypot(x - S.E(j, 3), y - S.E(j, 4)) < 0.55
                ok = false;
                break
            end
        end
        if ok
            placed = true;
            break
        end
    end
    if ~placed
        ang = atan2(S.py, S.px) + i * 2.399;
        x = rad * cos(ang);
        y = rad * sin(ang);
    end
    vt = sqrt(C.mu / rad);
    if cls == 3
        vt = 0.62 * vt;
    end
    hp = C.enemyHp(cls);
    if level >= 6
        hp = hp * (1 + 0.08 * (level - 5));
    end
    cd = 0;
    if per > 0
        [u, S.rng] = orLcg(S.rng, 1);
        cd = per * (0.75 + 0.25 * u);
    end
    S.E(i, :) = [1, cls, x, y, -vt * sin(ang), vt * cos(ang), hp, cd, rad, ang, 0, per];
end
end

function spec = roster(level, C)
if level == 1
    spec = [1, 2.05, 0];
elseif level == 2
    spec = [1, 1.20, 0; 1, 1.80, 0; 1, 2.40, 0];
elseif level == 3
    spec = [1, 1.05, 0; 1, 1.45, 0; 1, 2.10, 0; 1, 2.60, 0];
elseif level == 4
    spec = [1, 1.30, 0; 1, 2.20, 0; 2, 1.90, 2.8];
elseif level == 5
    spec = [1, 2.30, 0; 2, 1.55, 2.6; 3, 2.50, 3.6];
else
    n = min(C.maxE, 2 + floor(level / 2));
    spec = zeros(n, 3);
end
end
