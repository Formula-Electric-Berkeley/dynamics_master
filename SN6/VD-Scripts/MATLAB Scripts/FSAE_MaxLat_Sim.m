clear

WF      = 164.245;       %Front 'weight' (kg)
WR      = 142.775;       % Rear 'weight' (kg)
L       = 1550;      % Wheelbase (mm)
SR      = 4;         % Overall steer ratio (deg/deg)
SPEED   = 20*3.6;        % Speed (kph)
ENF     =  0.5;     % Front aligning moment steer compliance (deg/100 Nm per wheel)
% Now for some tricky stuff:
WB      = L/1000;           % Convert to meters 
U       = SPEED./3.6;       % m/sec
A       = WB*WR/(WF+WR);    % C.G. position behind fron axle
B       = WB*WF/(WF+WR);    % Behind rear axle
IZZ     = 75;               % Inertia estimate
R       = 0;                % initial condition for yaw rate. 
BETA    = 0;                % initial condition for sideslip
ALPHAF  = 0;
ALPHAR  = 0;

WLF     = WF/2;  % Individual wheel loads
WRF     = WF/2;
WLR     = WR/2;
WRR     = WR/2;

dt      =.001;             % Integration interval
hb      = waitbar(0,'Please wait...');
tmax    = 10;
n       = 0;
deg2rad = 180/pi;
MaxSlipRate = 30;  % no point in going any further.  (deg/g)

function Fy_out = pacejka_Fy(alpha, Fz)
    % Fz: positive vertical load (N)
    % alpha: slip angle (deg)
    % Fy_out: lateral force (N, positive)
    B = -0.34876850845497   + -0.000342768832610576   * Fz + -0.000000132470321272606 * (Fz^2);
    C =  0.550922217610631  + -0.00244368807392709    * Fz + -0.00000123205368392996  * (Fz^2);
    D =  338.398705773254   + -1.97694424258987       * Fz;
    E =  0.355389594938201  +  31.244897244705        * exp(0.0164059211355328 * Fz);
    F = -0.0233809460004577 + -0.000177392227968369   * Fz + -0.000000121225987062682 * (Fz^2);
    Bx = B .* alpha;
    Fy_out = D .* sin(C .* atan(Bx - E .* (Bx - atan(Bx))) + F);  % negate: fit produces negative, we want positive output
end

function mz = pacejka_mz(alpha, Fz)
    % Fz: positive vertical load (N)
    % alpha: slip angle (deg)
    % mz: aligning torque (Nm, negative = restorative)
    Fz_neg = -Fz;
    mz = ((-9.75871128366023 + -0.0586892090580317 .* Fz_neg) .* ...
        sin((2.52648069773574 + -0.000239385032436922 .* Fz_neg) .* ...
        atan((0.296405006141154 + 0.000111723987205492 .* Fz_neg) .* alpha - ...
        (0.374401683472281) .* ((0.296405006141154 + 0.000111723987205492 .* Fz_neg) .* alpha - ...
        atan((0.296405006141154 + 0.000111723987205492 .* Fz_neg) .* alpha)))));
end

for T = 0:dt:tmax   % 1 second ought to do it.
    n=n+1;
    try
        waitbar(T/tmax)
        STEER  = 2 * max(T - 1.0, 0);
        DELTAF = STEER/SR;
        FYLF   =  pacejka_Fy(ALPHAF,-9.8*WLF); %Nonlinear tire FY representation
        FYRF   =  pacejka_Fy(ALPHAF,-9.8*WRF); %
        FYLR   =  pacejka_Fy(ALPHAR,-9.8*WLR); %
        FYRR   =  pacejka_Fy(ALPHAR,-9.8*WRR); % 
        NLF    =  pacejka_mz(ALPHAF,-9.8*WLF); %Nonlinear tire MZ representation
        NRF    =  pacejka_mz(ALPHAF,-9.8*WRF); %
        NLR    =  pacejka_mz(ALPHAR,-9.8*WLR); %
        NRR    =  pacejka_mz(ALPHAR,-9.8*WRR); %

        USNF   = -ENF/200*(NLF+NRF);    % Understeer from front aligning torque
        ALPHAF =  USNF + BETA + A*R/U - DELTAF;
        ALPHAR =  BETA - B*R/U;
        ALPHAF = max(min(ALPHAF, 15), -15);  % clamp to ±15 deg
        ALPHAR = max(min(ALPHAR, 15), -15);
        RD     =  deg2rad*(A*(FYLF+FYRF) - B*(FYLR+FYRR) +NLF +NRF +NLR +NRR) /IZZ;
        BETAD  =  deg2rad*(FYLF+FYRF+FYLR+FYRR)/(WF+WR)/U - R;
        R      =  R+RD*dt;
        BETA   =  BETA+BETAD*dt;
        AYG    =  U*(R + BETAD)/deg2rad/9.8;    % lateral gs
        
        if abs(AYG) > 1.8 || abs(BETAD) > 50 || (n > 10 && abs(AYG - ayg(n-1)) > 0.3)
            disp('Instability detected - stopping')
            break
        end

        dwf    =  AYG * .279 * WF;     % Just some brute force front load xfer coefficients
        dwr    =  AYG * .279 * WR;      % Same idea for the rear...
        WLF    =  WF/2 + dwf; 
        WRF    =  WF/2 - dwf; 
        WLR    =  WR/2 + dwr;
        WRR    =  WR/2 - dwr;
        
        wlf(n)   = 9.8*WLF;
        wrf(n)   = 9.8*WRF;
        wlr(n)   = 9.8*WLR;
        wrr(n)   = 9.8*WRR;
        fylf(n)  = FYLF;
        fyrf(n)  = FYRF;
        fylr(n)  = FYLR;
        fyrr(n)  = FYRR;
        mzlf(n)   = NLF;
        mzrf(n)   = NRF;
        mzlr(n)   = NLR;
        mzrr(n)   = NRR;
        steer(n) = STEER;
        alphaf(n)= ALPHAF;
        alphar(n)= ALPHAR;
        r(n)     = R;
        beta(n)  = BETA;
        ayg(n)   = AYG;
        deltaf(n)= DELTAF;
        time(n)  = T;
    catch
        'Stopped'
        break
    end
end
close(hb)

warning off
sliprate = (gradient(-alphaf)./gradient(ayg));
warning on
inx      = find(sliprate > MaxSlipRate & ayg > .5,1);
maxlat   = ayg(inx) 


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

Ackpg=9.8*deg2rad*WB/U^2

K = gradient(steer./SR,ayg) -Ackpg ;
figure
valid = ayg > 0.15;
K_plot = K(valid);
ayg_plot = ayg(valid);
plot(ayg_plot, K_plot)
grid on
title('Understeer Gradient (deg/g) vs Lateral Acceleration (g)')
xlabel('Lateral Acceleration (g)')
ylabel('Understeer (deg/g)')
ylim([-2 1.5])


figure
plot(time, ayg)
title('Lateral Acceleration vs Time')

figure  
plot(time, r)
title('Yaw Rate vs Time')