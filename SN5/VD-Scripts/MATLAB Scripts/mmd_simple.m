clear; clc; close all;

% =========================================================================
% Milliken Moment Diagram – Bicycle Model (DrRacing approach)
% For each (beta, delta): iterate ay until lateral force equilibrium,
% then compute yaw moment. TLLTD is a single tuning parameter.
% =========================================================================

% --- Vehicle Parameters --------------------------------------------------
dist  = 0.535;            % Weight fraction on front axle
WB    = 1.55;             % Wheelbase [m]
lf    = WB * (1 - dist);  % CG to front axle [m]
lr    = WB * dist;        % CG to rear axle [m]
m     = 307.0;            % Mass [kg]
hCoG  = 0.279;            % CG height [m]
g     = 9.81;             % [m/s^2]
vx    = 13;               % Longitudinal speed [m/s]

% Total Lateral Load Transfer Distribution (front fraction, 0–1)
% Increase → more understeer / stability; decrease → more oversteer
TLLTD = 0.50;

% --- Static Wheel Loads (per axle, negative convention) ------------------
Fz_f0 = -(m * g * lr / WB);   % Both front wheels combined
Fz_r0 = -(m * g * lf / WB);   % Both rear wheels combined

% --- Sweep Setup ---------------------------------------------------------
betas  = deg2rad(linspace(-12, 12, 25));   % Body slip angle sweep
deltas = deg2rad(linspace(-20, 20, 25));   % Steer angle sweep

Ay_grid = nan(length(betas), length(deltas));
CN_grid = nan(length(betas), length(deltas));

% --- Main Loop -----------------------------------------------------------
for i = 1:length(betas)
    beta   = betas(i);
    vy     = vx * tan(beta);     % Lateral velocity (constant for this beta)

    for j = 1:length(deltas)
        delta = deltas(j);

        % Iterative solve for ay
        ay      = 0;
        damping = 0.5;

        for iter = 1:300
            r = ay / vx;   % Yaw rate (steady state assumption)

            % --- Lateral Load Transfer (via TLLTD) -----------------------
            dFz_total = m * hCoG * ay;         % Total lateral weight transfer [N]
            dFz_f     = TLLTD * dFz_total;     % Front axle share
            dFz_r     = (1 - TLLTD) * dFz_total; % Rear axle share

            FzfL = (Fz_f0 + dFz_f) / 2;   FzfR = (Fz_f0 - dFz_f) / 2;
            FzrL = (Fz_r0 + dFz_r) / 2;   FzrR = (Fz_r0 - dFz_r) / 2;

            % --- Bicycle Model Slip Angles (one per axle) ----------------
            % Both wheels on each axle share the same slip angle
            alpha_f = delta - atan((vy + lf * r) / vx);
            alpha_r =       - atan((vy - lr * r) / vx);

            alpha_f_deg = rad2deg(alpha_f);
            alpha_r_deg = rad2deg(alpha_r);

            % --- Tire Forces (summed left+right per axle) ----------------
            FyfL = pacejka_fy(alpha_f_deg, FzfL);
            FyfR = pacejka_fy(alpha_f_deg, FzfR);
            FyrL = pacejka_fy(alpha_r_deg, FzrL);
            FyrR = pacejka_fy(alpha_r_deg, FzrR);

            % Project front forces through steer angle, sum axles
            Fyf = (FyfL + FyfR) * cos(delta);
            Fyr =  FyrL + FyrR;

            % --- Self-Aligning Torques (both wheels per axle) ------------
            MzfL = pacejka_mz(alpha_f_deg, FzfL);
            MzfR = pacejka_mz(alpha_f_deg, FzfR);
            MzrL = pacejka_mz(alpha_r_deg, FzrL);
            MzrR = pacejka_mz(alpha_r_deg, FzrR);

            % --- Convergence ---------------------------------------------
            ay_new = (Fyf + Fyr) / m;
            if abs(ay_new - ay) < 1e-6
                break;
            end
            ay = ay + damping * (ay_new - ay);
        end

        % --- Store Results -----------------------------------------------
        Ay_grid(i, j) = ay;
        N = (Fyf * lf) - (Fyr * lr) + MzfL + MzfR + MzrL + MzrR;
        CN_grid(i, j) = N / (m * g * WB);
    end
end

% =========================================================================
% Plot
% =========================================================================
figure('Color', 'w', 'Position', [100 100 900 600]);
hold on; grid on;

p1 = plot(Ay_grid',  CN_grid',  'b', 'LineWidth', 0.9);  % beta isolines
p2 = plot(Ay_grid,   CN_grid,   'r', 'LineWidth', 0.9);  % delta isolines

yline(0, 'k', 'LineWidth', 1.2);
xline(0, 'k', 'LineWidth', 1.2);

xlabel('Lateral Acceleration  A_y  [m/s^2]', 'FontSize', 12);
ylabel('C_N = N / (mg \cdot WB)',             'FontSize', 12);
title(sprintf('Milliken Moment Diagram  –  Bicycle Model  (%.0f m/s,  TLLTD = %.0f%%)', ...
    vx, TLLTD*100), 'FontSize', 13);
legend([p1(1), p2(1)], {'\beta isolines', '\delta isolines'}, ...
    'Location', 'northwest', 'FontSize', 11);

% =========================================================================
% Key Metrics
% =========================================================================
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

% =========================================================================
% Tire Model Functions
% =========================================================================
function fy = pacejka_fy(alpha, Fz)
    B = (-0.34876850845497  - 0.000342768832610576*Fz   - 0.000000132470321272606*Fz^2);
    C = ( 0.550922217610631 - 0.00244368807392709 *Fz   - 0.000000123205368392996*Fz^2);
    D = ( 338.398705773254  - 1.97694424258987    *Fz);
    E = ( 0.355389594938201 + 31.244897244705      *exp(0.0164059211355328*Fz));
    F = (-0.0233809460004577- 0.000177392227968369 *Fz   - 0.000000121225987062682*Fz^2);
    fy = D * sin(C * atan(B*alpha - E*(B*alpha - atan(B*alpha))) + F);
end

function mz = pacejka_mz(alpha, Fz)
    mz = ((-9.75871128366023 + -0.0586892090580317*Fz) .* ...
        sin((2.52648069773574 + -0.000239385032436922*Fz) .* ...
        atan((0.296405006141154 + 0.000111723987205492*Fz).*alpha - ...
        0.374401683472281 .* ((0.296405006141154 + 0.000111723987205492*Fz).*alpha - ...
        atan((0.296405006141154 + 0.000111723987205492*Fz).*alpha)))));
end

function out = ternary(cond, a, b)
    if cond; out = a; else; out = b; end
end