% =========================================================================
% QUARTER-CAR ROAD-CONDITION SWEEP - FRONT CORNER
% =========================================================================
% Runs the current nonlinear Ohlins damper model over representative road
% inputs.  The resulting table and plots are the evaluation layer that a
% later damper-click optimizer can minimize.

clearvars
close all
clc

model_dir = fileparts(mfilename('fullpath'));

% --- FRONT-CORNER VEHICLE PARAMETERS ---
m1 = 141.885/2;     % sprung mass, kg
m2 = 22.36/2;       % unsprung mass, kg
k = 35683.525;      % suspension spring rate, N/m
kt = 101573.528;    % tire vertical stiffness, N/m

% --- CURRENT OHLINS TTX25 SETTINGS ---
damper_settings = struct( ...
    'ls_rebound', 2, ...
    'hs_rebound', 3, ...
    'ls_compression', 4, ...
    'hs_compression', 1);

[damper_velocity, damper_force] = build_damper_curve( ...
    fullfile(model_dir, 'damper_3D_matrix.mat'), damper_settings);

% --- SIMULATION TIME ---
dt = 0.001;
tmax = 4.0;
t_vec = (0:dt:tmax).';

% Each profile is spatial.  Vehicle speed controls how quickly the tire
% traverses it without changing its physical height or length.
scenarios = [ ...
    struct('name', "Smooth finite bump", 'type', "smooth_bump", ...
        'speeds', [5 10 15 20], ...
        'params', struct('height', 0.030, 'length', 0.400, ...
                         'start_time', 1.0)); ...
    struct('name', "Short sharp bump", 'type', "sharp_bump", ...
        'speeds', 10, ...
        'params', struct('height', 0.020, 'length', 0.100, ...
                         'start_time', 1.0)); ...
    struct('name', "Pothole", 'type', "pothole", ...
        'speeds', 10, ...
        'params', struct('depth', 0.030, 'length', 0.400, ...
                         'start_time', 1.0)); ...
    struct('name', "Sinusoidal / washboard", 'type', "washboard", ...
        'speeds', 10, ...
        'params', struct('amplitude', 0.005, 'wavelength', 0.500, ...
                         'length', 5.000, 'start_time', 1.0)); ...
    struct('name', "Random rough road", 'type', "rough", ...
        'speeds', 10, ...
        'params', struct('rms_height', 0.003, 'length', 10.000, ...
                         'seed', 42, 'start_time', 1.0)); ...
    struct('name', "Flat-road sanity check", 'type', "flat", ...
        'speeds', 10, ...
        'params', struct('start_time', 1.0))];

results = struct([]);
result_index = 0;

for scenario_index = 1:numel(scenarios)
    scenario = scenarios(scenario_index);

    for vehicle_speed = scenario.speeds
        [road_input, road_info] = generate_road_profile( ...
            scenario.type, t_vec, vehicle_speed, scenario.params);

        response = simulate_quarter_car(t_vec, road_input, ...
            m1, m2, k, kt, damper_velocity, damper_force, dt);

        metrics = calculate_response_metrics(response, m1, m2, k, kt, ...
            road_info, tmax);

        result_index = result_index + 1;
        results(result_index).scenario_index = scenario_index;
        results(result_index).name = scenario.name;
        results(result_index).type = scenario.type;
        results(result_index).speed = vehicle_speed;
        results(result_index).road_info = road_info;
        results(result_index).road = road_input;
        results(result_index).response = response;
        results(result_index).metrics = metrics;
    end
end

% --- SUMMARY TABLE ---
condition = strings(numel(results), 1);
speed_mps = zeros(numel(results), 1);
speed_kph = zeros(numel(results), 1);
tire_load_rms_percent = zeros(numel(results), 1);
peak_suspension_travel_mm = zeros(numel(results), 1);
body_acceleration_rms = zeros(numel(results), 1);
minimum_tire_load_percent = zeros(numel(results), 1);
contact_loss_predicted = false(numel(results), 1);

for result_index = 1:numel(results)
    condition(result_index) = results(result_index).name;
    speed_mps(result_index) = results(result_index).speed;
    speed_kph(result_index) = 3.6*results(result_index).speed;
    tire_load_rms_percent(result_index) = ...
        100*results(result_index).metrics.normalized_tire_load_rms;
    peak_suspension_travel_mm(result_index) = ...
        1000*results(result_index).metrics.peak_suspension_travel;
    body_acceleration_rms(result_index) = ...
        results(result_index).metrics.body_acceleration_rms;
    minimum_tire_load_percent(result_index) = ...
        100*results(result_index).metrics.minimum_tire_load_ratio;
    contact_loss_predicted(result_index) = ...
        results(result_index).metrics.minimum_tire_load_ratio <= 0;
