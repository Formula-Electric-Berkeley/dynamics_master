function [Fyf, Fyr, nearCap] = solve_point(p, beta, delta)
% Steady-state at constant Ux.
% Unknowns: ay (=> k = ay/Ux^2). Iterate so that ay = sum(Fy)/m.
% Includes lateral load transfer with roll distribution (zetaF, zetaR).
% Smooth tire cap: Fy = mu*Fz*tanh(Ca*alpha/(mu*Fz)) per tire.

Ux = max(0.1, p.Ux);        % protect divide-by-zero
ay = 0;                     % initial guess
k  = 0;                     % curvature = r/Ux
nearCap = false;

% Static per-tire loads
FzF_stat = p.Wf/2;  FzR_stat = p.Wr/2;

for it = 1:6
    % curvature from previous ay
    k = ay / (Ux^2);

    % Slip angles (small-angle approx)
    alpha_f = delta - beta - p.lf * k;   % axle average
    alpha_r =      - beta + p.lr * k;

    % Lateral forces need vertical loads -> include LLT with roll
    M_lat  = p.m * ay * p.hcg;          % total roll moment
    M_f    = p.zetaF * M_lat;
    M_r    = p.zetaR * M_lat;

    dFzF_ax = M_f / p.tf;               % left-right difference (axle)
    dFzR_ax = M_r / p.tr;

    % Per tire Fz (inside/right convention irrelevant for axle sum)
    Fz_fl = FzF_stat + 0.5*dFzF_ax;   Fz_fr = FzF_stat - 0.5*dFzF_ax;
    Fz_rl = FzR_stat + 0.5*dFzR_ax;   Fz_rr = FzR_stat - 0.5*dFzR_ax;

    % Cornering stiffness scaling with load
    Ca_fl = p.Ca_ref * (Fz_fl/p.Fz_ref)^p.nLS;
    Ca_fr = p.Ca_ref * (Fz_fr/p.Fz_ref)^p.nLS;
    Ca_rl = p.Ca_ref * (Fz_rl/p.Fz_ref)^p.nLS;
    Ca_rr = p.Ca_ref * (Fz_rr/p.Fz_ref)^p.nLS;

    % Per-tire forces with smooth cap (tanh)
    Fy_fl = tire_y_smooth(Ca_fl, alpha_f, p.mu, Fz_fl);
    Fy_fr = tire_y_smooth(Ca_fr, alpha_f, p.mu, Fz_fr);
    Fy_rl = tire_y_smooth(Ca_rl, alpha_r, p.mu, Fz_rl);
    Fy_rr = tire_y_smooth(Ca_rr, alpha_r, p.mu, Fz_rr);

    % Axle sums
    Fyf = Fy_fl + Fy_fr;
    Fyr = Fy_rl + Fy_rr;

    % Update ay
    ay_new = (Fyf + Fyr)/p.m;

    % Convergence
    if abs(ay_new - ay) < 1e-3
        ay = ay_new; break;
    end
    ay = 0.5*ay + 0.5*ay_new;   % relaxed update
end

% "Near cap" flag if any tire >98% of mu*Fz
capRatios = [abs(Fy_fl)/(p.mu*max(Fz_fl,1)), ...
             abs(Fy_fr)/(p.mu*max(Fz_fr,1)), ...
             abs(Fy_rl)/(p.mu*max(Fz_rl,1)), ...
             abs(Fy_rr)/(p.mu*max(Fz_rr,1))];
nearCap = any(capRatios > 0.98);
end
