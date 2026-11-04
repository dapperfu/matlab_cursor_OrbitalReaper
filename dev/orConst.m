function C = orConst()
%ORCONST Policy parameters for Orbital Reaper.
%   Mechanisms read this struct. Tuning lives here so physics, weapons, and
%   levels stay in lockstep. A 0.6 s radial burn both lowers periapsis and
%   raises apoapsis while shifting phase, so kTan stays 0. thrustA is low
%   enough that this burn remains inside the arena. A near-empty tank
%   (about 2.2 s) goes hyperbolic and hits the boundary.
%   One release shot deals damageMax * (1 - exp(-hold / tau)) with
%   tau = 1.0 s. The same u sets muzzle speed, projectile radius, and
%   the fuel the shot spends. Holding does not fire again.

C.mu = 0.40;
C.r0 = 1.60;
C.rp = 0.40;
C.ra = 3.20;
C.dt = 1/60;
C.thrustA = 0.25;
C.kTan = 0.0;
C.fuelBurn = 0.40;
C.fuelRegen = 0.16;
C.tau = 1.0;
C.damageMax = 6;
C.shipR = 0.07;
C.shotR = 0.022;
C.muzzle0 = 0.40;
C.muzzle1 = 3.60;
C.cone = 0.82;
C.maxTof = 1.40;
C.maxE = 8;
C.maxP = 16;
C.maxQ = 16;
C.hp0 = 100;
C.shotLife = 2.4;
C.eShotLife = 4.5;
C.telegraph = 0.70;
C.enemyR = [0.055 0.08 0.14];
C.enemyHp = [4.2 8.5 14.0];
end
