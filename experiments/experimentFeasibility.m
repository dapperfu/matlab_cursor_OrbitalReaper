function experimentFeasibility
% Feasibility: SPACE auto-repeat suppression, focus watchdog, drawnow loop.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'dev'));

ud = orInputDevice(0);
ud = orInputDevice(1, ud, 1);
ud = orInputDevice(1, ud, 1);
ud = orInputDevice(1, ud, 1);
ud = orInputDevice(1, ud, 0);
fprintf('presses %d repeats %d down %d\n', ud.presses, ud.repeats, ud.down);
ud = orInputDevice(1, ud, 2);
ud = orInputDevice(1, ud, 2);
fprintf('releases %d idleReleases %d down %d\n', ud.releases, ud.idleReleases, ud.down);

[d1, r1, a1] = orInputDevice(2, true, true, 0.05);
[d2, r2, a2] = orInputDevice(2, true, true, 0.30);
[d3, r3, a3] = orInputDevice(2, true, false, 0.40);
[d4, r4, a4] = orInputDevice(2, true, false, 1.40);
fprintf('watch short %d %d %d\n', d1, r1, a1);
fprintf('watch lost %d %d %d\n', d2, r2, a2);
fprintf('watch delay %d %d %d\n', d3, r3, a3);
fprintf('watch long %d %d %d\n', d4, r4, a4);

S = orNewGame(3, 1);
tic;
orbitalReaperDev(3, 12, 'off');
elapsed = toc;
fprintf('drawnowFrames 12 elapsed %.3f\n', elapsed);
fprintf('FEASIBILITY ok\n');
