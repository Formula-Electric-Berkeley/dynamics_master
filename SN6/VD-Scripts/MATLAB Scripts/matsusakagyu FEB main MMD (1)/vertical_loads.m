function [Fz_fl, Fz_fr, Fz_rl, Fz_rr] = vertical_loads(p, Ay, kappa_vec)
% Lateral load transfer via roll moment split (zeta)
Kf = p.kphi_f; Kr = p.kphi_r; zeta = Kf/(Kf+Kr);

M_lat = p.m * Ay * p.hCG;              % lateral load transfer moment
dFz_f =  zeta    * M_lat / p.tfw;      % front axle lateral transfer (left +d, right -d)
dFz_r = (1-zeta) * M_lat / p.trw;      % rear  axle lateral transfer

% Static
Fz_f0 = p.Wf/2;
Fz_r0 = p.Wr/2;

% Optional: simple longitudinal transfer from net Fx (front+rear).
% Here we approximate Fx_sum using friction ellipse usage (very mild if kappas=0)
Fx_sum = 0; %#ok<NASGU> % retained for future extension if you want pitch transfer

% Compose loads per wheel
Fz_fl = -(Fz_f0 + dFz_f);
Fz_fr = -(Fz_f0 - dFz_f);
Fz_rl = -(Fz_r0 + dFz_r);
Fz_rr = -(Fz_r0 - dFz_r);

% Floor at small positive to avoid numerical issues
epsN = 50; 
Fz_fl = -(max(-Fz_fl, epsN));
Fz_fr = -(max(-Fz_fr, epsN));
Fz_rl = -(max(-Fz_rl, epsN));
Fz_rr = -(max(-Fz_rr, epsN));
end
