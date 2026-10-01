clear; clc; close all;
% Vehicle Parameters
dist = 0.52;
lf = 1.55 * (1 - dist);
lr = 1.55 * (dist);
m  = 316.0;
twf = 1.208;
twr = 1.208;
hCoG = 0.258;
g = 9.81;
WB = lf + lr;
vx = 15;
% Roll stiffnesses (Nm/rad)
kpf = 299 * 180/pi;
kpr = 264 * 180/pi;
LLTD = kpf / (kpf + kpr);
tf_deg = -3;  % front toe angle
tr_deg = 0.5;  % rear toe angle
Ks_f = 11459;  % front toe compliance, nm/rad
Ks_r = 11459;  % rear toe compliance, nm/rad
% Static vertical loads
Fz_f0 = -(m * g * lr / (2 * WB));
Fz_r0 = -(m * g * lf / (2 * WB));
% Sweep Setup
density = 20;
betas  = deg2rad(linspace(-12,12,density));
deltas = deg2rad(linspace(-12,12,density));
Ay_grid = NaN(length(betas), length(deltas));
CN_grid = NaN(length(betas), length(deltas));
% Main Loop
for i = 1:length(betas)
    beta = betas(i);
    vy = vx * tan(beta);
    ay_guess = 0;

    for j = 1:length(deltas)
        delta = deltas(j);
        ay = ay_guess;

        for iter = 1:400
            r = ay / vx;

            dFz_total_f = (LLTD * m * ay * hCoG) / twf;
            dFz_total_r = ((1 - LLTD) * m * ay * hCoG) / twr;

            FzfL = min(Fz_f0 + dFz_total_f/2, 0);
            FzfR = min(Fz_f0 - dFz_total_f/2, 0);
            FzrL = min(Fz_r0 + dFz_total_r/2, 0);
            FzrR = min(Fz_r0 - dFz_total_r/2, 0);

            % Slip angles
            af0 = (delta - atan((vy + lf*r) / vx));
            ar0 = (- atan((vy - lr*r) / vx));

            pk_fL = get_peak_alpha(abs(FzfL));
            pk_fR = get_peak_alpha(abs(FzfR));
            pk_rL = get_peak_alpha(abs(FzrL));
            pk_rR = get_peak_alpha(abs(FzrR));
            % Compliance steer
            afL = max(min(rad2deg(af0 - deg2rad(tf_deg) + pacejka_mz(rad2deg(af0), FzfL)/Ks_f),pk_fL(1)),pk_fL(2));
            afR = max(min(rad2deg(af0 + deg2rad(tf_deg) + pacejka_mz(rad2deg(af0), FzfR)/Ks_f),pk_fR(1)),pk_fR(2));
            arL = max(min(rad2deg(ar0 - deg2rad(tr_deg) + pacejka_mz(rad2deg(ar0), FzrL)/Ks_r),pk_rL(1)),pk_rL(2));
            arR = max(min(rad2deg(ar0 + deg2rad(tr_deg) + pacejka_mz(rad2deg(ar0), FzrR)/Ks_r),pk_rR(1)),pk_rR(2));
            Fyf = pacejka_fy((afL), FzfL) + pacejka_fy((afR), FzfR);
            Fyr = pacejka_fy((arL), FzrL) + pacejka_fy((arR), FzrR);

            ay_new = (Fyf + Fyr) / m;
            relaxation = 0.35 + 0.45 * exp(-0.25 * abs(ay));
            ay = ay*(1-relaxation) + ay_new*relaxation;
            if abs(ay_new - ay) < 0.001, break; end
        end
        if abs(ay_new - ay) < 0.05 && abs(ay) < 25
            Ay_grid(i,j) = ay;
            Mz = Fyf*lf - Fyr*lr + pacejka_mz(afL, FzfL) + pacejka_mz(afR, FzfR) + pacejka_mz(arL, FzrL) + pacejka_mz(arR, FzrR);
            CN_grid(i,j) = Mz / (m * g * WB);
            ay_guess = 0.98*ay;
        else
            ay_guess = 0;
        end
    end
end
% Smoothing and Plotting
Ay_sm = movmean(movmean(Ay_grid, 3, 1, 'omitnan'), 3, 2, 'omitnan');
CN_sm = movmean(movmean(CN_grid, 3, 1, 'omitnan'), 3, 2, 'omitnan');
figure;
hold on; grid on;
plot(Ay_sm', CN_sm', 'r-', 'LineWidth', 1.3); % Constant beta
plot(Ay_sm, CN_sm, 'b-', 'LineWidth', 1.3);   % Constant delta
yline(0, 'k--', 'LineWidth', 1.5);
xline(0, 'k--', 'LineWidth', 1.5);
xlabel('Lateral Acceleration, m/s²', 'FontSize', 14);
ylabel('Yaw Moment Coefficient CN', 'FontSize', 14);
dCN_dBeta = zeros(size(CN_sm));
[~, j0] = min(abs(deltas));   % index closest to delta = 0
for j = 1:length(deltas)
    dCN_dBeta(:,j) = gradient(CN_sm(:,j), betas);
end
figure
plot(Ay_sm(:, j0), dCN_dBeta(:, j0))
xlabel('Lateral Acceleration (m/s^2)')
ylabel('dCN / dbeta')
grid on
function alpha_peak = get_peak_alpha(Fz)
    x=Fz;
    alpha_peak=[];
    alpha_peak(1) = -3.83E-03*x + 8.93;
    alpha_peak(2) = 3.19E-03*x + -8.11;
end
% Tire Models
function fy = pacejka_fy(alpha, Fz)
    B = -0.3487 - 0.00034*Fz - 1.3e-7*Fz.^2;
    C =  0.5509 - 0.0024*Fz  - 1.2e-7*Fz.^2;
    D = 338.39  - 1.9769*Fz;
    E =  0.3553 + 31.24*exp(0.0164*Fz);
    F = -0.0233 - 0.00017*Fz - 1.2e-7*Fz.^2;
    fy = 0.6*D * sin(C * atan(B*alpha - E*(B*alpha - atan(B*alpha))) + F);
end
function mz = pacejka_mz(alpha, Fz)
    mz = 0.6*((-9.7587 - 0.0586.*Fz) .* sin((2.526 - 0.00023.*Fz) .* ...
         atan((0.296 + 0.00011.*Fz).*alpha - 0.374 .* ((0.296 + 0.00011.*Fz).*alpha - ...
         atan((0.296 + 0.00011.*Fz).*alpha)))));
end
