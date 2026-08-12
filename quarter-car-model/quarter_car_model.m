% =========================================================================
% QUARTER CAR MODEL - FRONT AXLE
% =========================================================================

m1 = 141.885/2;  % sprung mass, kg
m2 =  22.36/2;   % unsprung mass, kg 
k = 35683.525;   % spring rate, N/m
kt = 101573.528; % tire spring rate, N/m

% --- OHLINS TTX25 DAMPER SETTINGS ---
% Specify your desired clicks for Rebound (negative vel) and Compression (positive vel).
% These settings are the closest available combinations to c_design below,
% evaluated separately for rebound and compression over the full velocity
% range.  Change them to evaluate any other supported/interpolated setting.
ls_clicks_reb = 2;
hs_clicks_reb = 3;

ls_clicks_comp = 4;
hs_clicks_comp = 1;

% --- LOAD INTERPOLATED DYNO DATA ---
% Resolve the data relative to this script so it works from any folder.
model_dir = fileparts(mfilename('fullpath'));
load(fullfile(model_dir, 'damper_3D_matrix.mat'));

% Ensure variables are double precision for interpolation.
vel_mm = double(vel_mm); 
ls_settings = double(ls_settings);
hs_settings = double(hs_settings);
Force_3D = double(Force_3D);

% Force column vector for queries
xq = vel_mm(:); 

% Linear interpolation across settings preserves the shape of the fitted
% dyno curves.  A global spline here overshoots the noisy digitized points
% around zero velocity and can create nonphysical multi-kN force spikes.
force_lookup = griddedInterpolant({vel_mm(:), ls_settings(:), hs_settings(:)}, ...
    Force_3D, 'linear', 'nearest');

% 1. Interpolate full curve for the Rebound settings
query_LS_reb = ls_clicks_reb * ones(size(xq));
query_HS_reb = hs_clicks_reb * ones(size(xq));
Force_reb_full = force_lookup(xq, query_LS_reb, query_HS_reb);

% 2. Interpolate full curve for the Compression settings
query_LS_comp = ls_clicks_comp * ones(size(xq));
query_HS_comp = hs_clicks_comp * ones(size(xq));
Force_comp_full = force_lookup(xq, query_LS_comp, query_HS_comp);

% 3. Piece them together cleanly at v = 0
force_N = zeros(size(xq));
force_N(xq < 0) = Force_reb_full(xq < 0);
force_N(xq >= 0) = Force_comp_full(xq >= 0);

% --- BASELINE DESIGN CURVE (For Plotting) ---
vel_mm_21 = linspace(-250,250,21); 
c_design = [-447.297 -412.890 -378.482 -344.075 -309.667 -275.260 -240.852 -206.445 -137.630 -68.815 0.000 30.584 61.169 91.753 107.046 122.338 137.630 152.922 168.214 183.507 198.799];  
c_designsmooth = spline(vel_mm_21, c_design, xq);

% --- CONVERT TO SI UNITS FOR ODE SOLVER ---
vel_si = xq / 1000;  % m/s
force_si = force_N;  % N

% =========================================================================
% SIMULATION & ODE SOLVER
% =========================================================================
c_crit = 2*sqrt(k*m1) * abs(vel_si);
c_table = [force_si'; vel_si'];

dt = 0.001;  % time step, s
tmax = 6;    % max time, s
tdist = 1;   % time the tire reaches the bump, s

% The road is defined spatially, then traversed at vehicle_speed.  Change
% profile_type to sharp_bump, pothole, washboard, rough, or flat to run one
% of the other profiles implemented in generate_road_profile.m.  Run
% quarter_car_road_sweep.m to compare all conditions and several speeds.
profile_type = "smooth_bump";
vehicle_speed = 10; % m/s
road_params = struct('height', 0.030, ... % 30 mm
                     'length', 0.400, ... % 400 mm
                     'start_time', tdist);

%F-k(x1-x2)-c(x1'-x2')=m1x1"

%-F+k(x1-x2)+c(x1'-x2')-kt(x2-xt(t))=m2x2"

%m1x1"+c(x1'-x2')+k(x1-x2)=F
%m2x2"-k(x1-x2)-c(x1'-x2')+ktx2=-F+ktxt

%[m1 0; 0 m2]*[x1"; x2"] + [c -c; -c c]*[x1'; x2'] + [k -k; -k k+kt]*[x1; x2] = [1 0; 1 kt]

