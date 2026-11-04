function tests = testPhysics
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'dev'));
tests = functiontests(localfunctions);
end

function S = playing(seed)
if nargin < 1
    seed = 1;
end
S = orNewGame(seed, 1);
S.mode = 1;
end

function testCoastStaysBounded(tc)
S = playing();
r0 = hypot(S.px, S.py);
for i = 1:10800
    S = orStep(S, false, false);
end
r = hypot(S.px, S.py);
verifyLessThan(tc, abs(r - r0) / r0, 0.03);
verifyEqual(tc, S.hp, 100);
verifyEqual(tc, S.mode, 1);
end

function testThrustChangesOrbit(tc)
S = playing();
r0 = hypot(S.px, S.py);
for i = 1:36
    S = orStep(S, true, false);
end
S = orStep(S, false, false);
for i = 1:180
    S = orStep(S, false, false);
end
r = hypot(S.px, S.py);
verifyGreaterThan(tc, abs(r - r0), 0.08);
end

function testZeroThrustPreservesMotion(tc)
S = playing();
e0 = energy(S);
for i = 1:300
    S = orStep(S, false, false);
end
verifyLessThan(tc, abs(energy(S) - e0), 0.02);
verifyEqual(tc, S.fuel, 1, 'AbsTol', 1e-9);
end

function testFuelBurnMatchesModel(tc)
C = orConst();
S = playing();
n = 60;
for i = 1:n
    S = orStep(S, true, false);
end
expected = 1 - n * C.fuelBurn * C.dt;
verifyEqual(tc, S.fuel, expected, 'AbsTol', 1e-9);
verifyGreaterThan(tc, S.fuel, 0);
end

function testProjectileVelocity(tc)
C = orConst();
S = playing();
t = 0.5;
S.holdDt = t;
S.aimx = 1;
S.aimy = 0;
vx = S.vx;
vy = S.vy;
S = orCombat(S, 'fire');
u = 1 - exp(-t / C.tau);
spd = C.muzzle0 + C.muzzle1 * u;
verifyEqual(tc, S.P(1, 4), vx + spd, 'AbsTol', 1e-12);
verifyEqual(tc, S.P(1, 5), vy, 'AbsTol', 1e-12);
verifyEqual(tc, S.P(1, 6), C.damageMax * u, 'AbsTol', 1e-12);
verifyLessThan(tc, S.P(1, 6), C.damageMax);
verifyEqual(tc, S.shotsFired, 1);
verifyEqual(tc, S.P(1, 1), 1);
end

function testShortHoldFiresWeakShot(tc)
C = orConst();
S = playing();
n = 5;
for i = 1:n
    S = orStep(S, true, false);
    verifyEqual(tc, S.shotsFired, 0);
end
S = orStep(S, false, false);
t = n * C.dt;
u = 1 - exp(-t / C.tau);
verifyEqual(tc, S.shotsFired, 1);
verifyEqual(tc, S.P(1, 6), C.damageMax * u, 'AbsTol', 1e-9);
verifyLessThan(tc, u, 1 - exp(-0.5 / C.tau));
end

function testDamageFollowsStepResponse(tc)
C = orConst();
holds = [0.5, 1.0, 2.0];
dmgs = zeros(1, numel(holds));
for i = 1:numel(holds)
    n = round(holds(i) / C.dt);
    S = playing();
    S.hp = 1e6;
    for k = 1:n
        S = orStep(S, true, false);
        verifyEqual(tc, S.shotsFired, 0);
        verifyEqual(tc, S.presses, 1);
    end
    hudT = (n - 1) * C.dt;
    verifyEqual(tc, S.charge, 1 - exp(-hudT / C.tau), 'AbsTol', 1e-12);
    S = orStep(S, false, false);
    verifyEqual(tc, S.shotsFired, 1);
    verifyEqual(tc, S.releases, 1);
    t = n * C.dt;
    expect = C.damageMax * (1 - exp(-t / C.tau));
    verifyEqual(tc, S.P(1, 6), expect, 'AbsTol', 1e-9);
    verifyLessThan(tc, S.P(1, 6), C.damageMax);
    dmgs(i) = S.P(1, 6);
end
nominal = C.damageMax * (1 - exp(-holds / C.tau));
verifyEqual(tc, dmgs, nominal, 'AbsTol', 1e-9);
verifyGreaterThan(tc, dmgs(3), dmgs(1));
verifyGreaterThan(tc, dmgs(2), dmgs(3) - dmgs(2));
end

function testSweptHitAtHighSpeed(tc)
C = orConst();
S = playing();
S.E(1, 1) = 1;
S.E(1, 2) = 1;
S.E(1, 3) = 2;
S.E(1, 4) = 0;
S.E(1, 5) = 0;
S.E(1, 6) = 0;
S.E(1, 7) = 4.2;
hp0 = S.E(1, 7);
S.P(1, :) = [1, 0, 0, 4 / C.dt, 0, 3, 0, C.shotR];
S = orStep(S, false, false);
verifyLessThan(tc, S.E(1, 7), hp0);
end

function e = energy(S)
C = orConst();
r = hypot(S.px, S.py);
sp = hypot(S.vx, S.vy);
e = 0.5 * sp * sp - C.mu / r;
end
