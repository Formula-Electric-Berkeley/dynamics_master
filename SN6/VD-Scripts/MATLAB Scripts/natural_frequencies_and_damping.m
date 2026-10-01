% Inputs
A_1 = 20;      % front initial displacement (mm)
zeta_1 = .7; % front damping ratio (ζ)
f_1 = 2.5;     % front natural frequency (Hz)
phi_1 = 0;     % front phase (rad)

A_2 = 20;      % rear initial displacement (mm)
zeta_2 = .7; % rear damping ratio (ζ)
f_2 = 2.75;    % rear natural frequency (Hz)
phi_2 = 0;     % rear phase (rad)

wb = 1.550;    % wheelbase (m)
vel = 15;      % velocity (m/s)

t_front_delay = 0.1;   % delay before front hits bump (s)

% Derived
t_delay = wb / vel;     % delay between front and rear (s)
t = linspace(0, 1, 500);  % time vector

% Convert to angular frequencies
wn1 = 2*pi*f_1;
wn2 = 2*pi*f_2;

% Damped frequencies
wd1 = wn1 * sqrt(max(0, 1 - zeta_1^2));
wd2 = wn2 * sqrt(max(0, 1 - zeta_2^2));

% Front displacement: zero before t_front_delay
disp_F = zeros(size(t));
front_after = t >= t_front_delay;
tau_F = t(front_after) - t_front_delay;
disp_F(front_after) = A_1 .* exp(-zeta_1*wn1 .* tau_F) .* cos(wd1 .* tau_F + phi_1);

% Rear displacement: zero before t_front_delay + t_delay
disp_R = zeros(size(t));
rear_after = t >= (t_front_delay + t_delay);
tau_R = t(rear_after) - (t_front_delay + t_delay);
disp_R(rear_after) = A_2 .* exp(-zeta_2*wn2 .* tau_R) .* cos(wd2 .* tau_R + phi_2);

% Plot
figure;
plot(t, disp_F, 'b', 'LineWidth', 2);
hold on;
plot(t, disp_R, 'r', 'LineWidth', 2);
xline(t_front_delay, ':k', 'Front hits bump');
xline(t_front_delay + t_delay, ':k', 'Rear hits bump');
xlabel('Time (s)');
ylabel('Displacement (mm)');
title('Front and Rear Wheel Bump Displacement vs Time');
legend('Front','Rear');
grid on;
