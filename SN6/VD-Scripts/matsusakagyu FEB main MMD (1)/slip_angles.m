function [a_fl, a_fr, a_rl, a_rr] = slip_angles(p, vy, Ux, r, delta)
% Paper uses arctan forms; we keep that for fidelity.
% Front left
a_fl = delta - atan2( (vy + r*p.lf - r*p.tfw/2), Ux );
% Front right
a_fr = delta - atan2( (vy + r*p.lf + r*p.tfw/2), Ux );
% Rear left
a_rl =      - atan2( (vy - r*p.lr - r*p.trw/2), Ux );
% Rear right
a_rr =      - atan2( (vy - r*p.lr + r*p.trw/2), Ux );
end
