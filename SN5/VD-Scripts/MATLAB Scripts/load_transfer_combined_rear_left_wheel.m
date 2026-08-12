%% Vehicle parameters
m_total   = 306.988;        % total mass with driver [kg]
m_unsF    = 22.36;         % unsprung mass front [kg]
m_unsR    = 20.76;         % unsprung mass rear [kg]
tF        = 1.23;        % front track [m]
tR        = 1.23;        % rear track [m]
h_CG      = 0.279;       % CG height [m]
z_unsF    = 0.20;       % front unsprung CG height [m]
z_unsR    = 0.20;       % rear unsprung CG height [m]
L         = 1.55;        % wheelbase [m]
a         = 0.72075;        % CG to front axle [m]
b         = L - a;      % CG to rear axle [m]
KphiF     = 450;        % front roll stiffness [Nm/deg] (convert below)
KphiR     = 500;        % rear roll stiffness [Nm/deg]
KphiF     = KphiF * (pi/180);  % -> [Nm/rad]
KphiR     = KphiR * (pi/180);

g = 9.81;               % gravity [m/s^2]

% Derived
m_sprung = m_total - (m_unsF + m_unsR);
mass_frac_F = b / L;
mass_frac_R = a / L;
fF = KphiF / (KphiF + KphiR);
fR = 1 - fF;

% Acceleration grid
ay = linspace(-2, 2, 50) * g;
ax = linspace(-2, 2, 50) * g;
[AY, AX] = meshgrid(ay, ax);

% === Load transfer calculations ===
% Lateral load transfer (algebraic)
dF_lat_F = (m_sprung * h_CG / tF) * fF .* AY;   % +ay → load to right
dF_lat_R = (m_sprung * h_CG / tR) * fR .* AY;   % +ay → load to right

% Unsprung lateral contribution
dF_lat_uns_F = (m_unsF * h_CG / tF) .* AY;
dF_lat_uns_R = (m_unsR * h_CG / tR) .* AY;

% Total lateral transfer
dF_lat_F = dF_lat_F + dF_lat_uns_F;
dF_lat_R = dF_lat_R + dF_lat_uns_R;

% Longitudinal transfer (algebraic)
dF_long = (m_total * h_CG / L) .* AX;           % +ax → load to rear

% Static wheel loads
Fz_static_F = mass_frac_F * m_total * g / 2;
Fz_static_R = mass_frac_R * m_total * g / 2;
Fz0=Fz_static_F;

% === Front-left wheel load ===
Fz_RL = Fz_static_R ...
       - 0.5 * dF_lat_R ...   % loses load in left turn (ay>0)
       + 0.5 * dF_long;       % loses load in acceleration (ax>0)


%% === Graphing ===
% Requires: ay, ax, Fz_FL, Fz0 (Fz0 = static front-left normal, e.g. Fz_static_F)

figure('Units','normalized','Position',[0.1 0.1 0.6 0.55]);
hAx = axes();

% Plot heatmap
imagesc(ay/g, ax/g, Fz_RL, 'Parent', hAx);
set(hAx, 'YDir', 'normal');
xlabel(hAx, 'Lateral Accel [g]');
ylabel(hAx, 'Longitudinal Accel [g]');
title(hAx, 'Rear-Left Wheel Normal Load [N]');

% Create red-white-blue colormap (white = static)
n = 256;
cmap1 = [linspace(0,1,n/2)' linspace(0,1,n/2)' ones(n/2,1)]; % blue->white
cmap2 = [ones(n/2,1) linspace(1,0,n/2)' linspace(1,0,n/2)']; % white->red
colormap(hAx, [cmap1; cmap2]);

% Center white at static normal load
delta = max(abs(Fz_RL(:) - Fz0));
if delta == 0, delta = 1; end
clim(hAx, [Fz0 - delta, Fz0 + delta]);

% Add colorbar to the east outside and adjust axes so colorbar is visible
cb = colorbar(hAx, 'eastoutside');
ylabel(cb, 'Normal Load [N]');

% Preserve and adjust positions to ensure colorbar is not clipped
axPos = hAx.Position;    % [left bottom width height]
cbPos = cb.Position;     % after creation
pad = 0.01;              % small gap
newWidth = axPos(3) - cbPos(3) - pad;
if newWidth < 0.1
    newWidth = axPos(3) * 0.85;
end
hAx.Position = [axPos(1), axPos(2), newWidth, axPos(4)];
cb.Position = [axPos(1) + newWidth + pad, axPos(2), cbPos(3), axPos(4)];

axis tight;
