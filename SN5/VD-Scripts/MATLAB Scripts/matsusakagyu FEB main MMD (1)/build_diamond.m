%{
function [Fyf, Fyr, capFlag] = build_diamond(p, beta_vec, delta_vec)
% Generates raw front/rear axle forces for the Milliken diagram
% (no normalization). Returns Fyf, Fyr [N].

N = numel(beta_vec)*numel(delta_vec);
Fyf  = zeros(N,1);
Fyr  = zeros(N,1);
capFlag = false(N,1);

k = 1;
for ib = 1:numel(beta_vec)
    beta = beta_vec(ib);
    for id = 1:numel(delta_vec)
        delta = delta_vec(id);
        [Fyf_i, Fyr_i, onCap] = solve_point(p, beta, delta);
        Fyf(k) = Fyf_i;     % raw N
        Fyr(k) = Fyr_i;     % raw N
        capFlag(k) = onCap;
        k = k+1;
    end
end
end
%}
%Normalized plot

function [Fyf_n, Fyr_n, capFlag] = build_diamond(p, beta_vec, delta_vec)
% Generates the full point cloud for the Milliken diagram at constant Ux.
% Returns normalized axle forces and a boolean near-cap flag.

N = numel(beta_vec)*numel(delta_vec);
Fyf_n  = zeros(N,1);
Fyr_n  = zeros(N,1);
capFlag = false(N,1);

k = 1;
for ib = 1:numel(beta_vec)
    beta = beta_vec(ib);
    for id = 1:numel(delta_vec)
        delta = delta_vec(id);
        [Fyf, Fyr, onCap] = solve_point(p, beta, delta);
        Fyf_n(k) = Fyf / (p.mu*p.Wf);
        Fyr_n(k) = Fyr / (p.mu*p.Wr);
        capFlag(k) = onCap;
        k = k+1;
    end
end
end