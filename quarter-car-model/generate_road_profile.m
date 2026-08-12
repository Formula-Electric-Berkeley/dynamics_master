function [road_height, info] = generate_road_profile(profile_type, t, vehicle_speed, params)
%GENERATE_ROAD_PROFILE Create a road-height input for the quarter-car model.
%   [ROAD_HEIGHT, INFO] = GENERATE_ROAD_PROFILE(TYPE, T, SPEED, PARAMS)
%   evaluates a spatial road profile at x = SPEED*(T - START_TIME).
%
%   Supported TYPE values:
%       "smooth_bump" - finite half-cosine bump
%       "sharp_bump"  - short finite half-cosine bump
%       "pothole"     - finite negative half-cosine bump
%       "washboard"   - finite sinusoidal road section
%       "rough"       - deterministic band-limited random road
%       "flat"        - zero road height (sanity check)
%
%   Heights and lengths are in metres, speed is in m/s, and time is in s.

arguments
    profile_type {mustBeTextScalar}
    t double
    vehicle_speed (1,1) double {mustBePositive}
    params struct = struct()
end

profile_type = lower(string(profile_type));
t_shape = size(t);
t = t(:);
start_time = get_param(params, 'start_time', 1.0);
x = vehicle_speed*(t - start_time);
road_height = zeros(size(t));

info = struct( ...
    'type', profile_type, ...
    'vehicle_speed', vehicle_speed, ...
    'start_time', start_time, ...
    'end_time', start_time, ...
    'length', 0, ...
    'distance', x, ...
    'description', "");

switch profile_type
    case "smooth_bump"
        height = get_param(params, 'height', 0.030);
        profile_length = get_param(params, 'length', 0.400);
        active = x >= 0 & x <= profile_length;
        phase = x(active)/profile_length;
        road_height(active) = 0.5*height*(1 - cos(2*pi*phase));
        info.description = sprintf('%.0f mm x %.0f mm smooth bump', ...
            1000*height, 1000*profile_length);

    case "sharp_bump"
        height = get_param(params, 'height', 0.020);
        profile_length = get_param(params, 'length', 0.100);
        active = x >= 0 & x <= profile_length;
        phase = x(active)/profile_length;
        road_height(active) = 0.5*height*(1 - cos(2*pi*phase));
        info.description = sprintf('%.0f mm x %.0f mm sharp bump', ...
            1000*height, 1000*profile_length);

    case "pothole"
        depth = abs(get_param(params, 'depth', 0.030));
        profile_length = get_param(params, 'length', 0.400);
        active = x >= 0 & x <= profile_length;
        phase = x(active)/profile_length;
        road_height(active) = -0.5*depth*(1 - cos(2*pi*phase));
        info.description = sprintf('%.0f mm x %.0f mm pothole', ...
            1000*depth, 1000*profile_length);

    case "washboard"
        amplitude = get_param(params, 'amplitude', 0.005);
        wavelength = get_param(params, 'wavelength', 0.500);
        profile_length = get_param(params, 'length', 5.000);
        active = x >= 0 & x <= profile_length;
        road_height(active) = amplitude*sin(2*pi*x(active)/wavelength);
        info.description = sprintf('%.1f mm washboard, %.2f m wavelength', ...
            1000*amplitude, wavelength);

    case "rough"
        target_rms = get_param(params, 'rms_height', 0.003);
        profile_length = get_param(params, 'length', 10.000);
        seed = get_param(params, 'seed', 42);
        dx = get_param(params, 'spatial_step', 0.005);
        ramp_length = get_param(params, 'ramp_length', 0.500);

        % A fixed seed makes damping-setting comparisons repeatable.  The
        % harmonic construction is band-limited, so the tire is not driven
        % by nonphysical point-to-point white-noise discontinuities.
        previous_rng = rng;
        restore_rng = onCleanup(@() rng(previous_rng));
        rng(seed, 'twister');
        x_grid = (0:dx:profile_length).';
        spatial_frequencies = logspace(log10(0.15), log10(8), 60);
        phases = 2*pi*rand(size(spatial_frequencies));
        rough_grid = zeros(size(x_grid));

        for frequency_index = 1:numel(spatial_frequencies)
            frequency = spatial_frequencies(frequency_index);
            amplitude_weight = (frequency/spatial_frequencies(1))^(-1);
            rough_grid = rough_grid + amplitude_weight*cos( ...
                2*pi*frequency*x_grid + phases(frequency_index));
        end

        rough_grid = rough_grid - mean(rough_grid);
        rough_rms = sqrt(mean(rough_grid.^2));
        if rough_rms > 0
            rough_grid = target_rms*rough_grid/rough_rms;
        end

        % Fade both ends of the finite segment to avoid artificial steps.
        if ramp_length > 0
            ramp_in = min(x_grid/ramp_length, 1);
            ramp_out = min((profile_length - x_grid)/ramp_length, 1);
            envelope_in = 0.5*(1 - cos(pi*ramp_in));
            envelope_out = 0.5*(1 - cos(pi*ramp_out));
            rough_grid = rough_grid.*min(envelope_in, envelope_out);
        end

        active = x >= 0 & x <= profile_length;
        road_height(active) = interp1(x_grid, rough_grid, x(active), ...
            'linear', 0);
        info.description = sprintf('Random rough road, %.1f mm RMS', ...
            1000*target_rms);

    case "flat"
        profile_length = 0;
        info.description = "Flat road";

    otherwise
        error('generate_road_profile:UnknownProfile', ...
            'Unknown road profile type: %s', profile_type);
end

validateattributes(profile_length, {'double'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'}, mfilename, 'profile length');

info.length = profile_length;
info.end_time = start_time + profile_length/vehicle_speed;
road_height = reshape(road_height, t_shape);
info.distance = reshape(info.distance, t_shape);
end

function value = get_param(params, name, default_value)
%GET_PARAM Return a profile parameter or its documented default.
if isfield(params, name)
    value = params.(name);
else
    value = default_value;
end
end
