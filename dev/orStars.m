function [xs, ys] = orStars(seed)
%ORSTARS Deterministic starfield on its own LCG stream.
%   Level generation never calls this, so drawing stars cannot change a level.

n = 48;
xs = zeros(1, n);
ys = zeros(1, n);
s = mod(double(seed) * 1009 + 7919, 4294967296);
if s == 0
    s = 1;
end
for i = 1:n
    [u, s] = orLcg(s, 2);
    xs(i) = -3.45 + 6.9 * u(1);
    ys(i) = -3.45 + 6.9 * u(2);
end
end