end

summary_table = table(condition, speed_mps, speed_kph, ...
    tire_load_rms_percent, peak_suspension_travel_mm, ...
    body_acceleration_rms, minimum_tire_load_percent, ...
    contact_loss_predicted, ...
    'VariableNames', {'RoadCondition', 'Speed_mps', 'Speed_kph', ...
    'TireLoadRMS_percent', 'PeakSuspensionTravel_mm', ...
    'BodyAccelerationRMS_mps2', 'MinimumTireLoad_percent', ...
    'ContactLossPredicted'});

disp(summary_table)

% --- ROAD-INPUT PLOTS ---
road_figure = figure('Name', 'Road-condition inputs', ...
    'Color', 'k');
road_layout = tiledlayout(3, 2, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

for scenario_index = 1:numel(scenarios)
    nexttile
    hold on
    selected = find([results.scenario_index] == scenario_index);
    for result_index = selected
        plot(t_vec, 1000*results(result_index).road, 'LineWidth', 1.4, ...
            'DisplayName', sprintf('%.0f m/s', results(result_index).speed));
    end
    title(scenarios(scenario_index).name)
    xlabel('Time (s)')
    ylabel('Road height (mm)')
    grid on
    xlim(profile_plot_limits(results(selected), tmax, 0.15))
    if numel(selected) > 1
        legend('Location', 'best')
    end
end
title(road_layout, 'Road Inputs')
apply_dark_theme(road_figure)

% --- NORMALIZED TIRE-LOAD RESPONSE PLOTS ---
load_figure = figure('Name', 'Tire-load responses', ...
    'Color', 'k');
load_layout = tiledlayout(3, 2, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

for scenario_index = 1:numel(scenarios)
    nexttile
    hold on
    selected = find([results.scenario_index] == scenario_index);
    for result_index = selected
        response = results(result_index).response;
        plot(response.t, response.tire_load/response.static_tire_load, ...
            'LineWidth', 1.3, ...
            'DisplayName', sprintf('%.0f m/s', results(result_index).speed));
    end
    yline(1, '--', 'Color', [0.75 0.75 0.75], ...
        'HandleVisibility', 'off')
    title(scenarios(scenario_index).name)
    xlabel('Time (s)')
    ylabel('F_z/F_{z,static}')
    grid on
    xlim(profile_plot_limits(results(selected), tmax, 1.0))
    if numel(selected) > 1
        legend('Location', 'best')
    end
end
title(load_layout, 'Normalized Tire Load')
apply_dark_theme(load_figure)

% --- METRIC COMPARISON ---
case_labels = strings(numel(results), 1);
for result_index = 1:numel(results)
    case_labels(result_index) = sprintf('%s\n%.0f m/s', ...
        results(result_index).name, results(result_index).speed);
end

metrics_figure = figure('Name', 'Road-condition metrics', ...
    'Color', 'k');
bar(tire_load_rms_percent)
xticks(1:numel(results))
xticklabels(case_labels)
xtickangle(35)
ylabel('RMS dynamic tire load / static load (%)')
title('Tire-Load Variability with Current Damper Settings')
grid on
apply_dark_theme(metrics_figure)

% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================
function [velocity_mps, force_n] = build_damper_curve(matrix_file, settings)
data = load(matrix_file);
velocity_mmps = double(data.vel_mm(:));
ls_settings = double(data.ls_settings(:));
hs_settings = double(data.hs_settings(:));
force_matrix = double(data.Force_3D);

force_lookup = griddedInterpolant( ...
    {velocity_mmps, ls_settings, hs_settings}, force_matrix, ...
    'linear', 'nearest');

rebound_force = force_lookup(velocity_mmps, ...
    settings.ls_rebound*ones(size(velocity_mmps)), ...
    settings.hs_rebound*ones(size(velocity_mmps)));
compression_force = force_lookup(velocity_mmps, ...
    settings.ls_compression*ones(size(velocity_mmps)), ...
    settings.hs_compression*ones(size(velocity_mmps)));

force_n = zeros(size(velocity_mmps));
force_n(velocity_mmps < 0) = rebound_force(velocity_mmps < 0);
force_n(velocity_mmps >= 0) = compression_force(velocity_mmps >= 0);
velocity_mps = velocity_mmps/1000;
end

function response = simulate_quarter_car(t_vec, road_input, ...
    m1, m2, k, kt, damper_velocity, damper_force, output_step)

initial_state = [0; 0; 0; 0];
options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, ...
    'MaxStep', output_step/2);

[t_sol, state] = ode45(@(t, x) quarter_car_rhs(t, x, ...
    m1, m2, k, kt, damper_velocity, damper_force, ...
    t_vec, road_input), t_vec, initial_state, options);

road_at_solution = interp1(t_vec, road_input, t_sol, 'linear', 0);
x1 = state(:, 1);
x1_velocity = state(:, 2);
x2 = state(:, 3);
x2_velocity = state(:, 4);

relative_velocity = x1_velocity - x2_velocity;
clamped_velocity = min(max(relative_velocity, damper_velocity(1)), ...
    damper_velocity(end));
damper_force_at_solution = interp1(damper_velocity, damper_force, ...
    clamped_velocity, 'linear');
body_acceleration = (-k*(x1 - x2) - damper_force_at_solution)/m1;

static_tire_load = (m1 + m2)*9.81;
dynamic_tire_load = kt*(road_at_solution - x2);
tire_load = static_tire_load + dynamic_tire_load;

response = struct( ...
    't', t_sol, ...
    'state', state, ...
    'road', road_at_solution, ...
    'x1', x1, ...
    'x2', x2, ...
    'suspension_travel', x1 - x2, ...
    'body_acceleration', body_acceleration, ...
    'dynamic_tire_load', dynamic_tire_load, ...
    'static_tire_load', static_tire_load, ...
    'tire_load', tire_load);
end

function derivative = quarter_car_rhs(t, state, m1, m2, k, kt, ...
    damper_velocity, damper_force, road_time, road_height)

x1 = state(1);
x1_velocity = state(2);
x2 = state(3);
x2_velocity = state(4);
road = interp1(road_time, road_height, t, 'linear', 0);

relative_velocity = x1_velocity - x2_velocity;
relative_velocity = min(max(relative_velocity, damper_velocity(1)), ...
    damper_velocity(end));
force = interp1(damper_velocity, damper_force, relative_velocity, 'linear');

x1_acceleration = (-k*(x1 - x2) - force)/m1;
x2_acceleration = (k*(x1 - x2) + force - kt*(x2 - road))/m2;

derivative = [x1_velocity; x1_acceleration; ...
              x2_velocity; x2_acceleration];
end

function metrics = calculate_response_metrics(response, m1, m2, ~, ~, ...
    road_info, tmax)
analysis_start = max(0, road_info.start_time - 0.05);
analysis_end = min(tmax, max(road_info.end_time, road_info.start_time) + 1.5);
window = response.t >= analysis_start & response.t <= analysis_end;

if ~any(window)
    window = true(size(response.t));
end

dynamic_load = response.dynamic_tire_load(window);
static_load = (m1 + m2)*9.81;
tire_load = response.tire_load(window);
suspension_travel = response.suspension_travel(window);
body_acceleration = response.body_acceleration(window);

metrics = struct( ...
    'normalized_tire_load_rms', ...
        sqrt(mean(dynamic_load.^2))/static_load, ...
    'peak_suspension_travel', max(abs(suspension_travel)), ...
    'body_acceleration_rms', sqrt(mean(body_acceleration.^2)), ...
    'minimum_tire_load_ratio', min(tire_load)/static_load, ...
    'analysis_start', analysis_start, ...
    'analysis_end', analysis_end);
end

function limits = profile_plot_limits(selected_results, tmax, post_time)
profile_lengths = arrayfun(@(result) result.road_info.length, selected_results);
if all(profile_lengths == 0)
    limits = [0 tmax];
    return
end

start_times = arrayfun(@(result) result.road_info.start_time, selected_results);
end_times = arrayfun(@(result) result.road_info.end_time, selected_results);
limits = [max(0, min(start_times) - 0.1), ...
          min(tmax, max(end_times) + post_time)];
end

function apply_dark_theme(fig)
%APPLY_DARK_THEME Style a completed figure for on-screen use and export.
background = [0.06 0.06 0.06];
foreground = [0.90 0.90 0.90];

fig.Color = background;

axes_handles = findall(fig, 'Type', 'axes');
set(axes_handles, ...
    'Color', background, ...
    'XColor', foreground, ...
    'YColor', foreground, ...
    'GridColor', [0.55 0.55 0.55], ...
    'MinorGridColor', [0.35 0.35 0.35]);

text_handles = findall(fig, 'Type', 'text');
set(text_handles, 'Color', foreground);

legend_handles = findall(fig, 'Type', 'legend');
set(legend_handles, ...
    'Color', background, ...
    'TextColor', foreground, ...
    'EdgeColor', [0.60 0.60 0.60]);
end
