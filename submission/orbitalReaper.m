function varargout=orbitalReaper(op,a,b,c)
if nargin==0,play([],inf);return;end
if op==1
if nargin<3,b=1;end
varargout{1}=newG(a,b);
elseif op==2
if nargin<4,c=false;end
varargout{1}=stepG(a,logical(b),logical(c));
elseif op==3
S=a;for i=1:size(b,1)
d=b(i,1)~=0;for k=1:b(i,2),S=stepG(S,d,false);end
end
varargout{1}=S;
elseif op==4
play(a,b);
end
end
function play(seed,nFrames)
if nargin<1||isempty(seed),seed=mod(floor(now*86400),2147483646)+1;end
if nargin<2||isempty(nFrames),nFrames=inf;end
vis='on';if isfinite(nFrames),vis='off';end
C=K();S=newG(seed,1);f=figure('Color',[0 0 .06],'MenuBar','none','Visible',vis);ax=axes('Parent',f);hold(ax,'on');axis(ax,[-3.7 3.7 -3.7 3.7]);axis(ax,'equal','off');[xs,ys]=stars(S.seed);plot(ax,xs,ys,'.','Color',[.7 .8 1]);rectangle('Parent',ax,'Position',[-.4 -.4 .8 .8],'Curvature',[1 1],'FaceColor',[.15 .3 .6]);ph=plot(ax,0,0,'^','Color',[.4 1 1]);mk=gobjects(3);sy='s^d';co=[.4 1 .5;1 .5 .2;.8 .4 1];for k=1:3,mk(k)=plot(ax,nan,nan,sy(k),'Color',co(k,:));end
ps=plot(ax,nan,nan,'.','Color',[1 .9 .3]);qs=plot(ax,nan,nan,'.','Color',[1 .3 .3]);ht=text(ax,-3.5,-3.4,'','Color',[.9 1 1]);mg=text(ax,-2,.4,'','Color',[1 1 1],'Visible','off');ud=key0();f.UserData=ud;f.WindowKeyPressFcn=@onP;f.WindowKeyReleaseFcn=@onR;acc=0;prev=tic;fr=0;while isgraphics(f)&&fr<nFrames
drawnow;if ~isgraphics(f),break;end
fr=fr+1;ud=f.UserData;w=min(.1,max(0,toc(prev)));prev=tic;ab=0;if ud.down,[ud.down,ud.rep,ab]=watch(ud.down,ud.rep,toc(ud.last));end
acc=acc+w;n=0;while acc>=C.dt&&n<5,S=stepG(S,ud.down,ab);ab=0;acc=acc-C.dt;n=n+1;end
if isgraphics(f),f.UserData=ud;drawG(S,ph,mk,ps,qs,ht,mg);end
end
if isgraphics(f)&&isfinite(nFrames),close(f);end
end
function onP(~,e),key(e,1);end
function onR(~,e),key(e,2);end
function key(e,k)
if ~isprop(e,'Key')||~strcmp(e.Key,'space'),return;end
f=gcbf;if isempty(f)||~isgraphics(f),return;end
u=f.UserData;if k==1,if ~u.down,u.down=1;u.rep=0;else,u.rep=1;end
else,u.down=0;u.rep=0;end
u.last=tic;f.UserData=u;
end
function u=key0()
u.down=0;u.rep=0;u.last=tic;
end
function [d,r,a]=watch(d,r,g)
a=0;if d&&((r&&g>.22)||(~r&&g>1.25)),a=1;d=0;r=0;end
end
function S=stepG(S,down,lost)
if nargin<3,lost=false;end
C=K();down=logical(down);if lost,S.phase=0;S.charge=0;down=false;end
if S.mode~=1,S=menu(S,down);return;end
if S.fresh
if ~down,S.fresh=0;end
down=false;
end
ev=false;if S.phase==0&&down
S.phase=1;S.t0=S.t;S.hd=0;
elseif S.phase==1&&~down
ev=true;S.hd=S.t-S.t0;S.phase=0;
elseif S.phase==1
S.hd=S.t-S.t0;
else
S.hd=0;
end
if S.phase==1||ev,S.charge=1-exp(-S.hd/C.tau);end
S=phys(S,C);S=aim(S,C);S=foes(S,C);S=hit(S,C);if ev,S=fire(S,C);end
if S.hp<=0
S.hp=0;S.mode=3;S.phase=0;S.charge=0;
elseif ~any(S.E(:,1)>0)
S.score=S.score+500+max(0,round(1200-20*S.lt))+round(300*S.fuel);S.mode=2;S.phase=0;S.charge=0;
end
S.t=S.t+C.dt;S.lt=S.lt+C.dt;
end
function S=menu(S,down)
if S.fresh
if ~down,S.fresh=0;end
return
end
if ~down,S.phase=0;S.charge=0;return;end
if S.phase~=0,return;end
if S.mode==0
S.mode=1;
elseif S.mode==2
sc=S.score;hp=S.hp;kk=S.kills;ff=S.nF;hh=S.nH;S=newG(S.seed,S.level+1);S.score=sc;S.hp=hp;S.kills=kk;S.nF=ff;S.nH=hh;S.mode=1;
elseif S.mode==3
S=newG(S.seed,1);S.mode=1;
end
S.fresh=1;S.phase=0;S.charge=0;S.t0=0;S.hd=0;
end
function S=phys(S,C)
dt=C.dt;r2=max(S.px^2+S.y^2,1e-8);r3=r2*sqrt(r2);ax=-C.mu*S.px/r3;ay=-C.mu*S.y/r3;if S.phase==1&&S.fuel>0
r=hypot(S.px,S.y);ax=ax+C.ta*S.px/r;ay=ay+C.ta*S.y/r;S.fuel=max(0,S.fuel-C.fb*dt);
elseif S.phase==0
S.fuel=min(1,S.fuel+C.fr*dt);
end
S.vx=S.vx+ax*dt;S.vy=S.vy+ay*dt;S.px=S.px+S.vx*dt;S.y=S.y+S.vy*dt;S=wall(S,C.rp+C.sr,1,28);S=wall(S,C.ra-C.sr,0,16);
end
function S=wall(S,lim,inn,dmg)
r=hypot(S.px,S.y);f='aL';if inn,f='pL';end
if inn&&r<lim||~inn&&r>lim
if r<1e-8,nx=1;ny=0;else,nx=S.px/r;ny=S.y/r;end
p=lim+(2*inn-1)*.02;S.px=nx*p;S.y=ny*p;vr=S.vx*nx+S.vy*ny;if (2*inn-1)*vr<0,S.vx=S.vx-1.8*vr*nx;S.vy=S.vy-1.8*vr*ny;end
if ~S.(f),S.hp=S.hp-dmg;S.(f)=1;end
elseif abs(r-lim)>.12,S.(f)=0;end
end
function S=aim(S,C)
r=max(hypot(S.px,S.y),1e-8);rh=[S.px S.y]/r;m=C.m0+C.m1*S.charge;best=-inf;ba=0;bt=inf;bs=1;b=rh;fd=0;
for i=1:C.nE
if S.E(i,1)<=0,continue;end
R=S.E(i,3:4)-[S.px S.y];W=S.E(i,5:6)-[S.vx S.vy];t=lead(W*W'-m*m,2*(R*W'),R*R');
if isempty(t),continue;end
u=(R/t+W)/m;un=hypot(u(1),u(2));if un<1e-6,continue;end
u=u/un;al=abs(u*rh');if al-.22*t>best
best=al-.22*t;ba=al;bt=t;bs=sign(u*rh');if bs==0,bs=1;end
b=u;fd=1;end
end
if ~fd||ba<C.cone||bt>C.tf
S.aimx=bs*rh(1);S.aimy=bs*rh(2);S.lock=fd*ba*max(0,1-bt/3)*.45;
else,S.aimx=b(1);S.aimy=b(2);S.lock=ba*max(0,1-.25*bt);end
end
function t=lead(a,b,c)
t=[];if abs(a)<1e-9,if abs(b)>1e-9&&-c/b>.02,t=-c/b;end,return;end
d=b*b-4*a*c;if d<0,return;end
u=[(-b-sqrt(d))/(2*a) (-b+sqrt(d))/(2*a)];u=u(u>.02);if ~isempty(u),t=min(u);end
end
function S=fire(S,C)
u=S.charge;dmg=C.dm*u;spd=C.m0+C.m1*u;vx=S.vx+spd*S.aimx;vy=S.vy+spd*S.aimy;spawned=false;for i=1:C.nP
if S.P(i,1)<=0,S.P(i,:)=[1 S.px S.y vx vy dmg 0 C.qr*(.5+u)];spawned=true;break;end
end
if spawned,S.nF=S.nF+1;S.fuel=max(0,S.fuel-(.10+.28*u));end
S.charge=0;
end
function S=foes(S,C)
dt=C.dt;G=[0 0 0;.22 .16 1;.35 .2 .55];
for i=find(S.E(:,1)>0)'
p=S.E(i,3:4);v=S.E(i,5:6);r2=max(p*p',1e-8);a=-C.mu*p/(r2*sqrt(r2));
r=max(hypot(p(1),p(2)),1e-6);rh=p/r;th=[-rh(2) rh(1)];vt=v*th';cls=S.E(i,2);des=S.E(i,9);
if cls==2,des=min(2.65,max(1,hypot(S.px,S.y)));end
a=a+(G(cls,1)*(des-r))*rh+(G(cls,2)*(G(cls,3)*sqrt(C.mu/r)-vt))*th;
v=v+a*dt;p=p+v*dt;S.E(i,3:6)=[p v];
if S.E(i,12)>0
S.E(i,8)=S.E(i,8)-dt;S.E(i,11)=S.E(i,8)<C.tg&&S.E(i,8)>0;
if S.E(i,8)<=0,S.E(i,8)=S.E(i,12);S.E(i,11)=0;S=shoot(S,i,C);end
end
end
end
function S=shoot(S,i,C)
x=S.E(i,3);y=S.E(i,4);vx=S.E(i,5);vy=S.E(i,6);
if S.E(i,2)==2
d=[S.px-x S.y-y];d=d/(norm(d)+1e-6);S=addQ(S,x,y,vx*.25+.7*d(1),vy*.25+.7*d(2),12,C);
else
for k=0:5,a=k*pi/3+S.t;S=addQ(S,x,y,vx*.2+.48*cos(a),vy*.2+.48*sin(a),10,C);end
end
end
function S=addQ(S,x,y,vx,vy,dmg,C)
for k=1:C.nQ
if S.Q(k,1)<=0,S.Q(k,:)=[1 x y vx vy dmg 0 C.qr];return;end
end
end
function S=hit(S,C)
dt=C.dt;hitThis=false;expired=false;
for i=1:C.nP
if S.P(i,1)<=0,continue;end
o=S.P(i,2:3);n=o+S.P(i,4:5)*dt;S.P(i,2:3)=n;S.P(i,7)=S.P(i,7)+dt;dmg=S.P(i,6);struck=false;
for e=1:C.nE
if S.E(e,1)>0&&sweep(o(1),o(2),n(1),n(2),S.E(e,3),S.E(e,4),S.P(i,8)+C.er(S.E(e,2)))
S.E(e,7)=S.E(e,7)-dmg;killed=S.E(e,7)<=0;if killed,S.E(e,1)=0;S.E(e,11)=0;end
S=award(S,dmg,killed);S.P(i,1)=0;struck=true;hitThis=true;break
end
end
if ~struck&&(S.P(i,7)>C.pl||hypot(n(1),n(2))<C.rp||hypot(n(1),n(2))>C.ra+.6),S.P(i,1)=0;expired=true;end
end
for i=1:C.nQ
if S.Q(i,1)<=0,continue;end
o=S.Q(i,2:3);n=o+S.Q(i,4:5)*dt;S.Q(i,2:3)=n;S.Q(i,7)=S.Q(i,7)+dt;
if sweep(o(1),o(2),n(1),n(2),S.px,S.y,C.qr+C.sr),S.hp=S.hp-S.Q(i,6);S.Q(i,1)=0;S.combo=0;
elseif S.Q(i,7)>C.ql||hypot(n(1),n(2))>C.ra+.8||hypot(n(1),n(2))<C.rp,S.Q(i,1)=0;end
end
for e=1:C.nE
if S.E(e,1)<=0,S.ram(e)=0;continue;end
d=hypot(S.E(e,3)-S.px,S.E(e,4)-S.y);
if d<C.sr+C.er(S.E(e,2)),if ~S.ram(e),S.hp=S.hp-18;end,S.ram(e)=1;else,S.ram(e)=0;end
end
if expired&&~hitThis,S.combo=0;end
end
function S=award(S,dmg,killed)
S.combo=S.combo+1;S.score=S.score+(40+round(25*dmg))*S.combo;S.nH=S.nH+1;if killed,S.score=S.score+250*S.combo;S.kills=S.kills+1;end
end
function h=sweep(x0,y0,x1,y1,cx,cy,r)
d=x1-x0;e=y1-y0;L=d*d+e*e;t=0;if L>1e-12,t=min(1,max(0,((cx-x0)*d+(cy-y0)*e)/L));end
h=(x0+t*d-cx)^2+(y0+t*e-cy)^2<=r*r;
end
function S=newG(seed,level)
seed=+seed;level=+level;C=K();S.seed=seed;S.level=level;S.mode=0;S.t=0;S.lt=0;S.score=0;S.combo=0;S.hp=C.hp0;S.fuel=1;S.charge=0;S.phase=0;S.fresh=0;S.t0=0;S.hd=0;S.lock=0;S.aimx=1;S.aimy=0;S.kills=0;S.nF=0;S.nH=0;S.pL=0;S.aL=0;S.rng=max(mod(seed*10007+level*97+12345,2^32),1);
[u,S.rng]=lcg(S.rng,1);ang=2*pi*u;r=C.r0;v=sqrt(C.mu/r);S.px=r*cos(ang);S.y=r*sin(ang);S.vx=-v*sin(ang);S.vy=v*cos(ang);S.E=zeros(C.nE,12);S.P=zeros(C.nP,8);S.Q=zeros(C.nQ,8);S.ram=zeros(C.nE,1);spec=roster(level,C);if level>=6
for i=1:size(spec,1)
[u,S.rng]=lcg(S.rng,2);cls=1+(u(1)>.55)+(u(1)>.84);per=(cls>1)*max(1.8,3.4-.08*level);
spec(i,:)=[cls 1.05+1.55*u(2) per];
end
end
for i=1:size(spec,1)
cls=spec(i,1);rad=spec(i,2);per=spec(i,3);[u,S.rng]=lcg(S.rng,1);ang=2*pi*u;x=rad*cos(ang);y=rad*sin(ang);
vt=sqrt(C.mu/rad);if cls==3,vt=.62*vt;end
hp=C.eh(cls);if level>=6,hp=hp*(1+.08*(level-5));end
q=0;if per>0,[u,S.rng]=lcg(S.rng,1);q=per*(.75+.25*u);end
S.E(i,:)=[1 cls x y -vt*sin(ang) vt*cos(ang) hp q rad ang 0 per];
end
end
function spec=roster(level,C)
if level==1,spec=[1 2.05 0];
elseif level==2,spec=[1 1.2 0;1 1.8 0;1 2.4 0];
elseif level==3,spec=[1 1.05 0;1 1.45 0;1 2.1 0;1 2.6 0];
elseif level==4,spec=[1 1.3 0;1 2.2 0;2 1.9 2.8];
elseif level==5,spec=[1 2.3 0;2 1.55 2.6;3 2.5 3.6];
else,spec=zeros(min(C.nE,2+floor(level/2)),3);end
end
function drawG(S,ph,mk,ps,qs,ht,mg)
set(ph,'XData',S.px,'YData',S.y);
for k=1:3,m=S.E(:,1)>0&S.E(:,2)==k;set(mk(k),'XData',S.E(m,3),'YData',S.E(m,4));end
[x,y]=alive(S.P);set(ps,'XData',x,'YData',y);[x,y]=alive(S.Q);set(qs,'XData',x,'YData',y);
set(ht,'String',sprintf('SC%d LV%d HP%d FU%d CH%d LK%d',round([S.score S.level S.hp 100*S.fuel 100*S.charge 100*S.lock])));
if S.mode==1,set(mg,'Visible','off');return;end
if S.mode==0,t=sprintf('Hold SPACE, release fires');
elseif S.mode==2,t=sprintf('LEVEL %d CLEAR',S.level);else,t=sprintf('GAME OVER %d',round(S.score));end
set(mg,'String',t,'Visible','on');
end
function [x,y]=alive(M)
m=M(:,1)>0;x=[nan;M(m,2)];y=[nan;M(m,3)];
end
function [xs,ys]=stars(seed)
s=mod(seed*1009+7919,2^32);s=max(s,1);
[u,~]=lcg(s,96);xs=-3.45+6.9*u(1:2:end);ys=-3.45+6.9*u(2:2:end);
end
function [u,s]=lcg(s,n)
u=zeros(1,n);for k=1:n,s=mod(1664525*s+1013904223,2^32);u(k)=s/2^32;end
end
function C=K()
C.mu=.40;C.r0=1.60;C.rp=.40;C.ra=3.20;C.dt=1/60;C.ta=.25;C.fb=.40;C.fr=.16;C.tau=1;C.dm=6;C.sr=.07;C.qr=.022;C.m0=.40;C.m1=3.60;C.cone=.82;C.tf=1.40;C.nE=8;C.nP=16;C.nQ=16;C.hp0=100;C.pl=2.4;C.ql=4.5;C.tg=.70;C.er=[.055 .08 .14];C.eh=[4.2 8.5 14];
end