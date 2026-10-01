function quarter_car_gui()
%QUARTER_CAR_GUI  Quarter-car ride dynamics simulator with nonlinear damper.
%
%   Interactive uifigure GUI featuring:
%     - Three road profiles : single bump, sine wave, ISO 8608-C Gaussian
%     - Asymmetric damper   : independent Soft / Medium / Hard for
%                             compression and rebound strokes
%     - Four live plots     : road input, body & wheel displacement,
%                             suspension travel, tyre contact force
%
%   Requires MATLAB R2019b or later.

%% ── Vehicle parameters ───────────────────────────────────────────────────
m1 = 141.885 / 2;   % sprung mass        [kg]
m2 =  22.36  / 2;   % unsprung mass      [kg]
k  = 35683.525;     % suspension rate    [N/m]
kt = 101573.528;    % tyre spring rate   [N/m]  (note: N/m, not kN/m)

%% ── Base damper look-up table (SI units throughout) ─────────────────────
%   Row 1 – force  (N)     negative = compression stroke
%   Row 2 – velocity (m/s) negative = compression stroke
vel_si = [-0.250 -0.225 -0.200 -0.175 -0.150 -0.125 -0.100 ...
          -0.075 -0.050 -0.025  0.000  0.025  0.050  0.075 ...
           0.100  0.125  0.150  0.175  0.200  0.225  0.250];

force_base = [-725 -700 -675 -650 -625 -600 -575 -525 -475 -400 ...
                 0  400  475  525  575  600  625  650  675  700  725];

%% ── Damping scale factors (Soft / Medium / Hard) ─────────────────────────
D = struct('Soft', 0.45, 'Medium', 1.0, 'Hard', 1.80);

%% ── Simulation time axis ─────────────────────────────────────────────────
dt    = 0.001;       % time step  [s]
tmax  = 5.0;         % end time   [s]
t_vec = 0 : dt : tmax;

%% ── GUI colour palette ───────────────────────────────────────────────────
BG_FIG  = [0.10 0.10 0.12];
BG_CTRL = [0.14 0.14 0.18];
BG_AX   = [0.08 0.08 0.10];
TC      = [0.82 0.82 0.86];   % axis tick / label colour
GC      = [0.20 0.20 0.25];   % grid colour

% Series colours
C_ROAD  = [0.40 0.90 0.55];
C_BODY  = [0.30 0.72 0.96];
C_WHEEL = [0.96 0.50 0.28];
C_SUSP  = [0.82 0.55 0.97];
C_TYRE  = [0.97 0.84 0.28];

%% ══════════════════════════════════════════════════════════════════════════
%%  FIGURE
%% ══════════════════════════════════════════════════════════════════════════
FW = 1300; FH = 760; CW = 245;

fig = uifigure('Name','Quarter-Car Simulator', ...
               'Position', [50 50 FW FH], ...
               'Color', BG_FIG, ...
               'Resize', 'off');

cp = uipanel(fig, 'Position', [0 0 CW FH], ...
             'BackgroundColor', BG_CTRL, 'BorderType', 'none');
pp = uipanel(fig, 'Position', [CW 0 FW-CW FH], ...
             'BackgroundColor', BG_AX,  'BorderType', 'none');

%% ── Control panel ────────────────────────────────────────────────────────

% App header
y = FH - 50;
uilabel(cp, 'Text', 'QUARTER-CAR SIMULATOR', ...
        'Position', [0 y CW 24], ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'FontColor', [0.88 0.88 0.93]);
y = y - 36;

% ── Road profile ──────────────────────────────────────────────────────────
sec_label('ROAD PROFILE', y); y = y - 17;
bg_road = rbgroup(y-60);
make_rb(bg_road, 'Single bump',            6, 40, true);
make_rb(bg_road, 'Sine wave',              6, 22, false);
make_rb(bg_road, 'Gaussian  (ISO 8608-C)', 6,  4, false);
y = y - 80;

% ── Compression damping ───────────────────────────────────────────────────
sec_label('COMPRESSION DAMPING', y); y = y - 17;
bg_comp = rbgroup(y-60);
make_rb(bg_comp, 'Soft',   6, 40, false);
make_rb(bg_comp, 'Medium', 6, 22, true);
make_rb(bg_comp, 'Hard',   6,  4, false);
y = y - 80;

% ── Rebound damping ───────────────────────────────────────────────────────
sec_label('REBOUND DAMPING', y); y = y - 17;
bg_reb = rbgroup(y-60);
make_rb(bg_reb, 'Soft',   6, 40, false);
make_rb(bg_reb, 'Medium', 6, 22, true);
make_rb(bg_reb, 'Hard',   6,  4, false);
y = y - 80;

