function tests = testSubmission
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'submission'));
tests = functiontests(localfunctions);
end

function testCharacterBudget(tc)
root = fileparts(fileparts(mfilename('fullpath')));
file = fullfile(root, 'submission', 'orbitalReaper.m');
txt = fileread(file);
raw = numel(txt);
clean = numel(strrep(txt, char(13), ''));
utf8 = numel(unicode2native(txt, 'UTF-8'));
verifyLessThanOrEqual(tc, raw, 10000);
verifyLessThanOrEqual(tc, clean, 10000);
verifyLessThanOrEqual(tc, utf8, 10000);
fprintf('submission chars raw=%d clean=%d utf8=%d\n', raw, clean, utf8);
end

function testNoProhibitedIdentifiers(tc)
root = fileparts(fileparts(mfilename('fullpath')));
src = fileread(fullfile(root, 'submission', 'orbitalReaper.m'));
list = fileread(fullfile(root, 'docs', 'PROHIBITED_FUNCTIONS.md'));
names = regexp(list, '(?m)^- ([A-Za-z_][A-Za-z0-9_]*)\s*$', 'tokens');
hits = {};
for i = 1:numel(names)
    name = names{i}{1};
    pat = ['(?<![A-Za-z0-9_])' name '(?![A-Za-z0-9_])'];
    if ~isempty(regexp(src, pat, 'once'))
        hits{end + 1} = name; %#ok<AGROW>
    end
end
verifyEmpty(tc, hits);
verifyEmpty(tc, regexp(src, '!', 'once'));
end

function testScriptedLevelOne(tc)
sched = [1 1; 0 1142; 1 33; 0 1; 1 33; 0 20];
S = orbitalReaper(3, orbitalReaper(1, 7, 1), sched);
verifyEqual(tc, S.mode, 2);
verifyEqual(tc, S.score, 2148);
verifyGreaterThanOrEqual(tc, S.kills, 1);
verifyGreaterThan(tc, S.hp, 0);
verifyEqual(tc, S.nF, 2);
end

function testHoldDoesNotRepeatFire(tc)
S = orbitalReaper(1, 7, 1);
S = orbitalReaper(2, S, true);
S = orbitalReaper(2, S, false);
for k = 1:400
    S = orbitalReaper(2, S, true);
end
verifyEqual(tc, S.nF, 0);
verifyLessThan(tc, S.fuel, 0.05);
end

function testOneHoldFiresOnce(tc)
S = armed();
S = orbitalReaper(3, S, [1 400; 0 1]);
verifyEqual(tc, S.nF, 1);
verifyLessThan(tc, S.P(1, 6), 6);
end

function testShortTapsFireOnceEach(tc)
S = armed();
for k = 1:8
    before = S.nF;
    S = orbitalReaper(3, S, [1 5; 0 1]);
    verifyEqual(tc, S.nF, before + 1);
end
verifyEqual(tc, S.nF, 8);
verifyLessThan(tc, 6 * (1 - exp(-5 / 60)), 6 * (1 - exp(-0.5)));
end

function testDamageStepResponse(tc)
shortHold = releaseAfter(30);
longHold = releaseAfter(120);
u05 = 1 - exp(-0.5);
u20 = 1 - exp(-2);
verifyEqual(tc, shortHold.nF, 1);
verifyEqual(tc, longHold.nF, 1);
verifyEqual(tc, shortHold.P(1, 6), 6 * u05, 'AbsTol', 1e-9);
verifyEqual(tc, longHold.P(1, 6), 6 * u20, 'AbsTol', 1e-9);
verifyGreaterThan(tc, longHold.P(1, 6), shortHold.P(1, 6));
verifyLessThan(tc, longHold.P(1, 6), 6);
d01 = 6 * (1 - exp(-1));
verifyGreaterThan(tc, d01, 6 * u20 - d01);
end

function S = armed()
S = orbitalReaper(1, 7, 1);
S = orbitalReaper(2, S, true);
S = orbitalReaper(2, S, false);
S.hp = 1e6;
end

function S = releaseAfter(nHold)
S = orbitalReaper(3, armed(), [1 nHold; 0 1]);
end

function testFigureSmoke(tc)
orbitalReaper(4, 7, 4);
verifyTrue(tc, true);
end

function testMatchesDevelopment(tc)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'dev'));
sched = [1 1; 0 1142; 1 33; 0 1; 1 33; 0 20];
A = orRun(orNewGame(7, 1), sched);
B = orbitalReaper(3, orbitalReaper(1, 7, 1), sched);
verifyEqual(tc, B.mode, A.mode);
verifyEqual(tc, B.score, A.score);
verifyEqual(tc, B.px, A.px, 'AbsTol', 1e-9);
verifyEqual(tc, B.y, A.py, 'AbsTol', 1e-9);
verifyEqual(tc, B.fuel, A.fuel, 'AbsTol', 1e-9);
end
