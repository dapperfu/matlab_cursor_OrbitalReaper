function tests = testGameplay
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'dev'));
tests = functiontests(localfunctions);
end

function testScriptedLevelOneWin(tc)
sched = [1 1; 0 1142; 1 33; 0 1; 1 33; 0 20];
S = orRun(orNewGame(7, 1), sched);
verifyEqual(tc, S.mode, 2);
verifyGreaterThanOrEqual(tc, S.kills, 1);
verifyGreaterThan(tc, S.score, 0);
verifyGreaterThan(tc, S.hp, 0);
end

function testPlayerCanMiss(tc)
S = orNewGame(7, 1);
S.mode = 1;
hp = S.E(1, 7);
S.charge = 0.55;
S.holdDt = 0.55;
S.aimx = 0;
S.aimy = 1;
S = orCombat(S, 'fire');
for i = 1:160
    S = orStep(S, false, false);
end
verifyEqual(tc, S.E(1, 7), hp);
verifyEqual(tc, S.shotsHit, 0);
end

function testEachClassCanBeDestroyed(tc)
S = orNewGame(1, 5);
S.mode = 1;
C = orConst();
classes = S.E(S.E(:, 1) > 0, 2);
verifyEqual(tc, sort(classes(:))', [1 2 3]);
for e = 1:3
    S.P(e, :) = [1, S.E(e, 3), S.E(e, 4), 0, 0, 100, 0, C.shotR];
end
S = orStep(S, false, false);
verifyEqual(tc, sum(S.E(:, 1)), 0);
verifyGreaterThanOrEqual(tc, S.kills, 3);
end

function testHealthDropsOnlyOnContact(tc)
S = orNewGame(1, 1);
S.mode = 1;
for i = 1:30
    S = orStep(S, false, false);
end
verifyEqual(tc, S.hp, 100);
S.Q(1, :) = [1, S.px, S.py, 0, 0, 12, 0, 0.05];
S = orStep(S, false, false);
verifyEqual(tc, S.hp, 88);
end

function testLevelClearThenContinue(tc)
C = orConst();
S = orNewGame(3, 1);
S.mode = 1;
score = S.score;
S.P(1, :) = [1, S.E(1, 3), S.E(1, 4), 0, 0, 100, 0, C.shotR];
S = orStep(S, false, false);
verifyEqual(tc, S.mode, 2);
verifyGreaterThan(tc, S.score, score);
S = orStep(S, true, false);
verifyEqual(tc, S.level, 2);
verifyEqual(tc, S.mode, 1);
verifyEqual(tc, S.fresh, 1);
verifyGreaterThan(tc, sum(S.E(:, 1)), 1);
end

function testGameOverRestart(tc)
S = orNewGame(4, 2);
S.mode = 1;
S.score = 500;
S.Q(1, :) = [1, S.px, S.py, 0, 0, 500, 0, 0.05];
S = orStep(S, false, false);
verifyEqual(tc, S.mode, 3);
verifyEqual(tc, S.hp, 0);
S = orStep(S, true, false);
verifyEqual(tc, S.mode, 1);
verifyEqual(tc, S.level, 1);
verifyEqual(tc, S.score, 0);
verifyEqual(tc, S.fresh, 1);
verifyEqual(tc, S.shotsFired, 0);
end

function testPermanentHoldDoesNotWin(tc)
S = orNewGame(7, 1);
S = orStep(S, true, false);
S = orStep(S, false, false);
for i = 1:1800
    if S.mode ~= 1
        break
    end
    S = orStep(S, true, false);
end
verifyEqual(tc, S.shotsFired, 0);
verifyLessThan(tc, S.fuel, 0.05);
verifyNotEqual(tc, S.mode, 2);
end

function testHeuristicBeatsTapAndHold(tc)
R = orBots(7, 32, 1);
heur = 5;
tap = 2;
hold = 3;
rhythm = 4;
verifyGreaterThan(tc, R.kills(heur), 0);
verifyGreaterThan(tc, R.score(heur), R.score(tap));
verifyGreaterThan(tc, R.score(heur), R.score(hold));
verifyGreaterThan(tc, R.score(heur), R.score(rhythm));
verifyGreaterThan(tc, R.accuracy(heur), R.accuracy(rhythm));
verifyEqual(tc, R.score(tap), 0);
verifyEqual(tc, R.fired(hold), 0);
end
