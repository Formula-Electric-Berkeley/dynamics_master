clear; clc;

% Vehicle Params
WF = 164.245;   
WR = 142.775;  % Front/rear mass (kg)
WB = 1.550;  % Wheelbase (m)
SR = 4;  % Steer ratio                  
U  = 13;  % Constant speed (m/s)
U_vec = linspace(10,50,10);  % Speed vector for downforce sweep (m/s)
ENF = 0.5;  % Front aligning moment steer compliance (deg/100 Nm)      
ENR = 0.5;  % Aligning moment steer compliance (deg/100 Nm)
A = WB*WR/(WF+WR);  
B = WB*WF/(WF+WR);
IZZ = 75;  % Yaw inertia    
dt = 0.001;  % Time step   
tmax = 30;  % Max time
deg2rad = 180/pi;
MaxSlipRate = 30;  % Max slip rate for accel limit

% Aero downforce at constant speed U
frontdf = 35.503;  % Front aero downforce (N)
reardf  = 56.497;  % Rear aero downforce (N)

% Roll & Chassis Stiffness
Kt          = 1204 * deg2rad;  % Chassis torsional stiffness (Nm/rad)
Kroll_total =  600 * deg2rad;  % Total suspension roll stiffness (Nm/rad)
W_dist_f    = WF / (WF + WR);

% LLTD Sweep
LLTD_mech_vec  = [0.488, 0.504, 0.513, 0.518, 0.525, 0.531, 0.537, 0.596];
maxlat_results = zeros(size(LLTD_mech_vec));
N_steps        = numel(0:dt:tmax);
LT_coeff       = 0.279 * (WF + WR);  % Load transfer coefficient (constant)

% Plotting
h_ug = figure('Name', 'Understeer Gradient Sweep');
hold on; grid on;
title('Understeer Gradient vs Lateral Acceleration', 'FontSize', 20);
xlabel('Lateral Acceleration (g)', 'FontSize', 14);
ylabel('Understeer (deg/g)', 'FontSize', 14);
ylim([-2 2]);

hb = waitbar(0, 'Running LLTD sweep...');

for i = 1:length(LLTD_mech_vec)

    % Effective LLTD with chassis flex correction
    LLTD_mech = LLTD_mech_vec(i);
    Kf = LLTD_mech * Kroll_total;
    Kr = (1 - LLTD_mech) * Kroll_total;
    LLTD_eff  = W_dist_f + (LLTD_mech - W_dist_f) * Kt / (Kt + Kf*Kr/(Kf+Kr));
    LLTD      = LLTD_eff;

    % Initial conditions
    R = 0; BETA = 0; ALPHAF = 0; ALPHAR = 0; n = 0;
    steer_log  = zeros(1, N_steps);
    alphaf_log = zeros(1, N_steps);
    ayg_log    = zeros(1, N_steps);
    WLF = WF/2;  WRF = WF/2;  WLR = WR/2;  WRR = WR/2;

    % Physics loop
    for T = 0:dt:tmax
        n = n + 1;
        if mod(n, 500) == 0
            waitbar(((i-1) + T/tmax) / length(LLTD_mech_vec), hb);
        end

        STEER  = max(T - 1.0, 0);
        DELTAF = STEER / SR;

        FYLF = pacejka_Fy(ALPHAF, -9.8*WLF - frontdf/2);
        FYRF = pacejka_Fy(ALPHAF, -9.8*WRF - frontdf/2);
        FYLR = pacejka_Fy(ALPHAR, -9.8*WLR - reardf/2);
        FYRR = pacejka_Fy(ALPHAR, -9.8*WRR - reardf/2);
        NLF  = pacejka_mz(ALPHAF, -9.8*WLF - frontdf/2);
        NRF  = pacejka_mz(ALPHAF, -9.8*WRF - frontdf/2);
        NLR  = pacejka_mz(ALPHAR, -9.8*WLR - reardf/2);
        NRR  = pacejka_mz(ALPHAR, -9.8*WRR - reardf/2);

        ALPHAF = max(min(-ENF/200*(NLF+NRF) + BETA + A*R/U - DELTAF, 15), -15);
        ALPHAR = max(min(-ENR/200*(NLR+NRR) + BETA - B*R/U,          15), -15);

        RD    = deg2rad * (A*(FYLF+FYRF) - B*(FYLR+FYRR) + NLF+NRF+NLR+NRR) / IZZ;
        BETAD = deg2rad * (FYLF+FYRF+FYLR+FYRR) / (WF+WR) / U - R;
        R     = R + RD*dt;
        BETA  = BETA + BETAD*dt;
        AYG   = U*(R + BETAD) / deg2rad / 9.8;

        steer_log(n)  = STEER;
        alphaf_log(n) = ALPHAF;
        ayg_log(n)    = AYG;

        if abs(AYG) > 2.0 || abs(BETAD) > MaxSlipRate, break; end

        dLT = AYG * LT_coeff;
        WLF = WF/2 + dLT*LLTD;      WRF = WF/2 - dLT*LLTD;
        WLR = WR/2 + dLT*(1-LLTD);  WRR = WR/2 - dLT*(1-LLTD);
    end  % for T

    % Trim to actual run length
    ayg    = ayg_log(1:n);
    alphaf = alphaf_log(1:n);
    steer  = steer_log(1:n);

    % Smooth
    ayg_s    = smoothdata(ayg,    'sgolay', 11);
    alphaf_s = smoothdata(alphaf, 'sgolay', 11);
    dayg     = gradient(ayg_s);
    sliprate = gradient(-alphaf_s) ./ dayg;

    % Limit detection for maxlat
    limit_idx = length(ayg);
    s0 = find(ayg > 0.2, 1);
    if ~isempty(s0)
        s   = s0:length(ayg);
        bad = find(dayg(s) < -0.05 | abs(sliprate(s)) > MaxSlipRate | ~isfinite(sliprate(s)), 1);
        if ~isempty(bad), limit_idx = s(bad); end
    end
    maxlat_results(i) = ayg(limit_idx);

    % Understeer gradient plot - cut at peak of smoothed ayg
    Ackpg = 9.8 * deg2rad * WB / U^2;
    [~, peak_idx] = max(ayg_s);
    K    = gradient(smoothdata(steer,'sgolay',11)./SR, ayg_s) - Ackpg;
    mask = ayg_s > 0.15 & (1:length(ayg_s)) <= limit_idx;
    if any(mask)
        K_plot = K(mask) - K(find(mask, 1));
        lbl = sprintf('Mech LLTD: %.0f%% (Eff: %.1f%%)', LLTD_mech*100, LLTD_eff*100);
        plot(ayg_s(mask), K_plot, 'LineWidth', 1.5, 'DisplayName', lbl);
    end

