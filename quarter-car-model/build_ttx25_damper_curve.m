function [velocity_mps, force_n] = build_ttx25_damper_curve(matrix_file, settings)
%BUILD_TTX25_DAMPER_CURVE Build an asymmetric physical damper curve.
%   Positive shaft velocity and force are compression. Negative shaft
%   velocity and force are rebound. Settings must contain ls_rebound,
%   hs_rebound, ls_compression, and hs_compression.

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
