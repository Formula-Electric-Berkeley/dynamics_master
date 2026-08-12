clear; clc; close all;

% Vehicle params 
dist = 0.535;             % weight fraction front
lf = 1.55*(1-dist); 
lr = 1.55*(dist);         % m (CoG to front/rear axle)
m = 307.0;                % kg
twf = 1.208; 
twr = 1.208;              % m (track widths)
kpf = 299 * 180/pi;       % Nm/rad (roll stiffness front)
kpr = 264 * 180/pi;       % Nm/rad (roll stiffness rear)
hCoG = 0.279;             % m
g = 9.81;                 % m/s^2
WB = lf + lr;             % wheelbase [m]
vx = 15;                  % m/s

% Static Toe (Deg) 
tf_deg = -1.0;  % Front toe (negative = toe-out)
tr_deg = 1.0;   % Rear toe (positive = toe-in)

% Compliance parameters 
Ks_f = 11459;              % Front toe compliance, Nm/rad
Ks_r = 11459;              % Rear toe compliance, Nm/rad

% Static vertical loads (per wheel, negative convention) 
Fz_f0 = -(m * g * lr / (2.0 * WB));
Fz_r0 = -(m * g * lf / (2.0 * WB));

% Sweep Setup 
betas  = deg2rad(linspace(-12, 12, 50));
deltas = deg2rad(linspace(-20, 20, 50));

Ay_grid = zeros(length(betas), length(deltas));
CN_grid = zeros(length(betas), length(deltas));

% Loop 
for i = 1:length(betas)
    beta = betas(i);
    ay_guess = 0;
    vy = vx * beta;  % hoist out — doesn't depend on ay

    for j = 1:length(deltas)
        delta = deltas(j);
        ay = ay_guess;

        for iter = 1:500
            r = ay / vx;

            % Load transfer
            dFzf = (m * hCoG * ay / twf) * (kpf / (kpf + kpr));
            dFzr = (m * hCoG * ay / twr) * (kpr / (kpf + kpr));
            
            % Prevent tire liftoff
            FzfL = min(Fz_f0 + dFzf, -10);  FzfR = min(Fz_f0 - dFzf, -10);
            FzrL = min(Fz_r0 + dFzr, -10);  FzrR = min(Fz_r0 - dFzr, -10);
            
            % Toe
            delta_fL = delta - deg2rad(tf_deg);
            delta_fR = delta + deg2rad(tf_deg);
            delta_rL = -deg2rad(tr_deg);
            delta_rR =  deg2rad(tr_deg);

            % Slip angles
            afL0 = delta_fL - atan((vy + lf*r)/vx);
            afR0 = delta_fR - atan((vy + lf*r)/vx);
            arL0 = delta_rL - atan((vy - lr*r)/vx);
            arR0 = delta_rR - atan((vy - lr*r)/vx);

            % Compliance
            afL = afL0 + pacejka_mz(rad2deg(afL0), FzfL) / Ks_f;
            afR = afR0 + pacejka_mz(rad2deg(afR0), FzfR) / Ks_f;
            arL = arL0 + pacejka_mz(rad2deg(arL0), FzrL) / Ks_r;
            arR = arR0 + pacejka_mz(rad2deg(arR0), FzrR) / Ks_r;

            afL_deg = max(min(rad2deg(afL), 20), -20);
            afR_deg = max(min(rad2deg(afR), 20), -20);
            arL_deg = max(min(rad2deg(arL), 20), -20);  
            arR_deg = max(min(rad2deg(arR), 20), -20);

            % Lateral forces
            FyfL = pacejka_fy(afL_deg, FzfL);
            FyfR = pacejka_fy(afR_deg, FzfR);
            FyrL = pacejka_fy(arL_deg, FzrL);
            FyrR = pacejka_fy(arR_deg, FzrR);

            Fyf = FyfL*cos(delta_fL) + FyfR*cos(delta_fR);
            Fyr = FyrL + FyrR;

            % Aligning torques
            MzfL = pacejka_mz(afL_deg, FzfL);
            MzfR = pacejka_mz(afR_deg, FzfR);
            MzrL = pacejka_mz(arL_deg, FzrL);
            MzrR = pacejka_mz(arR_deg, FzrR);

            % Convergence
            ay_new = (Fyf + Fyr) / m;
            if abs(ay_new - ay) < 1e-5
                break;
            end
            ay = ay + 0.1*(ay_new - ay);
        end  % iter

        N = (Fyf*lf) - (Fyr*lr) + MzfL + MzfR + MzrL + MzrR;
        CN_grid(i, j) = N / (m * g * WB);

        if iter == 500
            Ay_grid(i, j) = NaN;
            CN_grid(i, j) = NaN;
            ay_guess = 0; % Reset state because the last point blew up
        else
            Ay_grid(i, j) = ay;
            N = (Fyf*lf) - (Fyr*lr) + MzfL + MzfR + MzrL + MzrR;
            CN_grid(i, j) = N / (m * g * WB);
            ay_guess = ay; % Carry valid state forward
        end

    end  % j
