# Prohibited functions

Source: MATLAB Central 25th Anniversary Contest rules, section "MATLAB One-button Game Mini Hack".

Page: https://www.mathworks.com/matlabcentral/contests/25th-anniversary-contest-prizes-rules.html#onebuttonminihack

Retrieved: 2026-11-04. The fetch succeeded. This is the complete list printed on that page, plus the bang operator.

Entries may not use the bang (`!`) operator.

Entries may not use these functions:

- thingSpeakRead
- actxcontrol
- actxserver
- addpath
- arrayviewfunc
- assignin
- builtin
- cd
- chdir
- computer
- copyfile
- csvread
- csvwrite
- dbstack
- dbstop
- delete
- diary
- dir
- dlmread
- dos
- echo
- edit
- error
- eval
- evalc
- evalin
- execute
- exit
- fclose
- feature
- feval
- fgetl
- fgets
- finfo
- fopen
- ftp
- get_param
- getpref
- help
- hgsave
- import
- imread
- inline
- inlineeval
- inmem
- input
- java
- jpropeditutils
- keyboard
- lasterr
- lasterror
- load
- lookfor
- ls
- matlabpath
- mbuild
- mex
- mislocked
- mlock
- more
- movefile
- munlock
- path
- pause
- perl
- print
- printdlg
- pwd
- quit
- regexp
- rethrow
- rmpath
- run
- save
- sendmail
- set_param
- setpref
- str2func
- system
- system_dependent
- type
- uicontextmenu
- uicontrol
- uigetfile
- uimenu
- uiputfile
- unix
- urlread
- web
- webread
- websave
- webwrite
- what
- which
- who
- whos
- xmlread
- sound
- soundsc
- audioplayer
- audiorecorder
- audiodevinfo
- beep
- playblocking
- py
- pyrun
- pyrunfile
- NET
- System
- Microsoft
- javaObject
- javaMethod
- javaArray

## How the submission is checked

`tests/testSubmission.m` scans `submission/orbitalReaper.m` for these names as whole identifiers and for a bang operator used as a shell escape. Comments are included in the scan, so the submission must not mention these names even in comments. The development tree may use `addpath`, `error`, and `regexp` because it is not the entry.

The game loop must not call `pause`. Timing uses `drawnow`, `tic`, and `toc`. Graphics objects are hidden by setting `Visible` rather than calling `delete`.
