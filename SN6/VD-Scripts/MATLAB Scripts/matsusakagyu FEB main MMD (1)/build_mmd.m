function [Ay, N, CN, beta_grid, delta_grid, Ay_g] = build_mmd(p, beta_vec, delta_vec, kappa_f, kappa_r)
nb = numel(beta_vec); nd = numel(delta_vec);
Ay = nan(nb, nd);
N  = nan(nb, nd);
CN = nan(nb, nd);

[beta_grid, delta_grid] = ndgrid(beta_vec, delta_vec);

for ib = 1:nb
    beta = beta_vec(ib);
    for jd = 1:nd
        delta = delta_vec(jd);
        % solve this operating point
        [Ay_ij, N_ij] = solve_point_2(p, beta, delta, kappa_f, kappa_r);
        Ay(ib,jd) = Ay_ij;
        N(ib,jd)  = N_ij;
    
        L = p.lf + p.lr;           % wheelbase (for CN scaling)
        CN(ib,jd)   = N_ij / (p.m * p.g * L);
        Ay_g(ib,jd) = Ay_ij / p.g; % lateral g's
    end
end
end
