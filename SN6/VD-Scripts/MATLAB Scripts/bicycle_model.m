%% Nonlinear Bicycle Model with Load Transfer
% Steady-state cornering solve
% Slip angles in degrees
% Yaw rate in rad/s
% Loads in Newtons

clear; clc;

%% ---------------- VEHICLE PARAMETERS ----------------

p.m     = 300;      % mass (kg)
p.a     = 0.9;      % CG to front axle (m)
p.b     = 0.7;      % CG to rear axle (m)
p.hcg   = 0.28;     % CG height (m)
p.tf    = 1.2;      % front track (m)
p.tr    = 1.2;      % rear track (m)

p.U     = 15;       % speed (m/s)
p.delta = 5;        % steer angle (deg)

p.g = 9.81;

%% ---------------- SOLVER ----------------

x0 = [2; p.U/(p.a+p.b)];   % initial guess [beta_deg ; r]

options = optimoptions('fsolve',...
    'Display','iter',...
    'TolFun',1e-8,...
    'TolX',1e-8);

sol = fsolve(@(x) residuals(x,p), x0, options);

beta = sol(1);
r    = sol(2);
ay   = p.U*r;

fprintf('\n---- SOLUTION ----\n');
fprintf('Beta        = %.4f deg\n', beta);
fprintf('Yaw rate    = %.4f rad/s\n', r);
fprintf('Lat accel   = %.4f m/s^2\n', ay);
fprintf('Lat accel   = %.3f g\n\n', ay/p.g);


%% ================= RESIDUAL FUNCTION =================
function R = residuals(x,p)

beta = x(1);   % deg
r    = x(2);   % rad/s

%% --- Slip Angles (degrees) ---
alpha_f = p.delta - atan2d( ...
    p.U*sind(beta) + p.a*r, ...
    p.U*cosd(beta) );

alpha_r = -atan2d( ...
    p.U*sind(beta) - p.b*r, ...
    p.U*cosd(beta) );

%% --- Static Normal Loads ---
Fzf_static = p.m*p.g * p.b/(p.a+p.b);
Fzr_static = p.m*p.g * p.a/(p.a+p.b);

%% --- Lateral Acceleration ---
ay = p.U*r;

%% --- Lateral Load Transfer ---
dFzf = p.m * ay * p.hcg * p.b / ...
       ((p.a+p.b) * p.tf);

dFzr = p.m * ay * p.hcg * p.a / ...
       ((p.a+p.b) * p.tr);

% Wheel loads
Fz_fl = Fzf_static - dFzf;
Fz_fr = Fzf_static + dFzf;
Fz_rl = Fzr_static - dFzr;
Fz_rr = Fzr_static + dFzr;

% Prevent negative loads
Fz_fl = max(Fz_fl, 0);
Fz_fr = max(Fz_fr, 0);
Fz_rl = max(Fz_rl, 0);
Fz_rr = max(Fz_rr, 0);

%% --- Tire Forces ---
Fy_f = tireModel(alpha_f, Fz_fl) + ...
       tireModel(alpha_f, Fz_fr);

Fy_r = tireModel(alpha_r, Fz_rl) + ...
       tireModel(alpha_r, Fz_rr);

%% --- Force Balance ---
R(1) = p.m*p.U*r - (Fy_f + Fy_r);

%% --- Moment Balance ---
R(2) = p.a*Fy_f - p.b*Fy_r;

end


%% ================= TIRE MODEL =================
function Fy = tireModel(alpha_deg, Fz)

Fy = (338.398705773254 + -1.97694424258987 * Fz) .* ...
sin( ...
 (0.550922217610631 + -0.00244368807392709 * Fz + ...
  -0.00000123205368392996 .* Fz.^2) .* ...
 atan( ...
  (-0.34876850845497 + -0.000342768832610576 * Fz + ...
   -0.000000132470321272606 .* Fz.^2) .* alpha_deg ...
  - ...
  (0.355389594938201 + ...
   31.244897244705 .* exp(0.0164059211355328 .* Fz)) .* ...
  ( ...
   (-0.34876850845497 + -0.000342768832610576 * Fz + ...
    -0.000000132470321272606 .* Fz.^2) .* alpha_deg ...
   - ...
   atan((-0.34876850845497 + ...
         -0.000342768832610576 * Fz + ...
         -0.000000132470321272606 .* Fz.^2) .* alpha_deg) ...
  ) ...
 ) ...
 + ...
 (-0.0233809460004577 + ...
  -0.000177392227968369 * Fz + ...
  -0.000000121225987062682 .* Fz.^2) ...
);

end