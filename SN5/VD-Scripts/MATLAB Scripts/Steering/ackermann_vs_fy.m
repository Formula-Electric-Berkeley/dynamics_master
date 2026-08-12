close all;
clear all;
reset(groot);
set(groot, 'defaultFigureRenderer', 'painters');

function Fy_out = pacejka_Fy(alpha, Fz)
    % Fz: positive vertical load (N)
    % alpha: slip angle (deg)
    % Fy_out: lateral force (N, positive)
    Fz_neg = -Fz;  % model was fit with negative Fz convention internally
    B = -0.34876850845497   + -0.000342768832610576   .* Fz_neg + -0.000000132470321272606 .* (Fz_neg.^2);
    C =  0.550922217610631  + -0.00244368807392709    .* Fz_neg + -0.00000123205368392996  .* (Fz_neg.^2);
    D =  338.398705773254   + -1.97694424258987       .* Fz_neg;
    E =  0.355389594938201  +  31.244897244705        .* exp(0.0164059211355328 .* Fz_neg);
    F = 0;
    Bx = B .* alpha;
    Fy_out = -0.6*D .* sin(C .* atan(Bx - E .* (Bx - atan(Bx))) + F); % negate: fit produces negative, we want positive output
end

%% defining variables

t = 1.208;  % track width, m
wb = 1.55;  % wheelbase, m
cg = 0.279;  % cg height, m
m = 164.245;  % mass on front axle, kg
ay = 1.5*9.81;  % assume 1.5g lateral acceleration 
radius = linspace(4.5, 100, 100);  % corner radii range
ackermann = linspace(-1,1,100);  % ackermann fraction range, from 100% anti to 100% pro

%% vertical loads

FzO = (m/2)*9.81+m*cg*ay/t;  % outer tire vertical load
FzI = (m/2)*9.81-m*cg*ay/t;  % inner tire vertical load

%% single steering input: the Ackermann-neutral (geometric mean) steer angle

delta_acker_mean = atan(wb ./ radius);  % steer angle to CG path

[R_grid, A_grid] = meshgrid(radius, ackermann);
delta_mean_g = atan(wb ./ R_grid);

% geometric Ackermann angles for each wheel
delta_i_acker_g = atan(wb ./ (R_grid - t/2));
delta_o_acker_g = atan(wb ./ (R_grid + t/2));

% actual steer angles: ackermann fraction blends from parallel to full Ackermann
%   ackermann=1  → each wheel gets its geometric Ackermann angle
%   ackermann=0  → both wheels get delta_mean (parallel)
%   ackermann=-1 → angles are mirrored (anti-Ackermann)
delta_o_g = delta_mean_g + A_grid .* (delta_o_acker_g - delta_mean_g);
delta_i_g = delta_mean_g + A_grid .* (delta_i_acker_g - delta_mean_g);

%% vehicle body slip angle at front axle (small angle, steady state)
% β_f ≈ wb_f/R - this is the angle the front axle velocity vector makes
% with the car centerline just from the geometry of circular motion
% use front axle distance from CG
wb_f = wb * 0.465;  % front axle to CG distance, m 
beta_f = atan(wb_f ./ R_grid) .* (180/pi);  % deg, always positive

%% slip angles: geometric slip + body slip
alpha_o_g = (delta_o_g - delta_o_acker_g) .* (180/pi) + beta_f;
alpha_i_g = (delta_i_g - delta_i_acker_g) .* (180/pi) + beta_f;

%% lateral forces — no abs() needed now since beta_f keeps both positive
Fy_o = pacejka_Fy(alpha_o_g,       FzO .* ones(size(R_grid)));
Fy_i = pacejka_Fy(abs(alpha_i_g),  FzI .* ones(size(R_grid)));
Fy   = Fy_o + Fy_i;

%% Fy vs Ackermann at select radii
radii_to_plot = [4.5, 10, 20];
colors = {'b', 'r', 'g'};

figure; set(gcf, 'Renderer', 'painters');
hold on;

for k = 1:length(radii_to_plot)
    [~, r_idx] = min(abs(radius - radii_to_plot(k)));
    plot(ackermann * 100, Fy(:, r_idx), ...
        'Color', colors{k}, 'LineWidth', 2, ...
        'DisplayName', sprintf('R = %.1f m', radius(r_idx)));
    
    % mark peak
    [Fy_peak, peak_a_idx] = max(Fy(:, r_idx));
    peak_a_pct = ackermann(peak_a_idx) * 100;
    plot(peak_a_pct, Fy_peak, 'o', 'Color', colors{k}, ...
        'MarkerSize', 8, 'MarkerFaceColor', colors{k}, 'HandleVisibility', 'off');
    text(peak_a_pct, Fy_peak, sprintf('  %.0f N @ %.0f%%', Fy_peak, peak_a_pct), ...
        'Color', colors{k}, 'FontSize', 8, 'VerticalAlignment', 'bottom');
end

xlabel('Ackermann Percentage (%)');
ylabel('Front Axle Lateral Force (N)');
title('Front Axle Lateral Force vs Ackermann Percent');
legend('Location', 'best');
ylim([700, 2400]);
grid on;