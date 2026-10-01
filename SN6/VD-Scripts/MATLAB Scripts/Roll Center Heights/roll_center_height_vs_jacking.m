% Inputs
ay_g = 1.5;          % lateral acceleration [g]
track = 1.23;         % track width [m]
mass_total = 307;    % total vehicle mass [kg]
weight_frac = 0.53;  % axle weight fraction (e.g. front = 0.53)

% Constants
g = 9.81;
ay = ay_g * g;

% Axle mass and lateral force per outside wheel
mass_axle = mass_total * weight_frac;
F_lat_wheel = 0.5 * mass_axle * ay;

% Swingarm horizontal projection (half track)
L_swingarm = track / 2;

% Roll center height sweep
h_RC = linspace(-0.05, 0.10, 200);

% Jacking force
Fj = F_lat_wheel .* (h_RC ./ L_swingarm);

% Plot
figure;
plot(h_RC * 1000, Fj, 'LineWidth', 2);
xlabel('Roll Center Height [mm]');
ylabel('Jacking Force [N]');
title(sprintf('Jacking Force vs Roll Center Height (%.2g g lateral)', ay_g));
grid on;