function R = orBots(seed, seconds, levels)
%ORBOTS Compare scripted policies on the same worlds.
%   The heuristic uses fuel, charge, and lock. It has no extra button
%   and no spam penalty. It releases at u = 0.55, about 0.8 s. Damage
%   keeps rising after that, so the cutoff is not a damage peak.

if nargin < 1 || isempty(seed)
    seed = 7;
end
if nargin < 2 || isempty(seconds)
    seconds = 35;
end
if nargin < 3 || isempty(levels)
    levels = 1:3;
end
names = {'random', 'tap', 'hold', 'rhythm', 'heuristic'};
R.names = names;
R.score = zeros(1, numel(names));
R.kills = zeros(1, numel(names));
R.hp = zeros(1, numel(names));
R.fired = zeros(1, numel(names));
R.hits = zeros(1, numel(names));
R.clears = zeros(1, numel(names));
R.alive = zeros(1, numel(names));
for n = 1:numel(names)
    for level = levels
        S = runPolicy(names{n}, seed, level, seconds);
        R.score(n) = R.score(n) + S.score;
        R.kills(n) = R.kills(n) + S.kills;
        R.hp(n) = R.hp(n) + S.hp;
        R.fired(n) = R.fired(n) + S.shotsFired;
        R.hits(n) = R.hits(n) + S.shotsHit;
        R.clears(n) = R.clears(n) + max(0, S.level - level) + double(S.mode == 2);
        R.alive(n) = R.alive(n) + double(S.hp > 0);
    end
end
R.accuracy = R.hits ./ max(1, R.fired);
end

function S = runPolicy(name, seed, level, seconds)
C = orConst();
S = orNewGame(seed, level);
S = orStep(S, true, false);
S = orStep(S, false, false);
bot.phase = 0;
bot.left = 0;
bot.rng = mod(seed * 17 + level * 91 + 3, 4294967296);
n = round(seconds / C.dt);
for k = 1:n
    if S.mode == 2
        S = orStep(S, true, false);
        S = orStep(S, false, false);
        bot.phase = 0;
        bot.left = 0;
    end
    if S.mode == 3 || S.mode ~= 1
        break
    end
    [down, bot] = choose(name, S, bot);
    S = orStep(S, down, false);
end
end

function [down, bot] = choose(name, S, bot)
C = orConst();
switch name
    case 'hold'
        down = true;
    case 'tap'
        [down, bot] = pulse(bot, round(0.08 / C.dt), round(0.08 / C.dt));
    case 'rhythm'
        [down, bot] = pulse(bot, round(0.60 / C.dt), round(0.55 / C.dt));
    case 'random'
        if bot.left <= 0
            [u, bot.rng] = orLcg(bot.rng, 2);
            bot.phase = double(u(1) > 0.45);
            bot.left = 4 + floor((4 + 36 * u(2)));
        end
        down = bot.phase == 1;
        bot.left = bot.left - 1;
    otherwise
        down = heuristic(S);
end
end

function [down, bot] = pulse(bot, holdN, coastN)
if bot.left <= 0
    if bot.phase == 1
        bot.phase = 0;
        bot.left = coastN;
    else
        bot.phase = 1;
        bot.left = holdN;
    end
end
down = bot.phase == 1;
bot.left = bot.left - 1;
end

function down = heuristic(S)
if S.mode ~= 1
    down = false;
    return
end
if S.phase == 1
    if S.fuel <= 0.06 || S.charge >= 0.55
        down = false;
        return
    end
    down = true;
    return
end
if S.fuel < 0.45
    down = false;
    return
end
if S.lock >= 0.72
    down = true;
    return
end
down = false;
end
