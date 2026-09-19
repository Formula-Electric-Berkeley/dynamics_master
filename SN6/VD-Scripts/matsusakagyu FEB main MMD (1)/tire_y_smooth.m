function Fy = tire_y_smooth(Ca, alpha, mu, Fz)
% Smooth saturation: Fy = mu*Fz*tanh( (Ca*alpha)/(mu*Fz) )
% Robust to tiny Fz.
FzEff = max(Fz, 1);              % avoid division by ~0 in edge cases
Fy = mu*Fz * tanh( (Ca*alpha) / (mu*FzEff) );
end