end  % i


% -- Plotting -------------------------------------------------------------
figure('Color', 'w', 'Position', [100, 100, 900, 600]);
hold on; grid on;

p1 = plot(Ay_grid', CN_grid', 'b', 'LineWidth', 0.8);
p2 = plot(Ay_grid, CN_grid, 'r', 'LineWidth', 0.8);

yline(0, 'k', 'LineWidth', 1);
xline(0, 'k', 'LineWidth', 1);

xlabel('Lateral Acceleration A_y [m/s^2]');
ylabel('C_N = N / (mg \cdot WB)');
title(sprintf('Milliken Moment Diagram (%d m/s)', vx));

legend([p1(1), p2(1)], {'\beta Isolines', '\delta Isolines'}, ...
    'Location', 'northwest');

% Find trimmed max Ay (where |CN| is smallest along each delta isoline)
[~, trim_col] = min(abs(CN_grid), [], 2);
trimmed_Ay = arrayfun(@(i) Ay_grid(i, trim_col(i)), 1:length(betas));
[max_trimmed_Ay, idx] = max(trimmed_Ay);

% Absolute max Ay (untrimmed)
[max_Ay, max_idx] = max(Ay_grid(:));
[r_max, c_max]    = ind2sub(size(Ay_grid), max_idx);
N_at_max_Ay       = CN_grid(r_max, c_max);

% dN/dDelta at beta=0 (controllability at entry)
[~, b0]   = min(abs(betas));
CN_b0     = CN_grid(b0, :);
dN_dDelta_b0 = mean(diff(CN_b0) ./ diff(deltas));

% dN/dBeta at delta=0 (stability at entry)
[~, d0]   = min(abs(deltas));
CN_d0     = CN_grid(:, d0);
dN_dBeta_d0 = mean(diff(CN_d0) ./ diff(betas'));

fprintf('\n===== MMD Metrics =====\n');
fprintf('Max Ay (untrimmed):          %6.3f m/s²\n', max_Ay);
fprintf('CN @ Max Ay:                 %6.4f  (%s)\n', N_at_max_Ay, ...
    ternary(N_at_max_Ay < 0, 'stable/understeer', 'unstable/oversteer'));
fprintf('Max Ay (trimmed, N≈0):       %6.3f m/s²\n', max_trimmed_Ay);
fprintf('dN/dδ @ β=0 (entry ctrl):   %6.4f CN/rad\n', dN_dDelta_b0);
fprintf('dN/dβ @ δ=0 (entry stab):   %6.4f CN/rad\n', dN_dBeta_d0);
fprintf('========================\n');

function out = ternary(cond, a, b)
    if cond; out = a; else; out = b; end
end

% -- Tire Model Functions -------------------------------------------------

function fy = pacejka_fy(alpha, Fz)

    B = (-0.34876850845497 - 0.000342768832610576 * Fz - 0.000000132470321272606 * Fz^2);
    C = (0.550922217610631 - 0.00244368807392709 * Fz - 0.000000123205368392996 * Fz^2);
    D = (338.398705773254 - 1.97694424258987 * Fz);
    E = (0.355389594938201 + 31.244897244705 * exp(0.0164059211355328 * Fz));
    F = (-0.0233809460004577 - 0.000177392227968369 * Fz - 0.000000121225987062682 * Fz^2);
    
    fy = D * sin(C * atan(B*alpha - E*(B*alpha - atan(B*alpha))) + F);
end

function mz = pacejka_mz(alpha, Fz)
    
    mz = ((-9.75871128366023 + -0.0586892090580317.*Fz) .* ...
        sin((2.52648069773574 + -0.000239385032436922.*Fz) .* ...
        atan((0.296405006141154 + 0.000111723987205492.*Fz).*alpha - ...
        0.374401683472281 .* ((0.296405006141154 + 0.000111723987205492.*Fz).*alpha - ...
        atan((0.296405006141154 + 0.000111723987205492.*Fz).*alpha)))));
end