% ── Damper curve legend ───────────────────────────────────────────────────
sec_label('DAMPER CURVE', y); y = y - 17;
ax_damp = uiaxes(cp, 'Position', [14 y-110 CW-28 108]);
ax_damp.Color = [0.10 0.10 0.13];
ax_damp.XColor = TC; ax_damp.YColor = TC;
ax_damp.GridColor = GC; ax_damp.GridAlpha = 0.35;
ax_damp.XGrid = 'on'; ax_damp.YGrid = 'on';
ax_damp.FontSize = 7; ax_damp.Box = 'off'; ax_damp.TickDir = 'out';
ax_damp.XLim = [-0.26 0.26];
plot(ax_damp, vel_si, force_base, 'Color', [0.60 0.60 0.65], 'LineWidth', 1.2);
hold(ax_damp, 'on');
h_comp_line = plot(ax_damp, vel_si(vel_si < 0), force_base(vel_si < 0), ...
                   'Color', C_BODY, 'LineWidth', 2.0);
h_reb_line  = plot(ax_damp, vel_si(vel_si >= 0), force_base(vel_si >= 0), ...
                   'Color', C_WHEEL, 'LineWidth', 2.0);
plot(ax_damp, [0 0], [-800 800], '--', 'Color', GC, 'LineWidth', 0.6);
plot(ax_damp, [-0.26 0.26], [0 0], '--', 'Color', GC, 'LineWidth', 0.6);
xlabel(ax_damp, 'Velocity (m/s)', 'Color', TC, 'FontSize', 7);
ylabel(ax_damp, 'Force (N)',      'Color', TC, 'FontSize', 7);
legend(ax_damp, 'Baseline', 'Compression', 'Rebound', ...
       'TextColor', TC, 'Color', [0.10 0.10 0.13], 'EdgeColor', GC, ...
       'FontSize', 6, 'Location', 'northwest');
y = y - 126;

% ── Vehicle parameters ────────────────────────────────────────────────────
sec_label('VEHICLE PARAMETERS', y); y = y - 17;
pstr = { sprintf('Sprung mass    %5.1f kg',  m1), ...
         sprintf('Unsprung mass  %5.1f kg',  m2), ...
         sprintf('Spring rate  %7.0f N/m',   k),  ...
         sprintf('Tyre rate    %7.0f N/m',   kt)  };
for ii = 1:4
    uilabel(cp, 'Text', pstr{ii}, ...
            'Position', [14 y-ii*17 CW-14 14], ...
            'FontSize', 8, 'FontName', 'Courier New', ...
            'FontColor', [0.50 0.50 0.58]);
end
y = y - 80;

% ── Run button ────────────────────────────────────────────────────────────
btn = uibutton(cp, 'Text', '▶   RUN SIMULATION', ...
    'Position', [14 56 CW-28 46], ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'FontColor', [0.05 0.05 0.08], ...
    'BackgroundColor', [0.28 0.72 0.96], ...
    'ButtonPushedFcn', @run_sim);

status = uilabel(cp, 'Text', 'Ready — select options and press Run', ...
    'Position', [0 14 CW 20], ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 8, 'FontColor', [0.46 0.46 0.55]);

%% ── 2 × 2 plot axes ──────────────────────────────────────────────────────
PW = FW - CW;
ml = 70; mr = 18; mt = 44; mb = 54; gx = 64; gy = 50;
aw = (PW - ml - mr - gx) / 2;
ah = (FH - mt - mb - gy) / 2;

axpos = { [ml,         mb+ah+gy,  aw, ah]; ...   % TL – road profile
          [ml+aw+gx,   mb+ah+gy,  aw, ah]; ...   % TR – displacements
          [ml,         mb,        aw, ah]; ...   % BL – suspension travel
          [ml+aw+gx,   mb,        aw, ah] };     % BR – tyre force

ATitles = { 'Road Profile', ...
            'Body & Wheel Displacement', ...
            'Suspension Travel', ...
            'Tyre Contact Force' };
AYLabels = { 'Displacement (mm)', ...
             'Displacement (mm)', ...
             'Travel (mm)', ...
             'Force (N)' };

AX = gobjects(1, 4);
for ii = 1:4
    AX(ii) = uiaxes(pp, 'Position', axpos{ii});
    init_ax(AX(ii), ATitles{ii}, AYLabels{ii});
end

