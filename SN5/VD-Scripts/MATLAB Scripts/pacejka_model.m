%% Pacejka Lateral Force Curve Generator
% Pure lateral Magic Formula
% No aligning moment, no combined slip

clear; clc; close all;

%% =======================
% USER INPUTS
% ========================

Fn = 1000;              % Normal load (same units used in fit)
SA_min = -15;           % Slip angle min (deg)
SA_max = 15;            % Slip angle max (deg)
n_points = 200;         % Resolution

%% =======================
% Slip Angle Vector
% ========================

SA_deg = linspace(SA_min, SA_max, n_points);
SA = deg2rad(SA_deg);   % Convert to radians

%% =======================
% Load-Dependent Coefficients
% ========================

By = -0.34876850845497015 ...
     - 0.00034276883261057686 * Fn ...
     - 0.00000013247032127260662 * Fn^2;

Cy = 0.5509222176106313 ...
     - 0.002443688073927094 * Fn ...
     - 0.0000012320536839299613 * Fn^2;

Dy = 338.39870577325456 ...
     - 1.9769442425898722 * Fn;

Ey = 0.3553895949382016 ...
     + 31.244897244705058 * exp(0.016405921135532898 * Fn);

Fy_shift = -0.0233809460004577 ...
           - 0.00017739222796836902 * Fn ...
           - 0.00000012122598706268264 * Fn^2;

%% =======================
% Lateral Force Calculation
% ========================

Fy = Dy .* sin( ...
      Cy .* atan( ...
      By .* SA ...
      - Ey .* (By .* SA - atan(By .* SA)) ...
      ) ...
      ) ...
      + Fy_shift;

%% =======================
% Plot
% ========================

figure;
plot(SA_deg, Fy, 'LineWidth', 2);
grid on;
xlabel('Slip Angle (deg)');
ylabel('Lateral Force Fy');
title(['Pacejka Lateral Force Curve | Fn = ', num2str(Fn)]);