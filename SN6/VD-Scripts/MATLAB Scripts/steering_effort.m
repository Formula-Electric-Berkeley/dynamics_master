clear, clc;

% steering effort vs lateral acceleration
% Sign convention: Fz positive (compression), Fy positive (lateral force magnitude)


% inputs
g = 9.81;
tw = 1.208;       % track width, m
wb = 1.55;        % wheelbase, m
lltd = 0.47;      % lltd fraction front
cg = 0.279;       % cg height, m
wf = 1611.18047;  % front axle weight, N (positive)
i = 4;            % steering ratio :1
lambda = 10;      % KPI, deg inboard
v = 6;            % caster, deg rearward
rs = -0.033;      % scrub radius, m (+ = intersection inboard of wheel center)
nm = 0.015;       % mechanical trail, m
vel = 13;         % constant velocity, m/s

accel = linspace(0.01, 1.8, 20);  % accel range (start nonzero to avoid div/0)

% calcs

steer = rad2deg((atan((wb./((vel^2)./(accel.*g)-tw/2))) + atan((wb./((vel^2)./(accel.*g)+tw/2))))/2);  % tire steer angle, deg

wheel_angle = steer * i;  % steering wheel angle, deg

% Vertical loads: positive = compression
FzL = wf/2 - wf*cg.*accel.*lltd./tw;  % inside tire (unloaded)
FzR = wf/2 + wf*cg.*accel.*lltd./tw;  % outside tire (loaded)

% Lateral force demand (positive)
Fy = accel * wf;

% Distribute lateral force by vertical load (degenerate but ok as initial estimate)
FyL = Fy .* (FzL ./ (FzL + FzR));
FyR = Fy - FyL;

% Fy lookup table (all positive)

alpha_grid = linspace(0, 12, 200);   % slip angle, deg
Fz_grid    = linspace(500, 4000, 60); % vertical load, N (positive)

Fy_table = zeros(length(alpha_grid), length(Fz_grid));
for j = 1:length(Fz_grid)
    for k = 1:length(alpha_grid)
        Fy_table(k,j) = pacejka_Fy(alpha_grid(k), Fz_grid(j));
    end
end

% Clamp lateral force demand to tire capacity, then solve slip angles

alpha_L = zeros(size(FyL));
alpha_R = zeros(size(FyR));

for k = 1:length(FyL)
    % Find nearest Fz column (positive convention)
    [~,idxL] = min(abs(Fz_grid - FzL(k)));
    [~,idxR] = min(abs(Fz_grid - FzR(k)));

    % Clamp demand to max available (table is positive and monotonically increasing to peak)
    FyL_max = max(Fy_table(:,idxL));
    FyR_max = max(Fy_table(:,idxR));

    FyL_clamped = min(FyL(k), FyL_max);
    FyR_clamped = min(FyR(k), FyR_max);

    % Interpolate slip angle from clamped Fy demand
    alpha_L(k) = interp1(Fy_table(:,idxL), alpha_grid, FyL_clamped, 'linear', 'extrap');
    alpha_R(k) = interp1(Fy_table(:,idxR), alpha_grid, FyR_clamped, 'linear', 'extrap');
end

% Recover actual Fy from slip angles 

FyL_actual = zeros(size(alpha_L));
FyR_actual = zeros(size(alpha_R));

for k = 1:length(alpha_L)
    [~,idxL] = min(abs(Fz_grid - FzL(k)));
    [~,idxR] = min(abs(Fz_grid - FzR(k)));
    FyL_actual(k) = interp1(alpha_grid, Fy_table(:,idxL), alpha_L(k), 'linear', 'extrap');
    FyR_actual(k) = interp1(alpha_grid, Fy_table(:,idxR), alpha_R(k), 'linear', 'extrap');
end

Fy_actual = FyL_actual + FyR_actual;

% Aligning torques (pass positive Fz)

mz_L = pacejka_mz(alpha_L, FzL);
mz_R = pacejka_mz(alpha_R, FzR);

% Kingpin moments

% Mechanical trail: lateral force acts through nm, resists turn -> negative moment
Mkp_Fy = -(Fy_actual .* nm .* cos(deg2rad(v)) .* cos(deg2rad(steer)));

