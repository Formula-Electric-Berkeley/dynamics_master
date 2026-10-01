function response = simulate_quarter_car_response(t_vec, road_input, ...
    corner, damper_velocity, damper_force, options)
%SIMULATE_QUARTER_CAR_RESPONSE Solve one motion-ratio-aware quarter car.
%   The tire is unilateral: it transmits compression only and its normal
%   load is exactly zero while the model predicts loss of contact.

arguments
    t_vec double
    road_input double
    corner struct
    damper_velocity double
    damper_force double
    options.RelTol (1,1) double = 1e-6
    options.AbsTol (1,1) double = 1e-8
    options.MaxStep (1,1) double = 0.0005
end

t_vec = t_vec(:);
road_input = road_input(:);
damper_velocity = damper_velocity(:);
damper_force = damper_force(:);

validateattributes(road_input, {'double'}, {'size', size(t_vec)});
initial_state = zeros(4, 1);
solver_options = odeset('RelTol', options.RelTol, ...
    'AbsTol', options.AbsTol, 'MaxStep', options.MaxStep);

[t_sol, state] = ode45(@rhs, t_vec, initial_state, solver_options);
road_at_solution = interp1(t_vec, road_input, t_sol, 'linear', 0);

x1 = state(:, 1);
x1_velocity = state(:, 2);
x2 = state(:, 3);
x2_velocity = state(:, 4);

shaft_velocity = corner.motion_ratio*(x2_velocity - x1_velocity);
shaft_velocity = min(max(shaft_velocity, damper_velocity(1)), ...
    damper_velocity(end));
shaft_force = interp1(damper_velocity, damper_force, ...
    shaft_velocity, 'linear');
wheel_damper_force = corner.motion_ratio*shaft_force;
spring_force_on_body = -corner.wheel_rate*(x1 - x2);

linear_tire_load = corner.static_tire_load + ...
    corner.tire_rate*(road_at_solution - x2);
tire_load = max(0, linear_tire_load);
dynamic_tire_force = tire_load - corner.static_tire_load;
body_acceleration = (spring_force_on_body + wheel_damper_force) ...
    / corner.sprung_mass;

response = struct( ...
    't', t_sol, ...
    'state', state, ...
    'road', road_at_solution, ...
    'x1', x1, ...
    'x1_velocity', x1_velocity, ...
    'x2', x2, ...
    'x2_velocity', x2_velocity, ...
    'suspension_travel', x1 - x2, ...
    'shaft_velocity', shaft_velocity, ...
    'shaft_force', shaft_force, ...
    'wheel_damper_force', wheel_damper_force, ...
    'body_acceleration', body_acceleration, ...
    'dynamic_tire_load', dynamic_tire_force, ...
    'static_tire_load', corner.static_tire_load, ...
    'tire_load', tire_load, ...
    'contact_lost', linear_tire_load <= 0);

    function derivative = rhs(t, current_state)
        road = interp1(t_vec, road_input, t, 'linear', 0);
        x1_now = current_state(1);
        x1_velocity_now = current_state(2);
        x2_now = current_state(3);
        x2_velocity_now = current_state(4);

        shaft_velocity_now = corner.motion_ratio* ...
            (x2_velocity_now - x1_velocity_now);
        shaft_velocity_now = min(max(shaft_velocity_now, ...
            damper_velocity(1)), damper_velocity(end));
        shaft_force_now = interp1(damper_velocity, damper_force, ...
            shaft_velocity_now, 'linear');
        damper_force_on_body = corner.motion_ratio*shaft_force_now;
        spring_force_now = -corner.wheel_rate*(x1_now - x2_now);

        normal_load = max(0, corner.static_tire_load + ...
            corner.tire_rate*(road - x2_now));
        tire_dynamic_force = normal_load - corner.static_tire_load;

        x1_acceleration = (spring_force_now + damper_force_on_body) ...
            / corner.sprung_mass;
        x2_acceleration = (-spring_force_now - damper_force_on_body + ...
            tire_dynamic_force)/corner.unsprung_mass;

        derivative = [x1_velocity_now; x1_acceleration; ...
                      x2_velocity_now; x2_acceleration];
    end
end
