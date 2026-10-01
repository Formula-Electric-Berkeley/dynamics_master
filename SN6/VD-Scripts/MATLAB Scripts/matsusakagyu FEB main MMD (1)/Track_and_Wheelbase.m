%% Assumptions and Notes
% Gift from DUO
% This helps understand the effects of track width and wheelbase by plotting the Milliken Diagram (Yaw-Moment)
% Two variants will be used.
% Variant 1: Open‑loop chassis property (δ = 0): “What yaw moment does the tire system produce at a given ay if the wheels are held straight?”
% Variant 2: Ackermann (δ = L/R): “What residual yaw moment remains if you steer just the geometric amount?”
% This model uses a simple 4 wheel model that takes into account load transfer.
% This model assumes parallel steer ie front slip angles are the same.
% This model assumes linear, load sensitive tires. I acknowledge 
% This model assumes constant speed
clc; close all; clear;

%% --- Vehicle / tire params (baseline) ---
p.m      = 307;          % kg
p.g      = 9.81;         % m/s^2
p.Ux     = 15;           % m/s (constant speed)
p.L      = 1.55;         % m wheelbase
p.lf     = 0.72075;         % m CG->front axle (a)
p.lr     = p.L - p.lf;   % m CG->rear  axle (b)
p.tf     = 1.208;         % m front track
p.tr     = 1.208;         % m rear  track
p.hcg    = 0.279;         % m CG height

% Tire model (cornering stiffness scaling + smooth cap)
p.mu     = 1.0;         % -
p.Ca_ref = 4.0e4;        % N/rad @ Fz_ref (per tire)
p.Fz_ref = 1750;         % N
p.nLS    = 0.90;         % load-sensitivity exponent

% Roll stiffness split (zeta)
p.Kf     = 700;         % N*m/rad  (== 4.5 kN·m/rad)
p.Kr     = 700;         % N*m/rad
p.zetaF  = p.Kf/(p.Kf+p.Kr);  % roll moment distribution front
p.zetaR  = 1 - p.zetaF;

% Static axle loads
p.Wf = (p.lr/p.L)*p.m*p.g;  % N
p.Wr = (p.lf/p.L)*p.m*p.g;  % N

%% --- Sweep definitions (moderate to avoid immediate saturation) ---
beta_vec  = deg2rad(linspace(-6, 6, 19));   % sideslip sweep
delta_vec = deg2rad(linspace(-10,10,25));   % steer sweep

%% --- Build one diamond (baseline) ---
%%{
[Fyf_n, Fyr_n, capFlag] = build_diamond(p, beta_vec, delta_vec);

figure('Color','w'); hold on; axis equal; box on;
scatter(Fyf_n(~capFlag), Fyr_n(~capFlag), 10, [0.2 0.5 0.9], 'filled',...
        'DisplayName','Sub-limit');
scatter(Fyf_n( capFlag),  Fyr_n( capFlag),  10, [0.85 0.2 0.2], 'filled',...
        'DisplayName','Near cap');
% Convex hull outline (the “diamond”)
%K = convhull(Fyf_n, Fyr_n);
%plot(Fyf_n(K), Fyr_n(K), 'k-', 'LineWidth', 1.8, 'DisplayName','Envelope');

xlabel('F_{y,f} / (\mu W_f)');
ylabel('F_{y,r} / (\mu W_r)');
title('Milliken Handling Diagram (baseline)');
legend('Location','southeast');
xlim([-1.1, 1.1]); ylim([-1.1, 1.1]);
%%}

%% --- (Optional) Sweep geometry ratios: track and wheelbase ---
%{
KEEP_T_OVER_L = true;                 % set false to keep absolute tracks
t_over_L0 = p.tf/p.L;                 % keep t/L constant if true
wb_scale_vec = [0.85 0.95 1.00 1.05 1.15];

cols = lines(numel(wb_scale_vec));
figure('Color','w'); hold on; axis equal; box on;
for i = 1:numel(wb_scale_vec)
    rhoL = wb_scale_vec(i);
    pp = p;
    % scale wheelbase, keep a/L
    aFrac = p.lf/p.L;
    pp.L  = rhoL*p.L;  pp.lf = aFrac*pp.L;  pp.lr = pp.L - pp.lf;

    if KEEP_T_OVER_L
        pp.tf = t_over_L0*pp.L;  pp.tr = t_over_L0*pp.L;
        lbl = sprintf('L/L_0 = %.2f (t/L const)', rhoL);
    else
        pp.tf = p.tf;  pp.tr = p.tr;
        lbl = sprintf('L/L_0 = %.2f (t const)', rhoL);
    end

    % update statics
    pp.Wf = (pp.lr/pp.L)*pp.m*pp.g;
    pp.Wr = (pp.lf/pp.L)*pp.m*pp.g;

    [FyfN, FyrN] = build_diamond(pp, beta_vec, delta_vec);   % ignore cap flag
    K = convhull(FyfN, FyrN);
    plot(FyfN(K), FyrN(K), '-', 'Color', cols(i,:), 'LineWidth', 1.8, ...
        'DisplayName', lbl);
end
%xlabel('F_{y,f} / (\mu W_f)'); ylabel('F_{y,r} / (\mu W_r)');
xlabel('F_{y,f}'); ylabel('F_{y,r}');
title('MHD: sweep of wheelbase scale'); legend('Location','southeast');
%}