clear
clc

% Vehicle Params

m  = 307;
ms = 250;

h_cg = 0.279; %cg height, meters
h_rc = 0.04;

tf = 1.208;
tr = 1.208;

% roll inertia split
I_f = 60;
I_r = 60;

% Suspension Params
Kphi_spring_f = 17725.71755;
Kphi_spring_r = 16751.75198;

Kphi_arb_r = (19942.22396-16751.75198);     % rear ARB only

% Chassis Torsion

K_chassis = 83996;      % Nm/rad 

% Motion Ratios

MR_f = 0.763;
MR_r = 0.734;

% Time

dt = 0.001;
time = 0:dt:5;

phi_f = zeros(size(time));
phi_r = zeros(size(time));

phidot_f = zeros(size(time));
phidot_r = zeros(size(time));

ay = zeros(size(time));

% Lateral Accel

for i = 1:length(time)

    if time(i) > 0.5 && time(i) < 2.5
        ay(i) = 1.5*sin(pi*(time(i)-0.5)/2)^2;
    end

end

% Storage

LLT_f = zeros(size(time));
LLT_r = zeros(size(time));

% Dynamics

for i = 2:length(time)

    % roll moments

    M_total = ms * ay(i) * (h_cg - h_rc);

    % distribute by weight (simplified)
    M_f = 0.5 * M_total;
    M_r = 0.5 * M_total;

    % wheel velocities

    v_w_fl =  phidot_f(i-1)*tf/2;
    v_w_fr = -phidot_f(i-1)*tf/2;

    v_w_rl =  phidot_r(i-1)*tr/2;
    v_w_rr = -phidot_r(i-1)*tr/2;

    % damper velocities

    v_d_fl = MR_f*v_w_fl;
    v_d_fr = MR_f*v_w_fr;

    v_d_rl = MR_r*v_w_rl;
    v_d_rr = MR_r*v_w_rr;

    % damper forces

    F_fl = damperForce(v_d_fl);
    F_fr = damperForce(v_d_fr);
    F_rl = damperForce(v_d_rl);
    F_rr = damperForce(v_d_rr);

    % damper roll moments

    M_d_f = (F_fl - F_fr)*tf/2;
    M_d_r = (F_rl - F_rr)*tr/2;

    % spring moments

    M_s_f = Kphi_spring_f * phi_f(i-1);
    M_s_r = Kphi_spring_r * phi_r(i-1);

    % arb moment

    M_arb_r = Kphi_arb_r * phi_r(i-1);

    % chassis torsion moment

    M_cf = K_chassis*(phi_f(i-1) - phi_r(i-1));
    M_cr = K_chassis*(phi_r(i-1) - phi_f(i-1));

    % roll accelerations

    phidd_f = (M_f - M_s_f - M_d_f - M_cf) / I_f;
    phidd_r = (M_r - M_s_r - M_d_r - M_arb_r - M_cr) / I_r;

    % integrate

    phidot_f(i) = phidot_f(i-1) + phidd_f*dt;
    phidot_r(i) = phidot_r(i-1) + phidd_r*dt;

    phi_f(i) = phi_f(i-1) + phidot_f(i)*dt;
    phi_r(i) = phi_r(i-1) + phidot_r(i)*dt;

    % load transfer

    LLT_f(i) = (M_s_f + M_d_f)/ (tf/2);
    LLT_r(i) = (M_s_r + M_d_r + M_arb_r)/ (tr/2);

end

% plot

figure

plot(time,LLT_f,'r','LineWidth',2)
hold on
plot(time,LLT_r,'b','LineWidth',2)

xlabel('Time (s)')
ylabel('Load Transfer (N)')

legend('Front','Rear')
grid on

% phase lag

[~,idx_f] = max(LLT_f);
[~,idx_r] = max(LLT_r);

phase_lag = (idx_r - idx_f)*dt;

disp(['Rear axle lag (s): ',num2str(phase_lag)])

% damper curve

function F = damperForce(v)

vel = [-250 -200 -150 -100 -50 0 50 100 150 200 250];  % mm/sec
force = [(-600-300) (-575-280) (-525-260) (-475-250) (-350-200) 0 (40+75) (75+80) (125+85) (210+90) (300+95)];  % N
v_mm = v*1000;  % convert m/s → mm/s

F = interp1(vel,force,v_mm,'linear','extrap');


end



