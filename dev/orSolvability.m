function report = orSolvability(seeds, levels)
%ORSOLVABILITY Separation checks for seeded layouts.
%   This does not prove a level can be won. It records whether the
%   placement rules kept a gap around the planet, the player, and peers.

if nargin < 1
    seeds = 1:20;
end
if nargin < 2
    levels = 1:5;
end
C = orConst();
report.checked = 0;
report.closePlanet = 0;
report.closePlayer = 0;
report.closePeer = 0;
report.examples = {};
for seed = seeds
    for level = levels
        S = orNewGame(seed, level);
        report.checked = report.checked + 1;
        alive = find(S.E(:, 1) > 0);
        for a = 1:numel(alive)
            i = alive(a);
            if hypot(S.E(i, 3), S.E(i, 4)) < C.rp + 0.25
                report.closePlanet = report.closePlanet + 1;
            end
            if hypot(S.E(i, 3) - S.px, S.E(i, 4) - S.py) < 0.70
                report.closePlayer = report.closePlayer + 1;
                report.examples{end + 1} = [seed, level, i]; %#ok<AGROW>
            end
            for b = a + 1:numel(alive)
                j = alive(b);
                if hypot(S.E(i, 3) - S.E(j, 3), S.E(i, 4) - S.E(j, 4)) < 0.50
                    report.closePeer = report.closePeer + 1;
                end
            end
        end
    end
end
end
