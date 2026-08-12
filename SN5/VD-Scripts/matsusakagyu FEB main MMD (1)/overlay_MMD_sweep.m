function overlay_MMD_sweep(ratio, L_ref)
% Overlay raw MMD envelopes sweeping the geometry ratio (L/t) at fixed L_ref.

p0  = vehicle_params();
L   = L_ref;

figure('Color','w'); hold on; grid on; box on;
xlabel('a_y  [m/s^2]'); ylabel('C_{N}  [N·m]');
title(sprintf('MMD Envelopes (raw), L fixed at %.2f m; varying L/t', L_ref));

for rho = ratio(:).'
    t   = L / rho;           % track from desired L/t
    lf  = p0.lf;  lr = p0.lr;

    p = p0; p.L = L; p.lf = lf; p.lr = lr;
    if isfield(p,'tf'),  p.tf  = t; else, p.tfw = t; end
    if isfield(p,'tr'),  p.tr  = t; else, p.trw = t; end

    beta_vec  = deg2rad(linspace(-10, 10, 61));   % [rad]
    delta_vec = deg2rad(linspace(-10, 10, 81));   % [rad]
    [Ay, N]   = build_mmd(p, beta_vec, delta_vec, 0, 0);

    K = convhull(Ay(:), N(:));
    plot(Ay(K), N(K), 'LineWidth', 1.8, 'DisplayName', sprintf('L/t = %.2f', rho));
end

legend('Location','best'); axis tight; axis square;
end
