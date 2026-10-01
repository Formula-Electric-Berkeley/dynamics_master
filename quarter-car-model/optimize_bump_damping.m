% =========================================================================
% FRONT/REAR QUARTER-CAR DAMPER OPTIMIZATION - SMOOTH BUMP
% =========================================================================
% Motion ratio convention: damper travel / wheel travel.
% The exhaustive search uses vectorized fixed-step RK4 for speed.  Baseline
% and winning cases are then rerun with ode45 for authoritative reporting.

clearvars
close all
clc

model_dir = fileparts(mfilename('fullpath'));
matrix_file = fullfile(model_dir, 'damper_3D_matrix.mat');
vehicle = quarter_car_parameters();

baseline_settings = struct( ...
    'ls_rebound', 2, ...
    'hs_rebound', 3, ...
    'ls_compression', 4, ...
    'hs_compression', 1);

% --- BUMP AND NUMERICAL CONFIGURATION ---
vehicle_speeds = [5 10 15 20]; % m/s
bump_parameters = struct('height', 0.030, 'length', 0.400, ...
    'start_time', 0.5);
dt = 0.0005;
tmax = 2.1;
t_vec = (0:dt:tmax).';

% --- ALL DISCRETE TTX25 SETTING COMBINATIONS ---
damper_data = load(matrix_file);
[candidate_settings, candidate_force_curves, damper_velocity] = ...
    build_candidate_curves(damper_data);
baseline_index = find_baseline(candidate_settings, baseline_settings);

corners = {vehicle.front, vehicle.rear};
optimization_results = struct([]);

fprintf('Evaluating %d damper combinations at %d bump speeds...\n', ...
    height(candidate_settings), numel(vehicle_speeds));

for corner_index = 1:numel(corners)
    corner = corners{corner_index};
    fprintf('  %s corner...\n', corner.name);

    fixed_step_scores = evaluate_candidates(corner, t_vec, ...
        vehicle_speeds, bump_parameters, damper_velocity, ...
        candidate_force_curves);
    [winning_index, is_fully_feasible] = select_winner(fixed_step_scores);

    validation_indices = [baseline_index winning_index];
    validation_labels = ["Baseline" "Optimized"];
    validated = struct([]);

    for validation_index = 1:numel(validation_indices)
        candidate_index = validation_indices(validation_index);
        settings = table_row_to_settings(candidate_settings, candidate_index);
        [curve_velocity, curve_force] = build_ttx25_damper_curve( ...
            matrix_file, settings);

        for speed_index = 1:numel(vehicle_speeds)
            speed = vehicle_speeds(speed_index);
            [road_input, road_info] = generate_road_profile( ...
                "smooth_bump", t_vec, speed, bump_parameters);
            response = simulate_quarter_car_response(t_vec, road_input, ...
                corner, curve_velocity, curve_force, ...
                MaxStep=dt/2);
            metrics = response_metrics(response, road_info, tmax);

            validated(validation_index).label = ...
                validation_labels(validation_index);
            validated(validation_index).candidate_index = candidate_index;
            validated(validation_index).settings = settings;
            validated(validation_index).damper_velocity = curve_velocity;
            validated(validation_index).damper_force = curve_force;
            validated(validation_index).responses(speed_index) = response;
            validated(validation_index).metrics(speed_index) = metrics;
        end
    end

    rk4_objective = fixed_step_scores.mean_load_rms(winning_index);
    ode_objective = mean([validated(2).metrics.normalized_tire_load_rms]);
    objective_difference = abs(ode_objective - rk4_objective) ...
        / max(ode_objective, eps);
    if objective_difference > 0.01
        warning('optimize_bump_damping:ValidationDifference', ...
            ['%s RK4 and ode45 objectives differ by %.2f%%. ' ...
             'Consider reducing dt.'], corner.name, 100*objective_difference);
    end

    optimization_results(corner_index).corner = corner;
    optimization_results(corner_index).candidate_settings = candidate_settings;
    optimization_results(corner_index).fixed_step_scores = fixed_step_scores;
    optimization_results(corner_index).baseline_index = baseline_index;
    optimization_results(corner_index).winning_index = winning_index;
    optimization_results(corner_index).fully_feasible = is_fully_feasible;
    optimization_results(corner_index).validated = validated;
    optimization_results(corner_index).rk4_objective = rk4_objective;
    optimization_results(corner_index).ode45_objective = ode_objective;
    optimization_results(corner_index).validation_difference = ...
        objective_difference;
end

settings_summary = build_settings_summary(optimization_results);
speed_summary = build_speed_summary(optimization_results, vehicle_speeds);