%% ══════════════════════════════════════════════════════════════════════════
%%  RUN CALLBACK
%% ══════════════════════════════════════════════════════════════════════════
    function run_sim(~, ~)
        btn.Enable  = 'off';
        status.Text = 'Solving…';
        drawnow;

        % ── Read GUI state ────────────────────────────────────────────────
        road_str = bg_road.SelectedObject.Text;
        comp_str = bg_comp.SelectedObject.Text;
        reb_str  = bg_reb.SelectedObject.Text;
        sc = D.(comp_str);
        sr = D.(reb_str);

        % ── Build road profile ────────────────────────────────────────────
        switch road_str
            case 'Single bump'
                xt = road_bump(t_vec);
            case 'Sine wave'
                xt = road_sine(t_vec);
            otherwise
                xt = road_gauss(t_vec);
        end

        % ── Asymmetric damper table ───────────────────────────────────────
        fs = force_base;
        fs(vel_si <  0) = sc * force_base(vel_si <  0);   % compression
        fs(vel_si >= 0) = sr * force_base(vel_si >= 0);   % rebound
        c_tab = [fs; vel_si];

        % Update damper curve preview
        h_comp_line.YData = fs(vel_si < 0);
        h_reb_line.YData  = fs(vel_si >= 0);

        % ── Integrate ─────────────────────────────────────────────────────
        X0   = zeros(4, 1);
        opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-9, 'MaxStep', dt);
        [ts, Xs] = ode45( ...
            @(t, X) qcar_ode(t, X, m1, m2, k, kt, c_tab, t_vec, xt), ...
            t_vec, X0, opts);

        x1  = Xs(:, 1);
        x2  = Xs(:, 3);
        xts = interp1(t_vec, xt, ts, 'linear', 0);

        % ── Derived channels ──────────────────────────────────────────────
        susp   = (x1 - x2) * 1e3;                           % mm
        Fstat  = (m1 + m2) * 9.81;                          % N
        Ftyre  = kt * (x2 - xts) + Fstat;                   % N

        % ── Plot 1 – road profile ─────────────────────────────────────────
        cla(AX(1));
        shade(AX(1), ts, xts*1e3, C_ROAD*0.35);
        plot(AX(1), ts, xts*1e3, 'Color', C_ROAD, 'LineWidth', 1.8);
        fmt_ax(AX(1), ATitles{1}, AYLabels{1});

        % ── Plot 2 – body & wheel displacement ───────────────────────────
        cla(AX(2));
        shade(AX(2), ts, x1*1e3, C_BODY*0.30);
        plot(AX(2), ts, x1*1e3,  'Color', C_BODY,  'LineWidth', 1.8);
        plot(AX(2), ts, x2*1e3,  'Color', C_WHEEL, 'LineWidth', 1.2);
        plot(AX(2), ts, xts*1e3, '--', 'Color', C_ROAD, 'LineWidth', 0.9);
        legend(AX(2), 'Body (m_1)', 'Wheel (m_2)', 'Road', ...
               'TextColor', TC, 'Color', BG_AX, 'EdgeColor', GC, ...
               'FontSize', 8, 'Location', 'best');
        fmt_ax(AX(2), ATitles{2}, AYLabels{2});

        % ── Plot 3 – suspension travel ────────────────────────────────────
        cla(AX(3));
        shade(AX(3), ts, susp, C_SUSP*0.25);
        plot(AX(3), ts, susp, 'Color', C_SUSP, 'LineWidth', 1.6);
        plot(AX(3), [0 tmax], [0 0], '--', 'Color', GC, 'LineWidth', 0.8);
        fmt_ax(AX(3), ATitles{3}, AYLabels{3});

        % ── Plot 4 – tyre contact force ────────────────────────────────────
        cla(AX(4));
        shade(AX(4), ts, Ftyre, C_TYRE*0.22);
        plot(AX(4), ts, Ftyre, 'Color', C_TYRE, 'LineWidth', 1.6);
        plot(AX(4), [0 tmax], [Fstat Fstat], '--', ...
             'Color', [0.55 0.55 0.60], 'LineWidth', 0.8);
        text(AX(4), tmax*0.02, Fstat, '  static load', ...
             'Color', [0.55 0.55 0.60], 'FontSize', 7, 'VerticalAlignment', 'bottom');
        fmt_ax(AX(4), ATitles{4}, AYLabels{4});

        status.Text = sprintf('✓  %s  |  Comp: %s  |  Reb: %s', ...
                              road_str, comp_str, reb_str);
        btn.Enable = 'on';
    end

%% ══════════════════════════════════════════════════════════════════════════
%%  QUARTER-CAR ODE  (corrected equations of motion)
%%
%%   m1·ẍ1 = -k(x1-x2) - Fc(ẋ1-ẋ2)
%%   m2·ẍ2 =  k(x1-x2) + Fc(ẋ1-ẋ2) - kt(x2-xt)
%% ══════════════════════════════════════════════════════════════════════════
    function dX = qcar_ode(t, X, m1, m2, k, kt, c_tab, tv, xv)
        xt  = interp1(tv, xv, t, 'linear', 0);
        vr  = X(2) - X(4);   % relative velocity (sprung − unsprung)
        Fc  = interp1(c_tab(2,:), c_tab(1,:), vr, 'linear', 'extrap');
        dX  = [ X(2);
               (-k*(X(1)-X(3)) - Fc) / m1;
                X(4);
               ( k*(X(1)-X(3)) + Fc - kt*(X(3)-xt)) / m2 ];
    end

