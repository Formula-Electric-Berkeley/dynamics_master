% inputs

% FRONT axle only - compute rear separately

m1 = 141.885/2;  % sprung mass, kg
m2 =  22.36/2;  % unsprung mass, kg 
k = 35683.525;  % spring rate, N/m
kt = 101573.528;  % tire spring rate, N/m

vel_mm = linspace(-250,250,21);      % mm/s
xq=linspace(min(vel_mm),max(vel_mm),501);

c_ls2raw = [-667.732  -642.798  -619.507  -594.575  -566.361  -516.819  -463.994  -381.632  -297.640  -144.732    0.000   144.732   297.640   381.632   463.994   516.819   566.361   594.575   619.507   642.798   667.732];  % setting 2-4.3

c_ls2smooth = spline(vel_mm,c_ls2raw,xq);

c_ls4raw = [-628.1030532	-595.4551874	-559.5975595	-526.9460254	-494.3018279	-429.3435798	-367.6171037	-260.6458212	-169.8333981	-66.09388742	0	66.09388742	169.8333981	260.6458212	367.6171037	429.3435798	494.3018279	526.9460254	559.5975595	595.4551874	628.1030532];  % Setting 4-4.3

c_ls4smooth = spline(vel_mm,c_ls4raw,xq);

c_ls6raw = [-567.654  -523.030  -476.767  -430.508  -380.966  -310.093  -237.580  -161.787   -90.914   -41.372  -1.608   41.372    90.914   161.787   237.580   310.093   380.966   430.508   476.767   523.030   567.654];  % setting 6-4.3

c_ls6smooth = spline(vel_mm,c_ls6raw,xq);

c_ls10raw = [-441.322  -383.573  -329.109  -274.646  -221.819  -173.920  -127.655   -87.957   -49.897   -21.682    0    21.682    49.897    87.957   127.655   173.920   221.819   274.646   329.109   383.573   441.322];  % setting 10-4.3

c_ls10smooth = spline(vel_mm,c_ls10raw,xq);

c_ls15raw = [-296.943 -253.960 -215.905 -171.283 -133.225 -103.367 -75.155 -53.503 -33.491 -21.682 0.000 21.682 33.491 53.503 75.155 103.367 133.225 171.283 215.905 253.960 296.943];  % setting 15-4.3

c_ls15smooth = spline(vel_mm,c_ls15raw,xq);

c_design = [-447.297 -412.890 -378.482 -344.075 -309.667 -275.260 -240.852 -206.445 -137.630 -68.815 0.000 30.584 61.169 91.753	107.046	122.338	137.630	152.922	168.214	183.507	198.799];  % designed baseline damping curve

c_designsmooth = spline(vel_mm,c_design,xq);
 

force_N = zeros(size(xq));
force_N(xq <  0) = c_ls6smooth(xq <  0);   % rebound side from ls6
force_N(xq >= 0) = c_ls15smooth(xq >= 0);  % compression side from ls15

vel_si = xq / 1000;  % m/s
force_si = force_N;   % N

c_crit = 2*sqrt(k*m1) * vel_si;   % always positive, symmetric

c_table = [force_si; vel_si];

h = 0.03; % 30 mm bump

dt = 0.001;  % time step, s
tmax = 20;  % max time, s
tdist = 6;  % disturbance time, s

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

damping_ratio_actual = force_si./c_crit;

damping_ratio_design = c_designsmooth./c_crit;

figure
plot(t_sol, x1, 'LineWidth', 1.5)
hold on
plot(t_sol, x2, 'LineWidth', 1.5)
legend('Sprung','Unsprung')
xlabel('Time (s)', 'FontSize', 14)
ylabel('Displacement (m)', 'FontSize', 14)
title('Displacement from Bump Disturbance', 'FontSize', 20)
grid on

figure
plot(xq, damping_ratio_actual, 'Linewidth', 2)
xlabel('Velocity (mm/s)', 'FontSize', 14)
ylabel('Damping Ratio', 'FontSize', 14)
title('Damping Ratio vs. Velocity, Front', 'FontSize', 20)
grid on
ylim([0 1])

figure
plot(xq, damping_ratio_design, 'LineWidth', 1.5) 
hold on
plot(xq, damping_ratio_actual, 'LineWidth', 1.5)
xlabel('Velocity (mm/s)', 'FontSize', 14)
ylabel('Damping Ratio', 'FontSize', 14)
title('Damping Ratio vs. Velocity', 'FontSize', 20)
grid on
ylim([0 1])
xlim([-250 250])
legend('Designed', 'Actual', 'Location','bestoutside')

figure
plot(xq, c_designsmooth, xq, force_si)
legend('Desired', 'Actual')
xlabel('Velocity (mm/s)')
ylabel('Force, N')
title('Desired vs Actual Damping Curve')
grid on