end  % for i

close(hb);
figure(h_ug); legend('show', 'Location', 'best'); hold off;

% --- Max Lateral Acceleration vs LLTD ---
figure('Name', 'Cornering Performance vs LLTD');
plot(LLTD_mech_vec*100, maxlat_results, '-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
title('Maximum Lateral Acceleration vs Mechanical LLTD', 'FontSize', 20);
xlabel('Target Front Lateral Load Transfer Distribution (%)', 'FontSize', 14);
ylabel('Peak Lateral Acceleration (g)', 'FontSize', 14);

[best_g, best_idx] = max(maxlat_results);
hold on;
plot(LLTD_mech_vec(best_idx)*100, best_g, 'r*', 'MarkerSize', 10, 'LineWidth', 2);
text(LLTD_mech_vec(best_idx)*100 + 0.5, best_g, ...
    sprintf(' Optimum: %.1f%% LLTD\n Max g: %.3f', LLTD_mech_vec(best_idx)*100, best_g), ...
    'Color', 'r', 'FontWeight', 'bold');
hold off;

fprintf('\n--- Sweep Complete ---\n');
fprintf('Highest Peak Lateral Acceleration: %.4f g\n', best_g);
fprintf('Achieved at Mechanical LLTD:       %.1f%%\n', LLTD_mech_vec(best_idx)*100);

% =========================================================
% Aero Sensitivity Study (Constant LLTD)
% =========================================================

LLTD_const = LLTD_mech_vec(6);
maxlat_vs_speed = zeros(size(U_vec));

figure('Name','Understeer Gradient vs Ay (Aero Sweep)');
hold on; grid on;
ylim([-2 2]);
title('Understeer Gradient vs Lateral Acceleration (Speed Sweep)', 'FontSize', 20);
xlabel('Lateral Acceleration (g)', 'FontSize', 14);
ylabel('Understeer (deg/g)', 'FontSize', 14);

for j = 1:length(U_vec)

    U = U_vec(j);

    % Aero at this speed
    df  = downforce(U);
    cop = centerofpressure(U);
    frontdf = df * (cop/100);
    reardf  = df * (1 - cop/100);

    % Initial conditions
    R = 0; BETA = 0; ALPHAF = 0; ALPHAR = 0; n = 0;
    steer_log  = zeros(1, N_steps);
    alphaf_log = zeros(1, N_steps);
    ayg_log    = zeros(1, N_steps);
    WLF = WF/2; WRF = WF/2; WLR = WR/2; WRR = WR/2;

    for T = 0:dt:tmax
        n = n + 1;

        STEER  = max(T - 1.0, 0);
        DELTAF = STEER / SR;

        FYLF = pacejka_Fy(ALPHAF, -9.8*WLF - frontdf/2);
        FYRF = pacejka_Fy(ALPHAF, -9.8*WRF - frontdf/2);
        FYLR = pacejka_Fy(ALPHAR, -9.8*WLR - reardf/2);
        FYRR = pacejka_Fy(ALPHAR, -9.8*WRR - reardf/2);
        NLF  = pacejka_mz(ALPHAF, -9.8*WLF - frontdf/2);
        NRF  = pacejka_mz(ALPHAF, -9.8*WRF - frontdf/2);
        NLR  = pacejka_mz(ALPHAR, -9.8*WLR - reardf/2);
        NRR  = pacejka_mz(ALPHAR, -9.8*WRR - reardf/2);

        ALPHAF = max(min(-ENF/200*(NLF+NRF) + BETA + A*R/U - DELTAF, 15), -15);
        ALPHAR = max(min(-ENR/200*(NLR+NRR) + BETA - B*R/U,          15), -15);

        RD    = deg2rad * (A*(FYLF+FYRF) - B*(FYLR+FYRR) + NLF+NRF+NLR+NRR) / IZZ;
        BETAD = deg2rad * (FYLF+FYRF+FYLR+FYRR) / (WF+WR) / U - R;
        R     = R + RD*dt;
        BETA  = BETA + BETAD*dt;
        AYG   = U*(R + BETAD) / deg2rad / 9.8;

        steer_log(n)  = STEER;
        alphaf_log(n) = ALPHAF;
        ayg_log(n)    = AYG;

        if abs(AYG) > 2.0 || abs(BETAD) > MaxSlipRate, break; end

        dLT = AYG * LT_coeff;
        WLF = WF/2 + dLT*LLTD_const;
        WRF = WF/2 - dLT*LLTD_const;
        WLR = WR/2 + dLT*(1-LLTD_const);
        WRR = WR/2 - dLT*(1-LLTD_const);
    end  % for T

    % Trim
    ayg    = ayg_log(1:n);
    alphaf = alphaf_log(1:n);
    steer  = steer_log(1:n);

    % Smooth
    ayg_s    = smoothdata(ayg,    'sgolay', 11);
    alphaf_s = smoothdata(alphaf, 'sgolay', 11);
    dayg     = gradient(ayg_s);
    sliprate = gradient(-alphaf_s) ./ dayg;

    % Limit detection for maxlat[~, 
    limit_idx = length(ayg);
    s0 = find(ayg > 0.2, 1);
    if ~isempty(s0)
        s   = s0:length(ayg);
        bad = find(dayg(s) < -0.05 | abs(sliprate(s)) > MaxSlipRate | ~isfinite(sliprate(s)), 1);
        if ~isempty(bad), limit_idx = s(bad); end
    end

    maxlat_vs_speed(j) = ayg(limit_idx);

    % Understeer gradient plot - cut at peak of smoothed ayg
    Ackpg = 9.8 * deg2rad * WB / U^2;
    [~, peak_idx] = max(ayg_s);
    K    = gradient(smoothdata(steer,'sgolay',11)./SR, ayg_s) - Ackpg;
    mask = ayg_s > 0.15 & (1:length(ayg_s)) <= limit_idx;
    if any(mask)
        K_plot = K(mask) - K(find(mask, 1));
        plot(ayg_s(mask), K_plot, 'LineWidth', 1.5, ...
            'DisplayName', sprintf('U = %.1f m/s', U));
    end

end  % for j

legend('show', 'Location', 'best');
hold off;

% Max lateral accel vs speed
figure('Name','Max Lateral Accel vs Speed');
plot(U_vec, maxlat_vs_speed, '-o', 'LineWidth', 2);
grid on;
xlabel('Speed (m/s)', 'FontSize', 14);
ylabel('Max Lateral Acceleration (g)', 'FontSize', 14);
title('Effect of Aero on Peak Lateral Acceleration', 'FontSize', 20);

fprintf('\n--- Aero Sweep Complete ---\n');
for j = 1:length(U_vec)
    fprintf('U = %.1f m/s  -> Max Ay = %.3f g\n', U_vec(j), maxlat_vs_speed(j));
end

% Local functions

function Fy = pacejka_Fy(alpha, Fz)
    B = -0.34876850845497   + -0.000342768832610576    * Fz + -0.000000132470321272606 * Fz^2;
    C =  0.550922217610631  + -0.00244368807392709     * Fz + -0.00000123205368392996  * Fz^2;
    D =  338.398705773254   + -1.97694424258987        * Fz;
    E =  0.355389594938201  +  31.244897244705         * exp(0.0164059211355328 * Fz);
    F = -0.0233809460004577 + -0.000177392227968369    * Fz + -0.000000121225987062682 * Fz^2;
    Fy = D .* sin(C .* atan((B.*alpha) - E.*((B.*alpha) - atan(B.*alpha))) + F);
end

function mz = pacejka_mz(alpha, Fz)
    Fz = -Fz;
    mz = ((-9.75871128366023 + -0.0586892090580317.*Fz) .* ...
        sin((2.52648069773574 + -0.000239385032436922.*Fz) .* ...
        atan((0.296405006141154 + 0.000111723987205492.*Fz).*alpha - ...
        0.374401683472281 .* ((0.296405006141154 + 0.000111723987205492.*Fz).*alpha - ...
        atan((0.296405006141154 + 0.000111723987205492.*Fz).*alpha)))));
end

function df = downforce(U)
    df = 0.193 - 0.691.*U + 0.692*U.^2;
end

function cop = centerofpressure(U)
    cop = 64.1 - 0.133.*U - 8.86E-03*U.^2;
end