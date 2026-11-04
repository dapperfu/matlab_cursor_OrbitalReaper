function gfx = orRender(op, gfx, S, vis)
%ORRENDER Create or update the vector scene.
%   op 'init' builds every graphics object once.
%   op 'draw' writes geometry into those objects.
%   Nothing here is recreated per frame, and nothing is deleted.

if strcmp(op, 'init')
    gfx = initScene(S, vis);
else
    gfx = drawScene(gfx, S);
end
end

function gfx = initScene(S, vis)
if nargin < 2 || isempty(vis)
    vis = 'on';
end
gfx.fig = figure( ...
    'Name', 'Orbital Reaper', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Color', [0.012 0.018 0.045], ...
    'Position', [60 40 860 860], ...
    'Visible', vis);
gfx.ax = axes('Parent', gfx.fig, 'Position', [0.05 0.08 0.90 0.88]);
hold(gfx.ax, 'on');
axis(gfx.ax, 'equal');
xlim(gfx.ax, [-3.7 3.7]);
ylim(gfx.ax, [-3.7 3.7]);
gfx.ax.Visible = 'off';
gfx.ax.Color = 'none';
[xs, ys] = orStars(S.seed);
gfx.stars = plot(gfx.ax, xs, ys, '.', ...
    'Color', [0.55 0.66 0.82], 'MarkerSize', 8);
radii = [1.15 1.60 2.15 2.70];
gfx.ring = gobjects(1, 4);
for i = 1:4
    gfx.ring(i) = rectangle('Parent', gfx.ax, ...
        'Position', [-radii(i), -radii(i), 2 * radii(i), 2 * radii(i)], ...
        'Curvature', [1 1], 'FaceColor', 'none', ...
        'EdgeColor', [0.18 0.26 0.40], 'LineWidth', 0.7);
end
gfx.atmo = rectangle('Parent', gfx.ax, ...
    'Position', [-0.62 -0.62 1.24 1.24], ...
    'Curvature', [1 1], 'FaceColor', 'none', ...
    'EdgeColor', [0.28 0.48 0.85], 'LineWidth', 2);
gfx.planet = rectangle('Parent', gfx.ax, ...
    'Position', [-0.40 -0.40 0.80 0.80], ...
    'Curvature', [1 1], 'FaceColor', [0.08 0.18 0.48], ...
    'EdgeColor', [0.35 0.55 0.95], 'LineWidth', 1.2);
gfx.plume = patch(gfx.ax, [0 0 0], [0 0 0], [1.0 0.55 0.20], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.85, 'Visible', 'off');
gfx.player = patch(gfx.ax, [0 0 0], [0 0 0], [0.35 0.95 1.0], ...
    'EdgeColor', [0.75 1 1], 'LineWidth', 1);
gfx.flash = rectangle('Parent', gfx.ax, ...
    'Position', [-0.2 -0.2 0.4 0.4], 'Curvature', [1 1], ...
    'FaceColor', 'none', 'EdgeColor', [1 0.8 0.35], ...
    'LineWidth', 1.6, 'Visible', 'off');
gfx.enemy = gobjects(1, 8);
for i = 1:8
    gfx.enemy(i) = patch(gfx.ax, [0 0 0], [0 0 0], [0.4 1 0.5], ...
        'EdgeColor', [0.9 1 0.9], 'LineWidth', 1, 'Visible', 'off');
end
gfx.pshots = plot(gfx.ax, nan, nan, '.', 'MarkerSize', 16, ...
    'Color', [1.0 0.92 0.35]);
gfx.qshots = plot(gfx.ax, nan, nan, '.', 'MarkerSize', 13, ...
    'Color', [1.0 0.32 0.38]);
gfx.lock = plot(gfx.ax, nan, nan, '-', 'Color', [0.45 0.95 1], 'LineWidth', 1.1);
gfx.hud = text(gfx.ax, 0, -3.48, '', ...
    'Color', [0.86 0.92 0.98], 'HorizontalAlignment', 'center', ...
    'FontName', 'Consolas', 'FontSize', 11);
gfx.msg = text(gfx.ax, 0, 0.2, '', ...
    'Color', [0.92 0.96 1], 'HorizontalAlignment', 'center', ...
    'FontName', 'Consolas', 'FontSize', 14, 'Visible', 'off');
end

function gfx = drawScene(gfx, S)
if ~isgraphics(gfx.fig)
    return
end
ang = facing(S);
[px, py] = craft(S.px, S.py, ang, 0.18, 0.09);
set(gfx.player, 'XData', px, 'YData', py);
c = min(1, max(0, S.charge));
set(gfx.player, 'FaceColor', [0.30 + 0.65 * c, 0.95, 1]);
if S.burn > 0
    len = 0.10 + 0.22 * S.fuel;
    [qx, qy] = plume(S.px, S.py, ang, len);
    set(gfx.plume, 'XData', qx, 'YData', qy, 'Visible', 'on');
