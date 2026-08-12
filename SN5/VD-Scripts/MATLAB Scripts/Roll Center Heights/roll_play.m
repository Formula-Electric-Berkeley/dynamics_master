function varargout = roll_play(varargin)
% ROLL_PLAY M-file for roll_play.fig
%      ROLL_PLAY, by itself, creates a new ROLL_PLAY or raises the existing
%      singleton*.
%
%      H = ROLL_PLAY returns the handle to a new ROLL_PLAY or the handle to
%      the existing singleton*.
%
%      ROLL_PLAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROLL_PLAY.M with the given input arguments.
%
%      ROLL_PLAY('Property','Value',...) creates a new ROLL_PLAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roll_play_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roll_play_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help roll_play

% Last Modified by GUIDE v2.5 28-Mar-2019 21:13:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @roll_play_OpeningFcn, ...
                   'gui_OutputFcn',  @roll_play_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before roll_play is made visible.
function roll_play_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to roll_play (see VARARGIN)

% Choose default command line output for roll_play
handles.output = hObject;
handles.t     = [0:.01:2.5]; % Time base
handles.tmid  = 1.5; % Time when pseudo step is 50% in
handles.hw    = 1.5;   % width of the steer pulse (but we are only using part of it
handles.pwr   = 100;  % max steer velocity factor
handles.f=[.1:.1:18];

handles.swamp = 20;  % max steer angle deg
handles.steer =(-2./pi*atan(abs((handles.t-handles.tmid)./handles.hw).^handles.pwr)+1.).*handles.swamp; % steer input signal
handles.g     = 9.806;
handles.math  = 0;   % do all the computations and draw the plots

ws = str2num(get(handles.WS,'String'));
kt = str2num(get(handles.KT,'String'));
rch= str2num(get(handles.RCH,'String'));
hs = str2num(get(handles.HS,'String'));

rg = rollgain(ws,(hs-rch)/1000,kt);
set(handles.ROLL_GAIN,'String',num2str(round2(rg)));
% Update handles structure
guidata(hObject, handles);
clc
make_xfers(hObject);

% UIWAIT makes roll_play wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = roll_play_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function speed_slider_Callback(hObject, eventdata, handles)
set(handles.SPEED,'String',num2str(round(get(handles.speed_slider,'Value'))))
handles.math = 1;  % roll compuations only are needed.
make_xfers(hObject);


function speed_slider_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function DF_Callback(hObject, eventdata, handles)
handles.math = 1;  % roll compuations only are needed.
make_xfers(hObject);


function DF_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function DR_Callback(hObject, eventdata, handles)
handles.math = 1;  % roll compuations only are needed.
make_xfers(hObject);


function DR_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function WF_Callback(hObject, eventdata, handles)
handles.math = 1;  % roll compuations only are needed.
make_xfers(hObject);


function WF_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function WR_Callback(hObject, eventdata, handles)
handles.math = 1;  % roll compuations only are needed.
make_xfers(hObject);


function WR_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function L_Callback(hObject, eventdata, handles)
handles.math = 1;  % roll compuations only are needed.
make_xfers(hObject);


function L_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function SR_Callback(hObject, eventdata, handles)
handles.math = 1;  % roll compuations only are needed.
make_xfers(hObject);


function SR_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function SPEED_Callback(hObject, eventdata, handles)
set(handles.speed_slider,'Value',str2num(get(handles.SPEED,'String')))
handles.math = 1;  % roll computations only are needed.
make_xfers(hObject);

function SPEED_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function RCH_Callback(hObject, eventdata, handles)
set(handles.rch_slider,'Value',str2num(get(handles.RCH,'String')))
ws = str2num(get(handles.WS,'String'));
kt = str2num(get(handles.KT,'String'));
rch= str2num(get(handles.RCH,'String'));
hs = str2num(get(handles.HS,'String'));

rg = rollgain(ws,(hs-rch)/1000,kt);
set(handles.ROLL_GAIN,'String',num2str(round2(rg)))

handles.math = 2;  % roll compuations only are needed.
make_xfers(hObject);

function RCH_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ROLL_ZETA_Callback(hObject, eventdata, handles)
handles.math = 2;  % roll compuations only are needed.
make_xfers(hObject);

function ROLL_ZETA_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ROLL_GAIN_Callback(hObject, eventdata, handles)
ws = str2num(get(handles.WS,'String'));
rg = str2num(get(handles.ROLL_GAIN,'String'));
rch= str2num(get(handles.RCH,'String'));
hs = str2num(get(handles.HS,'String'));

kt = handles.g*ws*((hs-rch)/1000)/rg;
set(handles.KT,'String',num2str(round(kt)))
handles.math = 2;  % roll compuations only are needed.
make_xfers(hObject);


function ROLL_GAIN_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function IXXS_Callback(hObject, eventdata, handles)
handles.math = 2;  % roll computations only are needed.
make_xfers(hObject);


function IXXS_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ROLL_HZ_Callback(hObject, eventdata, handles)
handles.math = 2;  % roll computations only are needed.
make_xfers(hObject);


function ROLL_HZ_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function KT_Callback(hObject, eventdata, handles)
ws = str2num(get(handles.WS,'String'));
kt = str2num(get(handles.KT,'String'));
rch= str2num(get(handles.RCH,'String'));
hs = str2num(get(handles.HS,'String'));

rg = rollgain(ws,(hs-rch)/1000,kt);
set(handles.ROLL_GAIN,'String',num2str(round2(rg)))

handles.math = 2;  % roll computations only are needed.
make_xfers(hObject);


function KT_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function KP_Callback(hObject, eventdata, handles)
handles.math = 1;  % vehicle computations only are needed.
make_xfers(hObject);


function KP_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function WS_Callback(hObject, eventdata, handles)
ws = str2num(get(handles.WS,'String'));
kt = str2num(get(handles.KT,'String'));
rch= str2num(get(handles.RCH,'String'));
hs = str2num(get(handles.HS,'String'));

rg = rollgain(ws,(hs-rch)/1000,kt);
set(handles.ROLL_GAIN,'String',num2str(round2(rg)))
handles.math = 2;  % roll computations only are needed.
make_xfers(hObject);


function WS_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function HS_Callback(hObject, eventdata, handles)
ws = str2num(get(handles.WS,'String'));
kt = str2num(get(handles.KT,'String'));
rch= str2num(get(handles.RCH,'String'));
hs = str2num(get(handles.HS,'String'));

rg = rollgain(ws,(hs-rch)/1000,kt);
set(handles.ROLL_GAIN,'String',num2str(round2(rg)))
handles.math = 2;  % roll computations only are needed.
make_xfers(hObject);


function HS_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function x= make_xfers(hObject)
handles   = guidata(hObject); 

if ismember(handles.math,[0 1]) % initialization or vehicle transfer function chnage parameter change

    df      = str2double(get(handles.DF,'String'));
    dr      = str2double(get(handles.DR,'String'));
    
    set(handles.K,'String',num2str(df-dr))
    
    l       = str2double(get(handles.L,'String'));
    wf      = str2double(get(handles.WF,'String'));
    wr      = str2double(get(handles.WR,'String'));
    sr      = str2double(get(handles.SR,'String'));
    speed   = str2double(get(handles.SPEED,'String'));
    kp      = str2double(get(handles.KP,'String'));
    t       = [0:.01:1.5];

    wb   = l/1000 ;
    a    = wb*wr /(wf+wr);
    b    = wb-a;
    u    = speed*.2778;
    const= 9.806*180/pi;

    % YAW VELOCITY TRANSFER FUNCTION Numerator factors:
    r2=0.;
    r1=a*b*const*u  / (df*wb);
    r0=a*b*const^2 / (df*dr*wb);

    % sideslip numerator factors:
    b2=0.;
    b1=a*b^2*const / (df*wb*(kp+1));
    b0=a*b*const*wb*(b*const-dr*u^2)/(df*dr*wb^2*u);

    % lateral acceleration numerator factors:
    a2=a*b^2*const*u / (df*wb*(kp+1));
    a1=a*b^2*const^2 / (df*dr*wb);
    a0=a*b*const^2*u / (df*dr*wb);

    % common denominator factors:
    d2=a*b*u / (kp+1);
    d1=a*b*const*(a*(df+dr*(kp+1))+b*(df*(kp+1)+dr))/(df*dr*wb*(kp+1));
    d0=a*b*const*(const*wb+u^2*(df-dr)) / (df*dr*u*wb);
    % inputs to transfer functions are radians of steer.
    % output of Ay is m/sec^2
 
    aysys = tf([a2 a1 a0],[d2 d1 d0]);
    rsys  = tf([   r1 r0],[d2 d1 d0]);
%   bsys  = tf([   b1 b0],[d2 d1 d0]);
    bdsys = tf([b1 b0 0] ,[d2 d1 d0]);

    w     = damp(aysys);
    whz   = w(1)/(2*pi);
    set(handles.vehicle_freqs,'String',num2str(round2(whz)));
    
    SR    = str2num(get(handles.SR,'String'));
    ay    = lsim(aysys,(handles.steer/SR/(180/pi)),handles.t)/handles.g;

end

if ismember(handles.math,[0 2]) % initialization or roll parameter change
KT   = str2num(get(handles.KT,'String'));
IXXS = str2num(get(handles.IXXS,'String'));
RCH  = str2num(get(handles.RCH,'String'));
WS   = str2num(get(handles.WS,'String'));
HS   = str2num(get(handles.HS,'String'));

H0   = (HS - RCH)/1000;
MR2  = WS*H0;

w_roll = sqrt((180/pi)*  KT /(IXXS + MR2) );

roll_Hz   = w_roll/(2*pi);
roll_gain = str2num(get(handles.ROLL_GAIN,'String'));    % deg/g
roll_zeta = str2num(get(handles.ROLL_ZETA,'String'));

roll_d2   = 1/(w_roll)^2;
roll_d1   = 2*roll_zeta/w_roll; 
roll_d0   = 1;

roll_sys  = tf([roll_gain],[roll_d2 roll_d1 1]);

[W ,z]    = damp(roll_sys);

Wn   = W(1)/(2*pi);
set(handles.ROLL_HZ,'String',num2str(round2(Wn)))

zeta = z(1);
end

% t seconds, ay in gs
roll  = lsim(roll_sys,ay,handles.t); %Roll from ay on a plot
rollg = roll(end)/ay(end); % verify steady state roll gain
set(handles.IXXSH,'String',num2str((IXXS + MR2)))
% rollp2ss = max(roll)/roll(end);
% figure('NumberTitle','Off','Menubar','None','Name','Roll Angle Generation Study')

axes(handles.axes1)

if isequal(get(handles.hold_on,'Value'),0)
    cla
    hold off
else
    hold on
end

plot(handles.t,handles.steer/handles.steer(end),'b-',handles.t,roll,'r-',handles.t,ay,'k-')  
grid on
xlabel('Time (seconds)')
ylabel('Roll and Ay from Pseudo Step via Transfer Functions') 

title('This is How We Roll')

legend('Steer/Max.Steer','Roll Angle (deg)','Ay (g)','Location','Best');legend boxoff


[mag_roll fase_roll] = bode(roll_sys,handles.f);
[mag_bd fase_bd]     = bode(bdsys,handles.f);
[mag_rsys fase_rsys] = bode(rsys,handles.f);

axes(handles.axes2)
if isequal(get(handles.hold_on,'Value'),0)
    cla
    hold off
else
    hold on
end
plot(handles.f/(2*pi),squeeze(mag_roll),'r-',handles.f/(2*pi),squeeze(mag_bd),'b-',handles.f/(2*pi),squeeze(mag_rsys),'k-')
grid on
href(0)
set(gca,'XTickLabel',[])

ylabel('Roll, Sideslip Velocity and Yawrate Gain') 

legend('Roll Gain (^o/g)','Sideslip Velocity by Steer (deg/sec/deg)','Yaw Velocity by Steer (deg/sec/deg)','Location','Best');legend boxoff

axes(handles.axes3)
if isequal(get(handles.hold_on,'Value'),0)
    cla
    hold off
else
    hold on
end
plot(handles.f/(2*pi),squeeze(fase_roll),'r-',handles.f/(2*pi),squeeze(fase_bd),'b-',handles.f/(2*pi),squeeze(fase_rsys),'k-')
href(0)
xlabel('Frequency (Hz.)')
YLim([-360 360])
grid on
set(gca,'YTick',[-360:90:360],'YTickLabel',[-360:90:360])
ylabel('Roll, Sideslip Velocity and Yawrate Phase') 
legend('Roll (deg)','Sideslip Velocity by Steer (deg)','Yaw Velocity by Steer','Location','Best');legend boxoff


if isequal(get(handles.hold_on,'Value'),0)
    hold off
end

function hold_on_Callback(hObject, eventdata, handles)

function rch_slider_Callback(hObject, eventdata, handles)
set(handles.RCH,'String',num2str(round(get(handles.rch_slider,'Value'))))
handles.math = 2;  % roll computations only are needed.
make_xfers(hObject);

function rch_slider_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function y = rollgain(sm,hs,kt)
% sm in kg
% hs = sprung mass cgheight - roll axis height at sm cg in meters
% kt = total roll stiffness in Nm/deg
y = 9.806*sm*hs/kt;


