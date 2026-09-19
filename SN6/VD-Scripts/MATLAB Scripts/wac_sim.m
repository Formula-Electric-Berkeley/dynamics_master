clear all
clc
% f=[ 3.0     0.5     0.25     1.25]
% m=[-0.018   0.025   0.2      2.8]

f = [2.5309    0.28824   0.20598  1.5077];   % 4 term Pacejka-lite Fy
m = [-0.0038645  0.015978  0.18494  3.0586]; % 4 term Pacejka-lite Mz

% f=[12.872 1.8752 .03235 1.4042]  % linear coernering stiffnesses.
% m=[0 0 0 0]       % no aligning moment

WF       = 90;        %Front 'weight' (kg)
WR       = 110;       % Rear 'weight' (kg)
L        = 1600;      % Wheelbase (mm)
SR       = 5;         % Overall steer ratio (deg/deg)
SPEED    = 80;        % Speed (kph)
ENF      = .5;        % Front aligning moment steer compliance (deg/100 Nm per wheel)
EF       = .05        % Front roll steer (deg/deg)
ER       = .01        % Rear roll steer (deg/deg)
% Now for some tricky stuff:
WB       = L/1000;           % Convert to meters
U        = SPEED./3.6;       % m/sec
A        = WB*WR/(WF+WR);    % C.G. position behind fron axle
B        = WB*WF/(WF+WR);    % Behind rear axle
IZZ      = (WF+WR)*A*B;      % Inertia estimate
R        = 0;                % initial condition for yaw rate.
BETA     = 0;                % initial condition for sideslip
ALPHAF   = 0;
ALPHAR   = 0;
X        = 0;
ROLL_VEL = 0;
ROLL     = 0;

WLF      = WF/2;  % Individual wheel loads
WRF      = WF/2;
WLR      = WR/2;
WRR      = WR/2;

caf = Pacejka4_Model(f,[-1, -9.8*WLF]) % Cornering Stiffness (N/deg)
car = Pacejka4_Model(f,[-1, -9.8*WLR])

naf = Pacejka4_Model(m,[-1, -9.8*WLF]) % Aligning stiffness (Nm/deg)
nar = Pacejka4_Model(m,[-1, -9.8*WLR])

PTrailf = 1000*naf/caf  % Pneumatic trail (mm)
PTrailr = 1000*nar/car

SWA_MAX = 10 ; %deg
pwidth  = 4.5;
power   = 250;
tmid    = 4.;

dt      =.01;             % Integration interval
hb      = waitbar(0,'Please wait...');
tmax    = 3.;
deg2rad = 180/pi;
MaxSlipRate = 30;  % no point in going any further.  (deg/g)

ROLL_GAIN = 3.
ROLL_FREQ = 2.5
ROLL_ZETA = .707

Wn  = ROLL_FREQ * 2 * pi;

N0  = ROLL_GAIN * Wn^2;
D2  = 1;
D1  = 2 * ROLL_ZETA * Wn;
D0  = Wn^2;

n = 0;
for T = 0:dt:tmax;   % 1 second ought to do it.
    n = n+1;
    try
        waitbar(T/tmax)
%         STEER  = 5*T;  % perfect step

        STEER    = (-2./pi*atan(abs((T-tmid)./(pwidth/2)).^power)+1.).*SWA_MAX; % imperfect step
        DELTAF   =  STEER/SR;
        FYLF     =  Pacejka4_Model(f,[ALPHAF,-9.806*WLF]); %Nonlinear tire FY representation
        FYRF     =  Pacejka4_Model(f,[ALPHAF,-9.806*WRF]); %
        FYLR     =  Pacejka4_Model(f,[ALPHAR,-9.806*WLR]); %
        FYRR     =  Pacejka4_Model(f,[ALPHAR,-9.806*WRR]); %
        NLF      =  Pacejka4_Model(m,[ALPHAF,-9.806*WLF]); %Nonlinear tire MZ representation
        NRF      =  Pacejka4_Model(m,[ALPHAF,-9.806*WRF]); %
        NLR      =  Pacejka4_Model(m,[ALPHAR,-9.806*WLR]); %
        NRR      =  Pacejka4_Model(m,[ALPHAR,-9.806*WRR]); %

        EF_STEER =  -ROLL*EF;
        ER_STEER =  -ROLL*ER;
        USNF     = -ENF/200*(NLF+NRF);    % Understeer from front aligning torque
        ALPHAF   =  USNF + BETA + A*R/U - DELTAF + EF_STEER;  % Degrees
        ALPHAR   =  BETA - B*R/U + ER_STEER;
        RD       =  deg2rad*(A*(FYLF+FYRF) - B*(FYLR+FYRR) +NLF +NRF +NLR +NRR) /IZZ;
        BETAD    =  deg2rad*(FYLF+FYRF+FYLR+FYRR)/(WF+WR)/U - R;
        R        =  R + RD*dt;
        BETA     =  BETA + BETAD*dt;
        AYG      =  U*(R + BETAD)/deg2rad/9.806;    % lateral gs
        dwf      =  AYG * 25;     % Just some brute force front load xfer coefficients
        dwr      =  AYG * 25;      % Same idea for the rear...
        WLF      =  WF/2 + dwf;
        WRF      =  WF/2 - dwf;
        WLR      =  WR/2 + dwr;
        WRR      =  WR/2 - dwr;

        ROLL_ACC =  AYG - D1*ROLL_VEL - D0*X; % Input - denominator terms
        ROLL_VEL =  ROLL_VEL + ROLL_ACC * dt;   % integral of roll acceleration
        X        =  X + ROLL_VEL * dt;    % integral of roll velocity  
        ROLL     = -X * N0;   % numerator * Wn^2 * steady state gain
        