%% ══════════════════════════════════════════════════════════════════════════
%%  ROAD PROFILES
%% ══════════════════════════════════════════════════════════════════════════

    % ── Single half-sine bump ─────────────────────────────────────────────
    function y = road_bump(tv)
        h  = 0.060;   % bump height  [m]  (60 mm)
        t0 = 0.50;    % onset time   [s]
        Tb = 0.07;    % duration     [s]  (~1.4 m at 72 km/h)
        y  = h * sin(pi*(tv - t0) / Tb) .* (tv >= t0 & tv < t0 + Tb);
    end

    % ── Steady-state sinusoidal road ──────────────────────────────────────
    function y = road_sine(tv)
        A = 0.012;   % amplitude [m]  (12 mm)
        f = 2.5;     % frequency [Hz] (~50 m wavelength at 72 km/h)
        y = A * sin(2*pi*f*tv);
    end

    % ── ISO 8608 Class C stochastic road (superposed sinusoids) ──────────
    function y = road_gauss(tv)
        rng(0);                              % repeatable seed
        v_veh = 20;                          % vehicle speed [m/s]

        % Spatial frequency grid (cycle/m)
        n_spat = logspace(log10(0.05), log10(10), 600);
        dn     = [diff(n_spat), n_spat(end) - n_spat(end-1)];

        % ISO 8608 Class C one-sided PSD:  Gq(n) = Gq0*(n/n0)^(-w)
        Gq0 = 256e-6;   n0 = 0.1;   w = 2;
        Gq  = Gq0 * (n_spat / n0).^(-w);       % [m^2 / (cycle/m)]

        % Amplitude spectrum and random phases
        amp_spat = sqrt(2 * Gq .* dn);          % [m]
        phi      = 2 * pi * rand(1, 600);

        % Convert to temporal frequencies and build time-domain profile
        f_temp = n_spat * v_veh;                % [Hz]
        y = sum(amp_spat' .* sin(2*pi*f_temp' .* tv + phi'), 1);

        % Normalise to 15 mm RMS (typical Class C)
        y = y * (0.015 / std(y));
    end

%% ══════════════════════════════════════════════════════════════════════════
%%  GUI / PLOT HELPERS
%% ══════════════════════════════════════════════════════════════════════════

    % Translucent fill between signal and zero baseline
    function shade(ax, tv, yv, fc)
        patch(ax, [tv(:); flipud(tv(:))], [yv(:); zeros(numel(yv), 1)], ...
              fc, 'FaceAlpha', 0.30, 'EdgeColor', 'none');
        hold(ax, 'on');
    end

    % Apply dark-theme styling to a uiaxes
    function init_ax(ax, ttl, ylbl)
        ax.Color          = BG_AX;
        ax.XColor         = TC;
        ax.YColor         = TC;
        ax.GridColor      = GC;
        ax.MinorGridColor = GC;
        ax.XGrid          = 'on';
        ax.YGrid          = 'on';
        ax.GridAlpha      = 0.35;
        ax.Box            = 'off';
        ax.FontSize       = 8;
        ax.TickDir        = 'out';
        ax.XLim           = [0 tmax];
        title( ax, ttl,          'Color', TC, 'FontSize', 10, 'FontWeight', 'bold');
        xlabel(ax, 'Time (s)',   'Color', TC, 'FontSize', 8);
        ylabel(ax, ylbl,         'Color', TC, 'FontSize', 8);
    end

    % Re-apply styling after hold(off) at end of each plot block
    function fmt_ax(ax, ttl, ylbl)
        hold(ax, 'off');
        init_ax(ax, ttl, ylbl);
    end

    % Coloured section header on control panel
    function sec_label(txt, yp)
        uilabel(cp, 'Text', txt, 'Position', [14 yp CW-14 15], ...
                'FontSize', 8, 'FontWeight', 'bold', ...
                'FontColor', [0.38 0.68 1.00]);
    end

    % Create a uibuttongroup on the control panel
    function bg = rbgroup(yp)
        bg = uibuttongroup(cp, 'Position', [14 yp CW-28 62], ...
                           'BackgroundColor', BG_CTRL, 'BorderType', 'none');
    end

    % Add a radio button to a button group
    % Note: BackgroundColor is not supported for uiradiobutton in uifigure —
    % the button inherits its parent uibuttongroup background automatically.
    function make_rb(bg, txt, xp, yp, val)
        uiradiobutton(bg, 'Text', txt, 'Position', [xp yp 200 16], ...
                      'FontColor', [0.82 0.82 0.86], ...
                      'Value', val);
    end

end