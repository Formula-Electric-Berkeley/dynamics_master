function [Ay, N] = solve_point_2(p, beta, delta, kappa_f, kappa_r)
Ux = p.Ux;
vy = Ux * tan(beta);    % sideslip definition: beta = atan(vy/Ux)

% Fixed-point solve for yaw rate r from steady-state lateral DOF
r = 0;              % initial guess
for k = 1:p.maxIter
    % Slips from kinematics (Eqs. 5-8 in paper)
    [alpha_fl, alpha_fr, alpha_rl, alpha_rr] = slip_angles(p, vy, Ux, r, delta);

    % Current Ay = Ux*r (since vy_dot=0)
    Ay_k = Ux * r;

    % Vertical loads with lateral (and optional longitudinal) transfer
    % Fx assumed from kappas -> influences long. weight transfer if desired
    kappa = [kappa_f, kappa_f, kappa_r, kappa_r]; % [fl fr rl rr]
    [Fz_fl, Fz_fr, Fz_rl, Fz_rr] = vertical_loads(p, Ay_k, kappa);

    % Tire forces (combined slip saturation)
    [Fy_fl, Fx_fl] = tire_forces_combined_pacejka(p, Fz_fl, alpha_fl, kappa_f);
    [Fy_fr, Fx_fr] = tire_forces_combined_pacejka(p, Fz_fr, alpha_fr, kappa_f);
    [Fy_rl, Fx_rl] = tire_forces_combined_pacejka(p, Fz_rl, alpha_rl, kappa_r);
    [Fy_rr, Fx_rr] = tire_forces_combined_pacejka(p, Fz_rr, alpha_rr, kappa_r);

    % Sum lateral force per axle (front multiplied by cos(delta))
    Fyf = (Fy_fl + Fy_fr) * cos(delta);
    Fyr =  (Fy_rl + Fy_rr);

    Fy_sum = Fyf + Fyr;

    % Fixed-point update from steady-state lateral DOF: m Ux r = sum Fy
    r_new = Fy_sum / (p.m * Ux);

    if abs(r_new - r) < p.tol
        r = r_new;
        break;
    end
    r = 0.7*r + 0.3*r_new; % relaxation for robustness
end

% Final outputs
Ay = Ux * r;
% Available yaw moment about CG (do NOT enforce Eq. 4 = 0; we want N available)
N  =  p.lf * (Fy_fl + Fy_fr) * cos(delta) - p.lr * (Fy_rl + Fy_rr);
end
