clc; clear; close all

%% Inputs
mass = 307; % kg
g = 9.81; % m/s^2
track_f = 1.23; % m
track_r = 1.23; % m
h_CG = 0.279; % m
L = 1.55; % m wheelbase
Wf_static = 0.535; % static front weight distribution
ay = 1.5 * g; % peak lateral acceleration

LLTD_vals = 0.3:0.01:0.7; % fraction of total LLT on front axle

%% Derived
W_total = mass * g;
Wf = W_total * Wf_static;
Wr = W_total - Wf;

%% Preallocate
Fz_FL = zeros(size(LLTD_vals));
Fz_FR = zeros(size(LLTD_vals));
Fz_RL = zeros(size(LLTD_vals));
Fz_RR = zeros(size(LLTD_vals));
K_understeer = zeros(size(LLTD_vals));

for i = 1:length(LLTD_vals)
    LLTD = LLTD_vals(i);

    % Total lateral load transfer
    LLT_total = mass * ay * h_CG / (track_f/2 + track_r/2);

    % Split LLT between front and rear
    LLT_front = LLT_total * LLTD;
    LLT_rear = LLT_total * (1 - LLTD);

    % Split left/right
    dFz_front = LLT_front / 2;
    dFz_rear = LLT_rear / 2;

    % Static loads per wheel
    Fz_FL(i) = Wf/2 + dFz_front;
    Fz_FR(i) = Wf/2 - dFz_front;
    Fz_RL(i) = Wr/2 + dFz_rear;
    Fz_RR(i) = Wr/2 - dFz_rear;

    % Understeer gradient approximation (°/g)
    % Assume front/rear cornering stiffness proportional to vertical load
    Cf = (Fz_FL(i) + Fz_FR(i)) / (2 * 1000); % N/deg scaling
    Cr = (Fz_RL(i) + Fz_RR(i)) / (2 * 1000);
    K_understeer(i) = (Wf_static/Cf - (1 - Wf_static)/Cr) * 57.3; % deg/g
end

%% Plot normal loads vs LLTD
figure
plot(LLTD_vals, Fz_FL, 'b', 'DisplayName', 'Front Left'); hold on
plot(LLTD_vals, Fz_FR, 'r', 'DisplayName', 'Front Right')
plot(LLTD_vals, Fz_RL, 'm', 'DisplayName', 'Rear Left')
plot(LLTD_vals, Fz_RR, 'Color', [0.8 0.5 0], 'DisplayName', 'Rear Right')
xlabel('LLTD')
ylabel('Tire Normal Forces (N)')
legend
grid on
title('Tire Normal Loads vs LLTD')
