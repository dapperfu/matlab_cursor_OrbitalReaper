function tests = testDeterminism
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'dev'));
tests = functiontests(localfunctions);
end

function testSameSeedSameLayout(tc)
A = orNewGame(42, 3);
B = orNewGame(42, 3);
verifyEqual(tc, A.E, B.E);
verifyEqual(tc, [A.px A.py A.vx A.vy], [B.px B.py B.vx B.vy]);
C = orNewGame(42, 4);
verifyNotEqual(tc, A.E(:, 3), C.E(:, 3));
end

function testSameScheduleSameTrajectory(tc)
sched = [1 1; 0 2; 1 20; 0 15; 1 10; 0 30];
A = orRun(orNewGame(9, 2), sched);
B = orRun(orNewGame(9, 2), sched);
verifyEqual(tc, A.px, B.px);
verifyEqual(tc, A.py, B.py);
verifyEqual(tc, A.score, B.score);
verifyEqual(tc, A.E, B.E);
end

function testRestartMatchesFreshLevel(tc)
S = orNewGame(11, 1);
S.mode = 1;
for i = 1:40
    S = orStep(S, false, false);
end
S.mode = 3;
S = orStep(S, true, false);
fresh = orNewGame(11, 1);
verifyEqual(tc, S.E, fresh.E);
verifyEqual(tc, [S.px S.py S.vx S.vy], [fresh.px fresh.py fresh.vx fresh.vy]);
verifyEqual(tc, S.mode, 1);
end

function testStarsDoNotChangeLevels(tc)
A = orNewGame(5, 2);
[xs, ys] = orStars(5);
B = orNewGame(5, 2);
verifyEqual(tc, A.E, B.E);
verifyEqual(tc, numel(xs), 48);
verifyEqual(tc, numel(ys), 48);
[xs2, ys2] = orStars(5);
verifyEqual(tc, xs, xs2);
verifyEqual(tc, ys, ys2);
end

function testFirstFiveLevelsRepeat(tc)
for level = 1:5
    A = orNewGame(8, level);
    B = orNewGame(8, level);
    verifyEqual(tc, A.E, B.E);
    verifyGreaterThan(tc, sum(A.E(:, 1)), 0);
end
L1 = orNewGame(8, 1);
L2 = orNewGame(8, 2);
verifyEqual(tc, sum(L1.E(:, 1)), 1);
verifyEqual(tc, sum(L2.E(:, 1)), 3);
end
