function S = orStep(S, down, focusLost)
%ORSTEP One game-time step, or a menu transition.
%   down is the debounced SPACE state, not a key-repeat count.
%   focusLost aborts thrust and charge and does not fire.
%   A press that changes Title, Level Clear, or Game Over is consumed.
%   Play ignores SPACE until that press is released.

if nargin < 3
    focusLost = false;
end
down = logical(down);
C = orConst();
if focusLost
    S.phase = 0;
    S.thrust = 0;
    S.charge = 0;
    S.releaseTime = S.t;
    S.focusAborts = S.focusAborts + 1;
    down = false;
end
if S.mode ~= 1
    S = menu(S, down);
    return
end
if S.fresh
    if ~down
        S.fresh = 0;
    end
    down = false;
end
evRel = false;
if S.phase == 0 && down
    S.phase = 1;
    S.pressTime = S.t;
    S.thrust = 1;
    S.presses = S.presses + 1;
    S.holdDt = 0;
elseif S.phase == 1 && ~down
    evRel = true;
    S.holdDt = S.t - S.pressTime;
    S.phase = 0;
    S.thrust = 0;
    S.releaseTime = S.t;
    S.releases = S.releases + 1;
elseif S.phase == 1
    S.holdDt = S.t - S.pressTime;
    S.thrust = 1;
else
    S.thrust = 0;
    S.holdDt = 0;
    S.coastDt = S.t - S.releaseTime;
end
if S.phase == 1 || evRel
    S.charge = 1 - exp(-max(0, S.holdDt) / C.tau);
end
S = orPhysics(S);
S = orCombat(S, 'aim');
S = orEnemies(S);
S = orCollide(S);
if evRel
    S = orCombat(S, 'fire');
end
if S.hp <= 0
    S.hp = 0;
    S.mode = 3;
    S.phase = 0;
    S.thrust = 0;
    S.charge = 0;
    S.burn = 0;
elseif ~any(S.E(:, 1) > 0)
    bonus = 500 + max(0, round(1200 - 20 * S.levelTime)) + round(300 * S.fuel);
    S.score = S.score + bonus;
    S.mode = 2;
    S.phase = 0;
    S.thrust = 0;
    S.charge = 0;
    S.burn = 0;
end
S.t = S.t + C.dt;
S.levelTime = S.levelTime + C.dt;
S.flash = max(0, S.flash - 2.5 * C.dt);
end

function S = menu(S, down)
if S.fresh
    if ~down
        S.fresh = 0;
    end
    return
end
if ~down
    S.phase = 0;
    S.thrust = 0;
    S.charge = 0;
    return
end
if S.phase ~= 0
    return
end
if S.mode == 0
    S.mode = 1;
elseif S.mode == 2
    score = S.score;
    hp = S.hp;
    kills = S.kills;
    fired = S.shotsFired;
    hits = S.shotsHit;
    best = S.bestCombo;
    S = orNewGame(S.seed, S.level + 1);
    S.score = score;
    S.hp = hp;
    S.kills = kills;
    S.shotsFired = fired;
    S.shotsHit = hits;
    S.bestCombo = best;
    S.mode = 1;
elseif S.mode == 3
    S = orNewGame(S.seed, 1);
    S.mode = 1;
end
S.fresh = 1;
S.phase = 0;
S.thrust = 0;
S.charge = 0;
S.burn = 0;
S.pressTime = 0;
S.releaseTime = 0;
S.holdDt = 0;
S.presses = 0;
S.releases = 0;
end
