function tests = testInput
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'dev'));
tests = functiontests(localfunctions);
end

function S = playing(seed, level)
if nargin < 1
    seed = 1;
end
if nargin < 2
    level = 1;
end
S = orNewGame(seed, level);
S.mode = 1;
end

function testOnePressAndNoRepeat(tc)
S = playing();
S = orStep(S, true, false);
S = orStep(S, true, false);
S = orStep(S, true, false);
verifyEqual(tc, S.presses, 1);
verifyEqual(tc, S.phase, 1);
verifyEqual(tc, S.shotsFired, 0);
end

function testHoldDoesNotFireUntilRelease(tc)
S = playing();
for i = 1:50
    S = orStep(S, true, false);
end
verifyEqual(tc, S.shotsFired, 0);
verifyGreaterThan(tc, S.charge, 0.5);
S = orStep(S, false, false);
verifyEqual(tc, S.shotsFired, 1);
verifyEqual(tc, S.releases, 1);
verifyEqual(tc, S.charge, 0);
verifyEqual(tc, S.phase, 0);
end

function testReleaseWhileReleasedIsNoOp(tc)
S = playing();
S = orStep(S, false, false);
S = orStep(S, false, false);
verifyEqual(tc, S.releases, 0);
verifyEqual(tc, S.presses, 0);
verifyEqual(tc, S.shotsFired, 0);
end

function testDifferentHoldImpulses(tc)
A = burn(20);
B = burn(90);
verifyGreaterThan(tc, abs(A.px - B.px) + abs(A.py - B.py), 0.05);
verifyGreaterThan(tc, abs(A.fuel - B.fuel), 0.05);
end

function testDifferentCoastStates(tc)
S = burn(25);
A = S;
B = S;
for i = 1:15
    A = orStep(A, false, false);
end
for i = 1:120
    B = orStep(B, false, false);
end
verifyGreaterThan(tc, hypot(A.px - B.px, A.py - B.py), 0.05);
end

function testFocusLossDoesNotFire(tc)
S = playing();
S = orStep(S, true, false);
S = orStep(S, true, false);
verifyEqual(tc, S.phase, 1);
S = orStep(S, true, true);
verifyEqual(tc, S.phase, 0);
verifyEqual(tc, S.shotsFired, 0);
verifyEqual(tc, S.charge, 0);
verifyEqual(tc, S.focusAborts, 1);
S = orStep(S, false, false);
verifyEqual(tc, S.shotsFired, 0);
end

function testRestartClearsInput(tc)
S = playing();
S.mode = 3;
S.phase = 1;
S.charge = 0.9;
S.thrust = 1;
S.t = 4;
S = orStep(S, true, false);
verifyEqual(tc, S.mode, 3);
verifyEqual(tc, S.shotsFired, 0);
S = orStep(S, false, false);
verifyEqual(tc, S.phase, 0);
verifyEqual(tc, S.charge, 0);
S = orStep(S, true, false);
verifyEqual(tc, S.mode, 1);
verifyEqual(tc, S.level, 1);
verifyEqual(tc, S.fresh, 1);
verifyEqual(tc, S.shotsFired, 0);
verifyEqual(tc, S.phase, 0);
verifyEqual(tc, S.score, 0);
S = orStep(S, true, false);
verifyEqual(tc, S.shotsFired, 0);
verifyEqual(tc, S.thrust, 0);
end

function testRepeatedDownIsOneShot(tc)
C = orConst();
S = playing();
S.hp = 1e6;
n = round(2.0 / C.dt);
for i = 1:n
    S = orStep(S, true, false);
    verifyEqual(tc, S.presses, 1);
    verifyEqual(tc, S.shotsFired, 0);
end
S = orStep(S, false, false);
t = n * C.dt;
verifyEqual(tc, S.shotsFired, 1);
verifyEqual(tc, S.releases, 1);
verifyEqual(tc, S.P(1, 6), C.damageMax * (1 - exp(-t / C.tau)), 'AbsTol', 1e-9);
verifyGreaterThan(tc, S.P(1, 6), C.damageMax * (1 - exp(-0.5 / C.tau)));
end

function testDeviceRepeatSuppression(tc)
ud = orInputDevice(0);
ud = orInputDevice(1, ud, 1);
ud = orInputDevice(1, ud, 1);
ud = orInputDevice(1, ud, 1);
verifyEqual(tc, ud.presses, 1);
verifyEqual(tc, ud.repeats, 2);
ud = orInputDevice(1, ud, 2);
ud = orInputDevice(1, ud, 2);
verifyEqual(tc, ud.releases, 1);
verifyEqual(tc, ud.idleReleases, 1);
verifyFalse(tc, ud.down);
end

function testFocusWatchdog(tc)
[d, r, a] = orInputDevice(2, true, true, 0.05);
verifyFalse(tc, a);
verifyTrue(tc, d);
[d, r, a] = orInputDevice(2, true, true, 0.30);
verifyTrue(tc, a);
verifyFalse(tc, d);
[d, r, a] = orInputDevice(2, true, false, 0.40);
verifyFalse(tc, a);
[d, r, a] = orInputDevice(2, true, false, 1.40);
verifyTrue(tc, a);
verifyFalse(tc, d);
end

function S = burn(n)
S = playing();
for i = 1:n
    S = orStep(S, true, false);
end
S = orStep(S, false, false);
end
