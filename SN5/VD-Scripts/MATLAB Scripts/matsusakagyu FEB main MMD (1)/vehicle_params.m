function p = vehicle_params()
% Vehicle geometry (edit to your car)
p.m  = 307;          % vehicle mass with driver, kg
p.lf = 1.55 * 0.465;         % CG to front axle distance, m
p.lr = 1.55 - p.lf;         % CG to rear axle distance, m   (L = lf+lr = 1.55 m)
p.tfw = 1.208;        % m   front track
p.trw = 1.208;        % m   rear track
p.hCG = 0.279;        % m   CG height
p.Iz  = 500;         % kg·m^2 (not used in steady-state MMD calc)

% Roll stiffness distribution (for lateral load transfer split)
p.kphi_f = 21231.090;     % N·m/rad
p.kphi_r = 18056.990;     % N·m/rad

% Static verticals
p.g  = 9.81;
p.Wf = p.m * p.g * (p.lr/(p.lf+p.lr));
p.Wr = p.m * p.g * (p.lf/(p.lf+p.lr));

% Numerics
p.maxIter = 60;
p.tol     = 1e-6;

% Speed placeholder (set in main)
p.Ux = 11;           % m/s (overwritten in main but use only for overlay_MMD_sweep.m)

end