fprintf('\nOptimized settings and combined bump objective:\n')
disp(settings_summary)
fprintf('Per-speed ode45 validation metrics:\n')
disp(speed_summary)

if any(~[optimization_results.fully_feasible])
    warning('optimize_bump_damping:NoFullyFeasibleSetting', ...
        ['At least one axle has no setting that maintains tire contact at ' ...
         'all four speeds. Its result minimizes contact-loss duration first.']);
end

% --- REQUESTED BUMP-DISPLACEMENT PLOT (10 m/s) ---
plot_speed = 10;
plot_speed_index = find(vehicle_speeds == plot_speed, 1);
displacement_figure = figure('Name', 'Bump displacement response', ...
    'Color', 'k');
displacement_layout = tiledlayout(2, 2, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

for corner_index = 1:numel(optimization_results)
    result = optimization_results(corner_index);
    for validation_index = 1:2
        nexttile
        response = result.validated(validation_index) ...
            .responses(plot_speed_index);
        plot(response.t, 1000*response.road, '--', ...
            'Color', [0.40 0.90 0.55], 'LineWidth', 1.2)
        hold on
        plot(response.t, 1000*response.x1, ...
            'Color', [0.30 0.72 0.96], 'LineWidth', 1.7)
        plot(response.t, 1000*response.x2, ...
            'Color', [0.96 0.50 0.28], 'LineWidth', 1.4)
        grid on
        xlim([bump_parameters.start_time - 0.05, ...
            bump_parameters.start_time + 1.5])
        xlabel('Time (s)')
        ylabel('Vertical displacement (mm)')
        title(sprintf('%s - %s', result.corner.name, ...
            result.validated(validation_index).label))
        legend('Road', 'Sprung mass', 'Unsprung mass', ...
            'Location', 'best')
    end
end
title(displacement_layout, sprintf( ...
    '30 mm x 400 mm Bump Displacement at %.0f m/s', plot_speed))
apply_dark_theme(displacement_figure)

% --- BASELINE VERSUS OPTIMIZED TIRE LOAD AT EVERY SPEED ---
tire_load_figure = figure('Name', 'Bump tire-load comparison', ...
    'Color', 'k');
tire_layout = tiledlayout(2, numel(vehicle_speeds), ...
    'TileSpacing', 'compact', 'Padding', 'compact');

for corner_index = 1:numel(optimization_results)
    result = optimization_results(corner_index);
    for speed_index = 1:numel(vehicle_speeds)
        nexttile
        baseline_response = result.validated(1).responses(speed_index);
        optimized_response = result.validated(2).responses(speed_index);
        plot(baseline_response.t, baseline_response.tire_load ...
            / baseline_response.static_tire_load, '--', ...
            'Color', [0.65 0.65 0.65], 'LineWidth', 1.1)
        hold on
        plot(optimized_response.t, optimized_response.tire_load ...
            / optimized_response.static_tire_load, ...
            'Color', [0.30 0.72 0.96], 'LineWidth', 1.5)
        yline(1, ':', 'Color', [0.75 0.75 0.75], ...
            'HandleVisibility', 'off')
        grid on
        xlim([bump_parameters.start_time - 0.05, ...
            bump_parameters.start_time + 1.5])
        xlabel('Time (s)')
        ylabel('F_z/F_{z,static}')
        title(sprintf('%s, %.0f m/s', result.corner.name, ...
            vehicle_speeds(speed_index)))
        legend('Baseline', 'Optimized', 'Location', 'best')
    end
end
title(tire_layout, 'Normalized Tire Load: Baseline vs Optimized')
apply_dark_theme(tire_load_figure)

% --- BASELINE VERSUS OPTIMIZED PHYSICAL DAMPER CURVES ---
damper_figure = figure('Name', 'Optimized damper curves', 'Color', 'k');
damper_layout = tiledlayout(1, 2, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

for corner_index = 1:numel(optimization_results)
    result = optimization_results(corner_index);
    nexttile
    plot(1000*result.validated(1).damper_velocity, ...
        result.validated(1).damper_force, '--', ...
        'Color', [0.65 0.65 0.65], 'LineWidth', 1.2)
    hold on
    plot(1000*result.validated(2).damper_velocity, ...
        result.validated(2).damper_force, ...
        'Color', [0.30 0.72 0.96], 'LineWidth', 1.7)
    xline(0, ':', 'Color', [0.55 0.55 0.55], ...
        'HandleVisibility', 'off')
    yline(0, ':', 'Color', [0.55 0.55 0.55], ...
        'HandleVisibility', 'off')
    xlabel('Damper shaft velocity (mm/s)')
    ylabel('Damper force (N)')
    title(result.corner.name)
    legend('Baseline', 'Optimized', 'Location', 'best')
    grid on
end
title(damper_layout, 'Physical Damper Curves')
apply_dark_theme(damper_figure)

% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================
function [settings_table, force_curves, velocity_mps] = ...
    build_candidate_curves(data)

velocity_mmps = double(data.vel_mm(:));
ls_values = double(data.ls_settings(:)).';
hs_values = double(data.hs_settings(:)).';
force_matrix = double(data.Force_3D);

[ls_rebound, hs_rebound, ls_compression, hs_compression] = ndgrid( ...
    ls_values, hs_values, ls_values, hs_values);
settings_table = table(ls_rebound(:), hs_rebound(:), ...
    ls_compression(:), hs_compression(:), ...
    'VariableNames', {'LSRebound', 'HSRebound', ...
                      'LSCompression', 'HSCompression'});

candidate_count = height(settings_table);
force_curves = zeros(numel(velocity_mmps), candidate_count);
rebound_rows = velocity_mmps < 0;
compression_rows = ~rebound_rows;

for candidate_index = 1:candidate_count
    ls_rebound_index = find(ls_values == ...
        settings_table.LSRebound(candidate_index), 1);
    hs_rebound_index = find(hs_values == ...
        settings_table.HSRebound(candidate_index), 1);
    ls_compression_index = find(ls_values == ...
        settings_table.LSCompression(candidate_index), 1);
    hs_compression_index = find(hs_values == ...
        settings_table.HSCompression(candidate_index), 1);

    rebound_curve = force_matrix(:, ls_rebound_index, hs_rebound_index);
    compression_curve = force_matrix(:, ls_compression_index, ...
        hs_compression_index);
    force_curves(rebound_rows, candidate_index) = ...
        rebound_curve(rebound_rows);
    force_curves(compression_rows, candidate_index) = ...
        compression_curve(compression_rows);
end

velocity_mps = velocity_mmps/1000;
end

function index = find_baseline(settings_table, baseline)
matches = settings_table.LSRebound == baseline.ls_rebound & ...
    settings_table.HSRebound == baseline.hs_rebound & ...
    settings_table.LSCompression == baseline.ls_compression & ...
    settings_table.HSCompression == baseline.hs_compression;
index = find(matches, 1);
assert(~isempty(index), 'Baseline setting is not in the discrete search grid.');
end

function scores = evaluate_candidates(corner, t_vec, speeds, bump_parameters, ...
    damper_velocity, force_curves)

candidate_count = size(force_curves, 2);
speed_count = numel(speeds);
load_rms = zeros(candidate_count, speed_count);
contact_duration = zeros(candidate_count, speed_count);
peak_travel = zeros(candidate_count, speed_count);
minimum_load_ratio = zeros(candidate_count, speed_count);

for speed_index = 1:speed_count
    [road, road_info] = generate_road_profile( ...
        "smooth_bump", t_vec, speeds(speed_index), bump_parameters);
    metrics = vectorized_rk4_metrics(corner, t_vec, road, road_info, ...
        damper_velocity, force_curves);
    load_rms(:, speed_index) = metrics.normalized_tire_load_rms;
    contact_duration(:, speed_index) = metrics.contact_loss_duration;
    peak_travel(:, speed_index) = metrics.peak_suspension_travel;
    minimum_load_ratio(:, speed_index) = metrics.minimum_tire_load_ratio;
end

scores = struct( ...
    'normalized_tire_load_rms', load_rms, ...
    'contact_loss_duration', contact_duration, ...
    'peak_suspension_travel', peak_travel, ...
    'minimum_tire_load_ratio', minimum_load_ratio, ...
    'mean_load_rms', mean(load_rms, 2), ...
    'total_contact_loss_duration', sum(contact_duration, 2));
end

function metrics = vectorized_rk4_metrics(corner, t_vec, road, road_info, ...
    damper_velocity, force_curves)

candidate_count = size(force_curves, 2);
state = zeros(4, candidate_count);
dt = t_vec(2) - t_vec(1);
analysis_start = max(0, road_info.start_time - 0.05);
analysis_end = min(t_vec(end), road_info.end_time + 1.5);

load_square_sum = zeros(1, candidate_count);
sample_count = 0;
contact_samples = zeros(1, candidate_count);
peak_travel = zeros(1, candidate_count);
minimum_load = inf(1, candidate_count);

for time_index = 1:numel(t_vec)
    if t_vec(time_index) >= analysis_start && ...
            t_vec(time_index) <= analysis_end
        [normal_load, suspension_travel] = state_outputs( ...
            state, road(time_index), corner);
        dynamic_load = normal_load - corner.static_tire_load;
        load_square_sum = load_square_sum + dynamic_load.^2;
        sample_count = sample_count + 1;
        contact_samples = contact_samples + (normal_load <= 1e-12);
        peak_travel = max(peak_travel, abs(suspension_travel));
        minimum_load = min(minimum_load, normal_load);
    end

    if time_index == numel(t_vec)
        break
    end

    road_start = road(time_index);
    road_end = road(time_index + 1);
    road_half = 0.5*(road_start + road_end);

    k1 = candidate_rhs(state, road_start, corner, ...
        damper_velocity, force_curves);
    k2 = candidate_rhs(state + 0.5*dt*k1, road_half, corner, ...
        damper_velocity, force_curves);
    k3 = candidate_rhs(state + 0.5*dt*k2, road_half, corner, ...
        damper_velocity, force_curves);
    k4 = candidate_rhs(state + dt*k3, road_end, corner, ...
        damper_velocity, force_curves);
    state = state + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
end

metrics = struct( ...
    'normalized_tire_load_rms', ...
        (sqrt(load_square_sum/sample_count)/corner.static_tire_load).', ...
    'contact_loss_duration', (contact_samples*dt).', ...
    'peak_suspension_travel', peak_travel.', ...
    'minimum_tire_load_ratio', ...
        (minimum_load/corner.static_tire_load).');
end

function derivative = candidate_rhs(state, road, corner, ...
    damper_velocity, force_curves)

x1 = state(1, :);
x1_velocity = state(2, :);
x2 = state(3, :);
x2_velocity = state(4, :);

shaft_velocity = corner.motion_ratio*(x2_velocity - x1_velocity);
shaft_force = candidate_force_lookup(shaft_velocity, ...
    damper_velocity, force_curves);
damper_force_on_body = corner.motion_ratio*shaft_force;
spring_force_on_body = -corner.wheel_rate*(x1 - x2);
normal_load = max(0, corner.static_tire_load + ...
    corner.tire_rate*(road - x2));
dynamic_tire_force = normal_load - corner.static_tire_load;

x1_acceleration = (spring_force_on_body + damper_force_on_body) ...
    / corner.sprung_mass;
x2_acceleration = (-spring_force_on_body - damper_force_on_body + ...
    dynamic_tire_force)/corner.unsprung_mass;

derivative = [x1_velocity; x1_acceleration; ...
              x2_velocity; x2_acceleration];
end

function force = candidate_force_lookup(velocity, velocity_grid, force_curves)
% One independent curve is stored in each column of force_curves.
velocity = min(max(velocity, velocity_grid(1)), velocity_grid(end));
grid_step = velocity_grid(2) - velocity_grid(1);
position = (velocity - velocity_grid(1))/grid_step + 1;
lower_row = floor(position);
lower_row = min(max(lower_row, 1), numel(velocity_grid) - 1);
fraction = position - lower_row;

candidate_count = size(force_curves, 2);
column_offset = (0:candidate_count-1)*size(force_curves, 1);
lower_index = lower_row + column_offset;
force = force_curves(lower_index).*(1 - fraction) + ...
    force_curves(lower_index + 1).*fraction;
end

function [normal_load, suspension_travel] = state_outputs(state, road, corner)
x1 = state(1, :);
x2 = state(3, :);
normal_load = max(0, corner.static_tire_load + ...
    corner.tire_rate*(road - x2));
suspension_travel = x1 - x2;
end

function [winning_index, fully_feasible] = select_winner(scores)
contact_tolerance = 1e-12;
feasible = scores.total_contact_loss_duration <= contact_tolerance;
fully_feasible = any(feasible);

if fully_feasible
    feasible_indices = find(feasible);
    [~, local_index] = min(scores.mean_load_rms(feasible));
    winning_index = feasible_indices(local_index);
else
    ranking = [scores.total_contact_loss_duration, scores.mean_load_rms];
    [~, order] = sortrows(ranking, [1 2]);
    winning_index = order(1);
end
end

function settings = table_row_to_settings(settings_table, row)
settings = struct( ...
    'ls_rebound', settings_table.LSRebound(row), ...
    'hs_rebound', settings_table.HSRebound(row), ...
    'ls_compression', settings_table.LSCompression(row), ...
    'hs_compression', settings_table.HSCompression(row));
end

function metrics = response_metrics(response, road_info, tmax)
analysis_start = max(0, road_info.start_time - 0.05);
analysis_end = min(tmax, road_info.end_time + 1.5);
window = response.t >= analysis_start & response.t <= analysis_end;
sample_step = median(diff(response.t));

dynamic_load = response.dynamic_tire_load(window);
metrics = struct( ...
    'normalized_tire_load_rms', ...
        sqrt(mean(dynamic_load.^2))/response.static_tire_load, ...
    'contact_loss_duration', sum(response.contact_lost(window))*sample_step, ...
    'peak_suspension_travel', ...
        max(abs(response.suspension_travel(window))), ...
    'minimum_tire_load_ratio', ...
        min(response.tire_load(window))/response.static_tire_load);
end

function summary = build_settings_summary(results)
row_count = 2*numel(results);
axle = strings(row_count, 1);
configuration = strings(row_count, 1);
ls_rebound = zeros(row_count, 1);
hs_rebound = zeros(row_count, 1);
ls_compression = zeros(row_count, 1);
hs_compression = zeros(row_count, 1);
mean_load_rms_percent = zeros(row_count, 1);
contact_loss_duration = zeros(row_count, 1);
feasible_at_all_speeds = false(row_count, 1);

row = 0;
for result_index = 1:numel(results)
    for validation_index = 1:2
        row = row + 1;
        validated = results(result_index).validated(validation_index);
        metrics = validated.metrics;
        axle(row) = results(result_index).corner.name;
        configuration(row) = validated.label;
        ls_rebound(row) = validated.settings.ls_rebound;
        hs_rebound(row) = validated.settings.hs_rebound;
        ls_compression(row) = validated.settings.ls_compression;
        hs_compression(row) = validated.settings.hs_compression;
        mean_load_rms_percent(row) = ...
            100*mean([metrics.normalized_tire_load_rms]);
        contact_loss_duration(row) = ...
            sum([metrics.contact_loss_duration]);
        feasible_at_all_speeds(row) = contact_loss_duration(row) <= 1e-12;
    end
end

summary = table(axle, configuration, ls_rebound, hs_rebound, ...
    ls_compression, hs_compression, mean_load_rms_percent, ...
    contact_loss_duration, feasible_at_all_speeds, ...
    'VariableNames', {'Axle', 'Configuration', 'LSRebound', 'HSRebound', ...
    'LSCompression', 'HSCompression', 'MeanTireLoadRMS_percent', ...
    'TotalContactLoss_s', 'FeasibleAtAllSpeeds'});
end

function summary = build_speed_summary(results, speeds)
row_count = 2*numel(results)*numel(speeds);
axle = strings(row_count, 1);
configuration = strings(row_count, 1);
speed_mps = zeros(row_count, 1);
load_rms_percent = zeros(row_count, 1);
peak_travel_mm = zeros(row_count, 1);
minimum_load_percent = zeros(row_count, 1);
contact_loss_duration = zeros(row_count, 1);

row = 0;
for result_index = 1:numel(results)
    for validation_index = 1:2
        for speed_index = 1:numel(speeds)
            row = row + 1;
            metrics = results(result_index).validated(validation_index) ...
                .metrics(speed_index);
            axle(row) = results(result_index).corner.name;
            configuration(row) = results(result_index) ...
                .validated(validation_index).label;
            speed_mps(row) = speeds(speed_index);
            load_rms_percent(row) = ...
                100*metrics.normalized_tire_load_rms;
            peak_travel_mm(row) = 1000*metrics.peak_suspension_travel;
            minimum_load_percent(row) = ...
                100*metrics.minimum_tire_load_ratio;
            contact_loss_duration(row) = metrics.contact_loss_duration;
        end
    end
end

summary = table(axle, configuration, speed_mps, load_rms_percent, ...
    peak_travel_mm, minimum_load_percent, contact_loss_duration, ...
    'VariableNames', {'Axle', 'Configuration', 'Speed_mps', ...
    'TireLoadRMS_percent', 'PeakSuspensionTravel_mm', ...
    'MinimumTireLoad_percent', 'ContactLoss_s'});
end

function apply_dark_theme(fig)
background = [0.06 0.06 0.06];
foreground = [0.90 0.90 0.90];
fig.Color = background;

axes_handles = findall(fig, 'Type', 'axes');
set(axes_handles, 'Color', background, 'XColor', foreground, ...
    'YColor', foreground, 'GridColor', [0.55 0.55 0.55], ...
    'MinorGridColor', [0.35 0.35 0.35]);
text_handles = findall(fig, 'Type', 'text');
set(text_handles, 'Color', foreground);
legend_handles = findall(fig, 'Type', 'legend');
set(legend_handles, 'Color', background, 'TextColor', foreground, ...
    'EdgeColor', [0.60 0.60 0.60]);
end
