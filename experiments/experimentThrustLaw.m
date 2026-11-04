function experimentThrustLaw
% Thrust-law survey for Orbital Reaper.
% Compares radial thrust with tangential blends, and symplectic Euler
% with velocity Verlet, on a circular orbit. Prints a one-line choice.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'dev'));
C = orConst();
mu = C.mu;
r0 = C.r0;
dt = C.dt;
thrustA = C.thrustA;

fprintf('mu %.3f r0 %.3f dt %.5f thrust %.3f\n', mu, r0, dt, thrustA);
ks = [0, 0.35, 0.70, 1.00];
fprintf('kTan  hold  dPeri  dApo  dSma  dPhase\n');
choice = 0;
choiceOk = false;
for k = ks
    for hold = [0.5, 2.0]
        coast = referenceCoast(mu, r0, dt,  hold + 5);
        burned = burnCoast(mu, r0, dt, thrustA, k, hold, 5, 'euler');
        dPeri = burned.peri - coast.peri;
        dApo = burned.apo - coast.apo;
        dSma = burned.sma - coast.sma;
        dPhase = wrapToPiLocal(burned.phase - coast.phase);
        fprintf('%4.2f %4.1f %7.3f %6.3f %6.3f %7.3f\n', k, hold, dPeri, dApo, dSma, dPhase);
    end
    b1 = burnCoast(mu, r0, dt, thrustA, k, 0.6, 5, 'euler');
    c1 = referenceCoast(mu, r0, dt, 5.6);
    raise = (b1.apo - c1.apo) > 0.12;
    lower = (c1.peri - b1.peri) > 0.06;
    phase = abs(wrapToPiLocal(b1.phase - c1.phase)) > 0.15;
    fprintf('  criteria k %.2f raise %d lower %d phase %d\n', k, raise, lower, phase);
    if raise && lower && phase && ~choiceOk
        choice = k;
        choiceOk = true;
    end
end
if ~choiceOk
    choice = 0.70;
    fprintf('CHOICE blend kTan %.2f (radial did not meet raise, lower, and phase)\n', choice);
else
    fprintf('CHOICE kTan %.2f\n', choice);
end

euler = coastLong(mu, r0, dt, 180, 'euler');
verlet = coastLong(mu, r0, dt, 180, 'verlet');
fprintf('drift180 euler %.5f verlet %.5f r0 %.3f\n', euler, verlet, r0);
if euler > 0.03 * r0 && verlet + 0.005 < euler
    fprintf('INTEGRATOR velocityVerlet\n');
else
    fprintf('INTEGRATOR symplecticEuler\n');
end
end

function el = referenceCoast(mu, r0, dt, seconds)
el = burnCoast(mu, r0, dt, 0, 0, 0, seconds, 'euler');
end

function el = burnCoast(mu, r0, dt, thrustA, kTan, hold, coast, kind)
nHold = round(hold / dt);
nCoast = round(coast / dt);
ang = 0.4;
v = sqrt(mu / r0);
px = r0 * cos(ang);
py = r0 * sin(ang);
vx = -v * sin(ang);
vy = v * cos(ang);
ax = 0;
ay = 0;
for n = 1:(nHold + nCoast)
    [gx, gy] = grav(px, py, mu);
    ax = gx;
    ay = gy;
    if n <= nHold && thrustA > 0
        r = hypot(px, py);
        rhx = px / r;
        rhy = py / r;
        tx = rhx + kTan * (-rhy);
        ty = rhy + kTan * rhx;
        tn = hypot(tx, ty);
        ax = ax + thrustA * tx / tn;
        ay = ay + thrustA * ty / tn;
    end
    if strcmp(kind, 'verlet')
        px = px + vx * dt + 0.5 * ax * dt * dt;
        py = py + vy * dt + 0.5 * ay * dt * dt;
        [gx, gy] = grav(px, py, mu);
        vx = vx + 0.5 * (ax + gx) * dt;
        vy = vy + 0.5 * (ay + gy) * dt;
    else
        vx = vx + ax * dt;
        vy = vy + ay * dt;
        px = px + vx * dt;
        py = py + vy * dt;
    end
end
el = elements(px, py, vx, vy, mu);
end

function drift = coastLong(mu, r0, dt, seconds, kind)
n = round(seconds / dt);
ang = 0.4;
v = sqrt(mu / r0);
px = r0 * cos(ang);
py = r0 * sin(ang);
vx = -v * sin(ang);
vy = v * cos(ang);
rMax = 0;
ax = 0;
ay = 0;
for nStep = 1:n
    [gx, gy] = grav(px, py, mu);
    if strcmp(kind, 'verlet')
        px = px + vx * dt + 0.5 * gx * dt * dt;
        py = py + vy * dt + 0.5 * gy * dt * dt;
        [gx2, gy2] = grav(px, py, mu);
        vx = vx + 0.5 * (gx + gx2) * dt;
        vy = vy + 0.5 * (gy + gy2) * dt;
    else
        vx = vx + gx * dt;
        vy = vy + gy * dt;
        px = px + vx * dt;
        py = py + vy * dt;
    end
    rMax = max(rMax, abs(hypot(px, py) - r0));
end
drift = rMax;
end

function [ax, ay] = grav(x, y, mu)
r2 = max(x * x + y * y, 1e-8);
r3 = r2 * sqrt(r2);
ax = -mu * x / r3;
ay = -mu * y / r3;
end

function el = elements(px, py, vx, vy, mu)
r = hypot(px, py);
sp = hypot(vx, vy);
eps = 0.5 * sp * sp - mu / r;
h = px * vy - py * vx;
sma = -mu / (2 * eps);
ecc = sqrt(max(0, 1 + 2 * eps * h * h / (mu * mu)));
el.sma = sma;
el.peri = sma * (1 - ecc);
el.apo = sma * (1 + ecc);
el.phase = atan2(py, px);
el.ecc = ecc;
end

function a = wrapToPiLocal(a)
a = mod(a + pi, 2 * pi) - pi;
end
