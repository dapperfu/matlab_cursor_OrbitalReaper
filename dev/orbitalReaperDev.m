function orbitalReaperDev(seed, nFrames, vis)
%ORBITALREAPERDEV Play Orbital Reaper from the development modules.
%   SPACE is the only gameplay control. The loop uses drawnow and a fixed
%   physics step of 1/60. Pass nFrames to run a bounded smoke loop.
%
%   orbitalReaperDev
%   orbitalReaperDev(seed)
%   orbitalReaperDev(seed, nFrames, 'off')

if nargin < 1 || isempty(seed)
    seed = mod(floor(now * 86400), 2147483646) + 1;
end
if nargin < 2 || isempty(nFrames)
    nFrames = inf;
end
if nargin < 3 || isempty(vis)
    if isfinite(nFrames)
        vis = 'off';
    else
        vis = 'on';
    end
end
C = orConst();
S = orNewGame(seed, 1);
gfx = orRender('init', [], S, vis);
ud = orInputDevice(0);
gfx.fig.UserData = ud;
gfx.fig.WindowKeyPressFcn = @onPress;
gfx.fig.WindowKeyReleaseFcn = @onRelease;
accum = 0;
prev = tic;
frames = 0;
while isgraphics(gfx.fig) && frames < nFrames
    drawnow;
    if ~isgraphics(gfx.fig)
        break
    end
    frames = frames + 1;
    ud = gfx.fig.UserData;
    wall = toc(prev);
    prev = tic;
    wall = min(max(wall, 0), 0.10);
    aborted = false;
    if ud.down
        gap = toc(ud.last);
        [ud.down, ud.rep, aborted] = orInputDevice(2, ud.down, ud.rep, gap);
    end
    accum = accum + wall;
    steps = 0;
    while accum >= C.dt && steps < 5
        S = orStep(S, ud.down, aborted);
        aborted = false;
        accum = accum - C.dt;
        steps = steps + 1;
    end
    if isgraphics(gfx.fig)
        gfx.fig.UserData = ud;
        orRender('draw', gfx, S);
    end
end
if isgraphics(gfx.fig) && isfinite(nFrames)
    close(gfx.fig);
end
end

function onPress(~, evt)
if ~isprop(evt, 'Key') || ~strcmp(evt.Key, 'space')
    return
end
fig = gcbf;
if isempty(fig) || ~isgraphics(fig)
    return
end
ud = fig.UserData;
fig.UserData = orInputDevice(1, ud, 1);
end

function onRelease(~, evt)
if ~isprop(evt, 'Key') || ~strcmp(evt.Key, 'space')
    return
end
fig = gcbf;
if isempty(fig) || ~isgraphics(fig)
    return
end
ud = fig.UserData;
fig.UserData = orInputDevice(1, ud, 2);
end
