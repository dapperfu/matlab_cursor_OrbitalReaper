function S = orRun(S, sched)
%ORRUN Apply an open-loop SPACE schedule.
%   sched is N x 2. Column 1 is 0 or 1. Column 2 is the step count.

for i = 1:size(sched, 1)
    down = sched(i, 1) ~= 0;
    for k = 1:sched(i, 2)
        S = orStep(S, down, false);
    end
end
end