% Scrub/KPI: load transfer creates restoring moment
delta_Fz = FzR - FzL;  % positive = more load on outside
Mkp_Fz = delta_Fz .* sin(deg2rad(lambda)) .* rs .* sin(deg2rad(steer)) + ...
          delta_Fz .* sin(deg2rad(v))      .* rs .* cos(deg2rad(steer));

% Aligning torque projected onto kingpin axis
Mkp_mz = (mz_L + mz_R) .* cos(deg2rad(sqrt(lambda^2 + v^2)));

Auto_motor_backdrive = -0.6;  % Nm at kingpin

Mkp = (Mkp_Fy + Mkp_Fz + Mkp_mz + Auto_motor_backdrive);

steering_wheel_torque = -Mkp ./ i;

% Plotting

figure
plot(wheel_angle, steering_wheel_torque)
xlabel('Steering Wheel Angle (deg)')
ylabel('Steering Effort (Nm)')
title('Steering Effort vs Wheel Angle at v=13 m/s')

figure
plot(accel, mz_L + mz_R, 'LineWidth', 2)
xlabel('Lateral Acceleration (g)')
ylabel('Aligning Torque (Nm)')
title('Total Aligning Torque vs Lateral Acceleration')
grid on

figure

subplot(2,1,1)
plot(accel, steering_wheel_torque, 'LineWidth', 2)
grid on
xlabel('Lateral Acceleration (g)')
ylabel('Steering Wheel Torque (Nm)')
title('Steering Effort vs Lateral Acceleration')

subplot(2,1,2)
plot(accel, Mkp_Fy,  'LineWidth', 1.8); hold on
plot(accel, Mkp_Fz,  'LineWidth', 1.8)
plot(accel, Mkp_mz,  'LineWidth', 1.8)
grid on
xlabel('Lateral Acceleration (g)')
ylabel('Kingpin Moment (Nm)')
title('Steering Moment Contributions')
legend('Fy Mechanical Trail', 'Fz Scrub/KPI', 'Aligning Torque', 'Location', 'best')

figure
plot(accel, FyL_actual, 'LineWidth', 1.8); hold on
plot(accel, FyR_actual, 'LineWidth', 1.8)
plot(accel, Fy_actual,  'LineWidth', 1.8)
grid on
xlabel('Lateral Acceleration (g)')
ylabel('Lateral Force (N)')
title('Tire Lateral Forces (saturated)')
legend('FyL', 'FyR', 'Fy total', 'Location', 'best')

% Pacejka Fy function (positive Fz in, positive Fy out)

function Fy_out = pacejka_Fy(alpha, Fz)
    % Fz: positive vertical load (N)
    % alpha: slip angle (deg)
    % Fy_out: lateral force (N, positive)
    Fz_neg = -Fz;  % model was fit with negative Fz convention internally
    B = -0.34876850845497   + -0.000342768832610576   * Fz_neg + -0.000000132470321272606 * (Fz_neg^2);
    C =  0.550922217610631  + -0.00244368807392709    * Fz_neg + -0.00000123205368392996  * (Fz_neg^2);
    D =  338.398705773254   + -1.97694424258987       * Fz_neg;
    E =  0.355389594938201  +  31.244897244705        * exp(0.0164059211355328 * Fz_neg);
    F = -0.0233809460004577 + -0.000177392227968369   * Fz_neg + -0.000000121225987062682 * (Fz_neg^2);
    Bx = B .* alpha;
    Fy_raw = 0.6*D .* sin(C .* atan(Bx - E .* (Bx - atan(Bx))) + F);
    Fy_out = -Fy_raw;  % negate: fit produces negative, we want positive output
end

% Pacejka Mz function (positive Fz in, correct sign Mz out)

function mz = pacejka_mz(alpha, Fz)
    % Fz: positive vertical load (N)
    % alpha: slip angle (deg)
    % mz: aligning torque (Nm, negative = restorative)
    Fz_neg = -Fz;
    mz = 0.6*-((-9.75871128366023 + -0.0586892090580317 .* Fz_neg) .* ...
        sin((2.52648069773574 + -0.000239385032436922 .* Fz_neg) .* ...
        atan((0.296405006141154 + 0.000111723987205492 .* Fz_neg) .* alpha - ...
        (0.374401683472281) .* ((0.296405006141154 + 0.000111723987205492 .* Fz_neg) .* alpha - ...
        atan((0.296405006141154 + 0.000111723987205492 .* Fz_neg) .* alpha)))));
end

