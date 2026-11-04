function [u, s] = orLcg(s, n)
%ORLCG Owned numerical-recipes LCG. Does not touch MATLAB rng.
%   s is a double in [0, 2^32). The multiplier product stays inside the
%   exact integer range of double, so the stream is reproducible.

if nargin < 2
    n = 1;
end
u = zeros(1, n);
for k = 1:n
    s = mod(1664525 * s + 1013904223, 4294967296);
    u(k) = s / 4294967296;
end
end