% Collect data at each time step:        
        wlf(n)   = 9.806*WLF;
        wrf(n)   = 9.806*WRF;
        wlr(n)   = 9.806*WLR;
        wrr(n)   = 9.806*WRR;
        fylf(n)  = FYLF;
        fyrf(n)  = FYRF;
        fylr(n)  = FYLR;
        fyrr(n)  = FYRR;
        mzlf(n)  = NLF;
        mzrf(n)  = NRF;
        mzlr(n)  = NLR;
        mzrr(n)  = NRR;
        steer(n) = STEER;
        alphaf(n)= ALPHAF;
        alphar(n)= ALPHAR;
        r(n)     = R;
        beta(n)  = BETA;
        ayg(n)   = AYG;
        deltaf(n)= DELTAF;
        roll(n)  = ROLL;
        rollvel(n)=ROLL_VEL;
        rollacc(n)=ROLL_ACC;
        time(n)   = T;
    catch
        'Stopped'
        break
    end
end
close(hb)


%sliprate = (gradient(-alphaf)./gradient(ayg));

%inx      = find(sliprate > MaxSlipRate & ayg > .5,1);
%maxlat   = ayg(inx)

%% You'll need this:
% function fy = Pacejka4_Model(P,X)
% x1  =  X(:,1);  %Slip
% x2  =  X(:,2);  % Fz
% D1  =  P(1);
% D2  =  P(2);
% B   =  P(3);
% C   =  P(4);
% D   =  (D1 + D2/1000.*x2).*x2;   % peak value (normalized
% fy  =  D.*sin(C.*atan(B.*x1));

figure('Name','Tire Model Lateral Force Inputs and Outputs')
plot3(alphaf,wlf,fylf,'ro')
hold on
plot3(alphaf,wrf,fyrf,'bo')
plot3(alphar,wlr,fylr,'ko')
plot3(alphar,wrr,fyrr,'mo')
grid on
xlabel('Tire Slip Angle (deg)')
ylabel('Tire Fz (N)')
zlabel('Tire Fy (N)')
legend('Left Front','Right Front','Left Rear','Right Rear'),legend BoxOff

figure('Name','Tire Model Aligning Moment Inputs and Outputs')
plot3(alphaf,wlf,mzlf,'ro')
hold on
plot3(alphaf,wrf,mzrf,'bo')
plot3(alphar,wlr,mzlr,'ko')
plot3(alphar,wrr,mzrr,'mo')
grid on
xlabel('Tire Slip Angle (deg)')
ylabel('Tire Fz (N)')
zlabel('Tire Mz (Nm)')
legend('Left Front','Right Front','Left Rear','Right Rear'),legend BoxOff

Ackpg=9.8*deg2rad*WB/U^2  % use this for constant speed steer ramp input.
K = gradient(steer./SR,ayg) -Ackpg ;
figure
plot(ayg,K)
ylim([-2 5])
grid on
xlabel('Lateral Acceleration (g)')
ylabel('Understeer (deg/g)')

figure
plot(time,steer/SWA_MAX,time,r/r(end),'b',time,beta/beta(end),time,ayg/ayg(end),'k',time,roll/roll(end),'m')
xlim([1.5 tmax])
grid on
xlabel('Time (sec)')
ylabel('Normalized by Steady State Value')
legend ('Steer Angle','YawVelocity','Side-Slip Angle','Lateral Acceleration','Roll Angle')
legend('location','SouthEast')
swad= max(diff(steer))/dt;

inx5    = find(beta/beta(end)   >= .90); % 90% roll point
inx4    = find(r/r(end)   >= .90); % 90% roll point
inx3    = find(roll/roll(end)   >= .90); % 90% roll point
inx2    = find(ayg/ayg(end)     >= .90); % 90% Ay point
inx1    = find(steer/steer(end) >= .50); % 50% steer point
LART    = (inx2(1) - inx1(1))*dt  % Lateral Acceleration Response Time (sec)
ROLLRT  = (inx3(1) - inx1(1))*dt  % Roll Response Time (sec)
YAWVRT  = (inx4(1) - inx1(1))*dt  % Yaw velocity Response Time (sec)
BETART  = (inx5(1) - inx1(1))*dt  % Sideslip Response Time (sec)

text(1.51,.9,{['CAF = ' num2str(caf,4) ' N/deg'],['CAR = ' num2str(car,4) ' N/deg'],...
    ['PTrail_F = ' num2str(PTrailf,3) ' mm'],['PTrail_R = ' num2str(PTrailr,3) ' mm'],...
    ['\tau_A_y = ' num2str(LART,3) ' sec'],...
    ['\tau_R_o_l_l = ' num2str(ROLLRT,3) ' sec'],... 
    ['\tau_\beta    = ' num2str(BETART,3) ' sec'],... 
    ['\tau_R   = ' num2str(YAWVRT,3) ' sec']})