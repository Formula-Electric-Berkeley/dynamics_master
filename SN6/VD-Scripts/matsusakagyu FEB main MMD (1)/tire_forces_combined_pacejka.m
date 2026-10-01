function [Fy, Fx] = tire_forces_combined_pacejka(p, Fz, alpha, kappa)
% Combined slip tire using Magic Formula (Pacejka) for both Fy and Fx
% 1) Compute pure-slip forces Fy0(alpha, Fz), Fx0(kappa, Fz)
% 2) Apply a friction-ellipse style reduction to couple them

% --- PURE LATERAL (Magic Formula) ---
Fy0 = pacejka_magic(alpha, Fz, p.pacejka_lat);

% --- PURE LONGITUDINAL (Magic Formula) ---
Fx0 = pacejka_magic(kappa, Fz, p.pacejka_long);  % same MF form, slip var = kappa

% --- COMBINED-SLIP REDUCTION (ellipse-style) ---
muFz = p.mu * max(Fz, 1);                 % guard against tiny Fz
util = min(1.0, abs(Fx0)/muFz);           % longitudinal usage 0..1
Gy   = sqrt(max(0, 1 - util.^2));         % lateral gain left
Fy   = Gy .* Fy0;
Fx   = Fx0;                                % keep Fx0 (you can also reduce Fx by Fy if desired)
end

% ---------- Magic Formula core (lateral or longitudinal) ----------
function F = pacejka_magic(slip, Fz, P)
% P must contain fields: B, C, D, E
% D is scaled by Fz (peak ~ proportional to load)
B = P.B; C = P.C; D = P.D * Fz; E = P.E;
F = D .* sin( C .* atan( B.*slip - E.*(B.*slip - atan(B.*slip)) ) );
end

