function Fy = pacejka_tire(alpha, Fz, pacejka)
% pacejka_tire - computes lateral tire force using Magic Formula
%
% Inputs:
%   alpha   - slip angle [rad]
%   Fz      - vertical load on tire [N]
%   pacejka - struct with coefficients {B,C,D,E.F}
%
% Output:
%   Fy      - lateral force [N]

pacejka.B = -0.34876850845497015 + -0.00034276883261057686 * Fz + -1.3247032127260662e-07 * (Fz.^2); % stiffness factor
pacejka.C = 0.5509222176106313 + -0.002443688073927094 * Fz + -1.2320536839299613e-06 * (Fz.^2); % shape factor
pacejka.D = 338.39870577325456 + -1.9769442425898722 * Fz; % peak factor (multiplies Fz inside MF)
pacejka.E = 0.3553895949382016 + 31.244897244705058 * exp(0.016405921135532898 * Fz); % curvature factor
pacejka.F = -0.0233809460004577 + -0.00017739222796836902 * Fz + -1.2122598706268264e-07 * (Fz.^2);

% Unpack parameters
B = pacejka.B; 
C = pacejka.C; 
D = pacejka.D;    
E = pacejka.E;
F = pacejka.F;

%slip angle in degrees
x=rad2deg(alpha);

% Magic Formula
term1 = E .* (B .* x - atan(B .* x)) - B .* x;
term2 = E .* (B - B ./ ((B.^2) .* (x.^2) + 1)) - B;
    
Fy = -(C .* D .* term2 .* cos(C .* atan(term1) - F)) ./ (term1.^2 + 1);

end