function dXdt = quarter_car(t, X, m1, m2, k, kt, c_table, t_vec, xt_vec)

x1 = X(1);
x1_dot = X(2);
x2 = X(3);
x2_dot = X(4);

% interpolate road input
xt = interp1(t_vec, xt_vec, t, 'linear', 0);

% relative velocity
v_rel = x1_dot - x2_dot;

% damper force (nonlinear)
v_rel = min(max(v_rel, c_table(2,1)), c_table(2,end));
c_force = interp1(c_table(2,:), c_table(1,:), v_rel, 'linear');

% equations of motion
x1_ddot = (-k*(x1 - x2) - c_force) / m1;
x2_ddot = ( k*(x1 - x2) + c_force - kt*(x2 - xt) ) / m2;

dXdt = [x1_dot;
        x1_ddot;
        x2_dot;
        x2_ddot];
end

X0 = [0; 0; 0; 0];

t_vec = 0:dt:tmax;

[xt, road_info] = generate_road_profile( ...
    profile_type, t_vec, vehicle_speed, road_params);

% This quarter-car model is not stiff; ode15s spends unnecessary time
% estimating Jacobians around the road-step transition.  ode45 matches the
% predecessor model and is substantially faster for this system.  MaxStep
% still resolves the 1 ms road-input table without sacrificing accuracy.
opts = odeset('RelTol',1e-6,'AbsTol',1e-8,'MaxStep',0.01);

[t_sol, X_sol] = ode45(@(t,X) quarter_car(t, X, m1, m2, k, kt, c_table, t_vec, xt), t_vec, X0, opts);

x1 = X_sol(:,1);  % sprung displacement
x2 = X_sol(:,3);  % unsprung displacement
road_sol = interp1(t_vec, xt, t_sol, 'linear', 0);

% Equivalent viscous damping ratio is F/(2*sqrt(k*m)*v).  It is undefined
% at zero velocity, so leave that single point out of the plot rather than
% dividing digitizer noise by an almost-zero velocity.
damping_ratio_actual = NaN(size(force_si));
damping_ratio_design = NaN(size(c_designsmooth));
nonzero_velocity = abs(vel_si) > eps;
damping_ratio_actual(nonzero_velocity) = abs(force_si(nonzero_velocity)) ...
    ./ c_crit(nonzero_velocity);
damping_ratio_design(nonzero_velocity) = abs(c_designsmooth(nonzero_velocity)) ...
    ./ c_crit(nonzero_velocity);

figure
plot(t_sol, 1000*x1, 'LineWidth', 1.5)
hold on
plot(t_sol, 1000*x2, 'LineWidth', 1.5)
plot(t_sol, 1000*road_sol, 'k--', 'LineWidth', 1.2)
legend('Sprung mass', 'Unsprung mass', 'Road input')
xlabel('Time (s)', 'FontSize', 14)
ylabel('Displacement (mm)', 'FontSize', 14)
title(sprintf('Response to %s at %.0f m/s', ...
    strrep(profile_type, '_', ' '), vehicle_speed), 'FontSize', 20)
xlim([max(0, road_info.start_time - 0.1), ...
      min(tmax, road_info.end_time + 1.5)])
grid on

figure
plot(xq, damping_ratio_actual, 'Linewidth', 2)
xlabel('Velocity (mm/s)', 'FontSize', 14)
ylabel('Damping Ratio', 'FontSize', 14)
title('Damping Ratio vs. Velocity, Front', 'FontSize', 20)
grid on
ylim([0 1])

figure
plot(xq, damping_ratio_design, 'LineWidth', 1.5) 
hold on
plot(xq, damping_ratio_actual, 'LineWidth', 1.5)
xlabel('Velocity (mm/s)', 'FontSize', 14)
ylabel('Damping Ratio', 'FontSize', 14)
title('Damping Ratio vs. Velocity', 'FontSize', 20)
grid on
ylim([0 1])
xlim([-250 250])
legend('Designed', 'Actual', 'Location','bestoutside')

figure
plot(xq, c_designsmooth, xq, force_si)
legend('Desired', 'Actual')
xlabel('Velocity (mm/s)')
ylabel('Force, N')
title('Desired vs Actual Damping Curve')
grid on

