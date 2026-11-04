function [ax, ay] = orGravity(x, y, mu)
%ORGRAVITY Inverse-square acceleration a = -mu * r / |r|^3.

r2 = x .* x + y .* y;
r2 = max(r2, 1e-8);
r3 = r2 .* sqrt(r2);
ax = -mu .* x ./ r3;
ay = -mu .* y ./ r3;
end
