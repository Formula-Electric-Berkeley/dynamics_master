% Inputs

Mz = 100;  % Peak aligning torque of tire, Nm

Ro_tr = 0.0127;  % Outer diameter of tie rod tube, M
Ri_tr_vals = [0.009, 0.00955, 0.010];  % Inner diameters of tie rod tube, M
L_tr = 0.5;  % Nominal length of tie rod, M

b_vals = [0.004, 0.005, 0.006];  % Thicknesses of upright tie rod attach, M
h = 0.016;  % Height of one 'beam' of upright tie rod attach, M
L_ur = 0.033682;  % Nominal length of upright tie rod attach 'beam,' M

Ro_c = 0.028575;  % Outer diameter of chassis tube, M
Ri_c = 0.0260858;  % Inner diameter of chassis tube, M
L_c = 0.2461;  % Node-to-node length of chassis tube, M
a = 0.037;  % Distance from node where tie rod force applied, M

e_4130 = 205e9;  % Modulus of elasticity for 4130 steel, Pa
e_6061 = 68.9e9;  % Modulus of elasticity for 6061-T6 aluminum, Pa

play = 0.00005;  % Axial play in rod end, M
toe_base_nom = 0.050909;  % Nominal toe base, M
toe_base = linspace(0.050909, 0.15, 100);  % Toe base range, M

% Calculation
F_Tr = Mz ./ toe_base;  % Tie rod axial reaction force

figure; hold on;

for i = 1:length(Ri_tr_vals)
    Ri_tr = Ri_tr_vals(i);

    for j = 1:length(b_vals)
        b = b_vals(j);

        delta_play = 2 * play;  % Play from two rod ends

        % Deflections
        delta_tr = (F_Tr * L_tr) ./ (pi * (Ro_tr^2 - Ri_tr^2) * e_4130 .* toe_base);
        delta_ur = ((F_Tr / 2) .* (L_ur + (toe_base - toe_base_nom)).^3) ./ ...
                   (3 * e_6061 * ((b * h^3) / 12));
        delta_c = (F_Tr .* a^2 .* (L_c - a)^2) ./ ...
                  (3 * e_4130 * (pi / 2) * (Ro_c^4 - Ri_c^4) * L_c);

        % Total angular compliance
        theta = (180 / pi) * asin((delta_play + delta_tr + delta_ur + delta_c) ./ toe_base);

        % Plot
        plot(toe_base, theta, 'DisplayName', ...
            sprintf('Ri_{tr}=%.4f m, b=%.3f m', Ri_tr, b));

        [min_theta, idx_min] = min(theta);
        toe_min = toe_base(idx_min);
        plot(toe_min, min_theta, 'ko', 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
        text(toe_min, min_theta, sprintf(' %.3f m', toe_min), ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
    end
end

% Labels
title('Rear Toe Compliance at 100 Nm Torque vs Rear Toe Base');
xlabel('Rear Toe Base (m)');
ylabel('Rear Toe Compliance (deg)');
legend('Location', 'best');
grid on;
