function Fz_RL = normal_load(ay_g, ax_g)
% Computes front-left wheel normal load [N]
% Inputs: ay_g, ax_g in g-units (e.g., ay_g = 1 → 1g lateral accel)

% === Vehicle parameters ===
m_total   = 306.988;   
m_unsF    = 22.36;     
m_unsR    = 20.76;     
tF        = 1.23;      
tR        = 1.23;      
h_CG      = 0.279;     
L         = 1.55;      
a         = 0.72075;   
b         = L - a;     
KphiF     = 450 * (pi/180);  
KphiR     = 500 * (pi/180);  
g         = 9.81;      

% === Convert to m/s² ===
ay = ay_g * g;
ax = ax_g * g;

% === Derived ===
m_sprung = m_total - (m_unsF + m_unsR);
mass_frac_R = a / L;
fR = KphiR / (KphiF + KphiR);

% === Lateral load transfer ===
dF_lat_F = (m_sprung * h_CG / tF) * fR * ay;
dF_lat_uns_F = (m_unsF * h_CG / tF) * ay;
dF_lat_F = dF_lat_F + dF_lat_uns_F;

% === Longitudinal load transfer ===
dF_long = (m_total * h_CG / L) * ax;

% === Static load ===
Fz_static_F = mass_frac_R * m_total * g / 2;

% === Front-left load ===
Fz_RL = Fz_static_F - 0.5*dF_lat_F + 0.5*dF_long;

end

Fz_RL = normal_load(-2,-2)