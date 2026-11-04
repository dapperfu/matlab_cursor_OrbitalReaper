function varargout = orInputDevice(op, a, b, c)
%ORINPUTDEVICE Keyboard latch and focus watchdog.
%   op 0: blank device state
%   op 1: apply one callback, kind 1 = SPACE press, 2 = SPACE release, 0 = other
%   op 2: focus watchdog. Returns down, repeatSeen, abort.
%
%   Repeated SPACE press callbacks while the key is already down only mark
%   repeatSeen. They do not create another press. That is how Windows
%   auto-repeat is suppressed without Java or .NET.

if op == 0
    varargout{1} = blankDevice();
elseif op == 1
    varargout{1} = applyKey(a, b);
elseif op == 2
    [down, rep, abort] = focusWatch(a, b, c);
    varargout{1} = down;
    varargout{2} = rep;
    varargout{3} = abort;
end
end

function ud = blankDevice()
ud.down = false;
ud.rep = false;
ud.presses = 0;
ud.repeats = 0;
ud.releases = 0;
ud.idleReleases = 0;
ud.last = tic;
end

function ud = applyKey(ud, kind)
if kind == 0
    return
end
if kind == 1
    if ~ud.down
        ud.down = true;
        ud.rep = false;
        ud.presses = ud.presses + 1;
    else
        ud.rep = true;
        ud.repeats = ud.repeats + 1;
    end
    ud.last = tic;
    return
end
if ud.down
    ud.releases = ud.releases + 1;
else
    ud.idleReleases = ud.idleReleases + 1;
end
ud.down = false;
ud.rep = false;
ud.last = tic;
end

function [down, rep, abort] = focusWatch(down, rep, gap)
% After auto-repeat has been seen, silence means the release was lost
% (typical when the figure loses focus on Windows). Before the first
% repeat, allow the OS initial delay, which can be longer than a second.
abort = false;
if ~down
    return
end
if rep && gap > 0.22
    abort = true;
elseif ~rep && gap > 1.25
    abort = true;
end
if abort
    down = false;
    rep = false;
end
end