else
    set(gfx.plume, 'Visible', 'off');
end
cols = [0.45 1.00 0.55; 1.00 0.48 0.22; 0.78 0.38 0.95];
for i = 1:8
    if S.E(i, 1) <= 0
        set(gfx.enemy(i), 'Visible', 'off');
        continue
    end
    cls = S.E(i, 2);
    ea = atan2(S.E(i, 6), S.E(i, 5));
    if cls == 2
        [ex, ey] = craft(S.E(i, 3), S.E(i, 4), ea, 0.16, 0.07);
    elseif cls == 3
        [ex, ey] = diamond(S.E(i, 3), S.E(i, 4), 0.16 + 0.05 * S.E(i, 11));
    else
        [ex, ey] = craft(S.E(i, 3), S.E(i, 4), ea, 0.12, 0.08);
    end
    ec = cols(cls, :);
    lw = 1;
    if S.E(i, 11) > 0
        ec = [1 0.95 0.55];
        lw = 2.4;
    end
    set(gfx.enemy(i), 'XData', ex, 'YData', ey, ...
        'FaceColor', cols(cls, :), 'EdgeColor', ec, ...
        'LineWidth', lw, 'Visible', 'on');
end
[sx, sy] = aliveXY(S.P);
set(gfx.pshots, 'XData', sx, 'YData', sy);
[qx, qy] = aliveXY(S.Q);
set(gfx.qshots, 'XData', qx, 'YData', qy);
if S.mode == 1 && S.lock > 0.05
    reach = 0.25 + 0.55 * S.lock;
    set(gfx.lock, 'XData', [S.px, S.px + reach * S.aimx], ...
        'YData', [S.py, S.py + reach * S.aimy]);
else
    set(gfx.lock, 'XData', nan, 'YData', nan);
end
if S.flash > 0
    rad = 0.18 + 0.45 * (1 - S.flash);
    set(gfx.flash, 'Visible', 'on', ...
        'Position', [S.px - rad, S.py - rad, 2 * rad, 2 * rad], ...
        'EdgeColor', [1, 0.75 * S.flash + 0.2, 0.30]);
else
    set(gfx.flash, 'Visible', 'off');
end
hud = sprintf('SCORE %d    LV %d    HP %d    FUEL %d%%    CHG %d%%    LOCK %d%%', ...
    round(S.score), S.level, round(S.hp), round(100 * S.fuel), ...
    round(100 * S.charge), round(100 * S.lock));
set(gfx.hud, 'String', hud);
if S.mode == 0
    set(gfx.msg, 'Visible', 'on', 'String', titleText());
elseif S.mode == 2
    set(gfx.msg, 'Visible', 'on', 'String', ...
        sprintf('LEVEL %d CLEAR\n\nSPACE continues', S.level));
elseif S.mode == 3
    set(gfx.msg, 'Visible', 'on', 'String', ...
        sprintf('GAME OVER\nSCORE %d\n\nSPACE restarts', round(S.score)));
else
    set(gfx.msg, 'Visible', 'off');
end
end

function ang = facing(S)
if S.burn > 0
    r = max(hypot(S.px, S.py), 1e-8);
    tx = S.px / r;
    ty = S.py / r;
    sp = hypot(S.vx, S.vy);
    if sp > 0.05
        ang = atan2(0.45 * ty + 0.55 * S.vy / sp, 0.45 * tx + 0.55 * S.vx / sp);
    else
        ang = atan2(ty, tx);
    end
else
    ang = atan2(S.vy, S.vx);
end
end

function [x, y] = craft(cx, cy, ang, len, wid)
local = [len, 0; -0.65 * len, wid; -0.65 * len, -wid];
[x, y] = rotateShape(local, cx, cy, ang);
end

function [x, y] = plume(cx, cy, ang, len)
local = [-0.08, 0.045; -0.08 - len, 0; -0.08, -0.045];
[x, y] = rotateShape(local, cx, cy, ang);
end

function [x, y] = diamond(cx, cy, s)
local = [s, 0; 0, s * 0.72; -s, 0; 0, -s * 0.72];
[x, y] = rotateShape(local, cx, cy, 0);
end

function [x, y] = rotateShape(local, cx, cy, ang)
ca = cos(ang);
sa = sin(ang);
xr = ca * local(:, 1) - sa * local(:, 2);
yr = sa * local(:, 1) + ca * local(:, 2);
x = xr + cx;
y = yr + cy;
end

function [x, y] = aliveXY(M)
mask = M(:, 1) > 0;
if any(mask)
    x = M(mask, 2);
    y = M(mask, 3);
else
    x = nan;
    y = nan;
end
end

function s = titleText()
s = sprintf([ ...
    'ORBITAL REAPER\n\n' ...
    'Hold SPACE    thrust and charge\n' ...
    'Release       fire one shot\n' ...
    'Coast         refuel and line up\n\n' ...
    'SPACE to launch']);
end
