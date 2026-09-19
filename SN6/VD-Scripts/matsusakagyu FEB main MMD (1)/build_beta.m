function [Nmax_beta, Nmin_beta] = build_beta(Nsurf, beta_grid, delta_grid)
% For each beta, find max/min N across all delta
betas = unique(beta_grid(:));
Nmax_beta = zeros(size(betas));
Nmin_beta = zeros(size(betas));

for i = 1:numel(betas)
    mask = abs(beta_grid - betas(i)) < 1e-12;
    Ni   = Nsurf(mask);
    Nmax_beta(i) = max(Ni);
    Nmin_beta(i) = min(Ni);
end
end