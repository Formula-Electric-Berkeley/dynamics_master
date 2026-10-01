% inputs

m1 = 141.885/2;  % sprung mass, kg
m2 =  22.36/2;  % unsprung mass, kg 
k = 35683.525;  % spring rate, N/m
kt = 101573.528;  % tire spring rate, N/m
c = [-725  -700   -675   -650   -625   -600   -575   -525  -475  -400 0 400 475  525  575   600   625   650   675   700   725
     -250  -225   -200   -175   -150   -125   -100   -75   -50   -25  0 25  50   75   100   125   150   175   200   225   250;];  % Damping force (N, row 1) vs velocity (mm/s, row 2)

vel_mm = c(2,:);      % mm/s
force_N = c(1,:);    % lb

vel_si = vel_mm / 1000;  % m/s
force_si = force_N;   % N

c_table = [force_si; vel_si];

h = 0.03; % 30 mm bump

dt = 0.001;  % time step, s
tmax = 20;  % max time, s
tdist = 1;  % disturbance time, s

%F-k(x1-x2)-c(x1'-x2')=m1x1"

%-F+k(x1-x2)+c(x1'-x2')-kt(x2-xt(t))=m2x2"

%m1x1"+c(x1'-x2')+k(x1-x2)=F
%m2x2"-k(x1-x2)-c(x1'-x2')+ktx2=-F+ktxt

%[m1 0; 0 m2]*[x1"; x2"] + [c -c; -c c]*[x1'; x2'] + [k -k; -k k+kt]*[x1; x2] = [1 0; 1 kt]

function dXdt = quarter_car(t, X, m1, m2, k, kt, c_table, t_vec, xt_vec)

x1 = X(1);
x1_dot = X(2);
x2 = X(3);
x2_dot = X(4);

% interpolate road input
xt = interp1(t_vec, xt_vec, t, 'linear', 0);

% relative velocity
v_rel = x1_dot - x2_dot;

% damper force (nonlinear)
c_force = interp1(c_table(2,:), c_table(1,:), v_rel, 'linear', 'extrap');

% equations of motion
x1_ddot = (-k*(x1 - x2) - c_force) / m1;
x2_ddot = ( k*(x1 - x2) + c_force - kt*(x2 - xt) ) / m2;

dXdt = [x1_dot;
        x1_ddot;
        x2_dot;
        x2_ddot];
end

X0 = [0; 0; 0; 0];

t_vec = 0:dt:tmax;

xt = h * (t_vec > tdist);

opts = odeset('RelTol',1e-6,'AbsTol',1e-8);

[t_sol, X_sol] = ode45(@(t,X) quarter_car(t, X, m1, m2, k, kt, c_table, t_vec, xt), t_vec, X0, opts);

x1 = X_sol(:,1);  % sprung displacement
x2 = X_sol(:,3);  % unsprung displacement

plot(t_sol, x1, t_sol, x2)
legend('Sprung','Unsprung')