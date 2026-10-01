function varargout = chirp_test(varargin)
% CHIRP_TEST M-file for chirp_test.fig
%      CHIRP_TEST, by itself, creates a new CHIRP_TEST or raises the existing
%      singleton*.
%
%      H = CHIRP_TEST returns the handle to a new CHIRP_TEST or the handle to
%      the existing singleton*.
%
%      CHIRP_TEST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CHIRP_TEST.M with the given input arguments.
%
%      CHIRP_TEST('Property','Value',...) creates a new CHIRP_TEST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before chirp_test_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to chirp_test_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help chirp_test

% Last Modified by GUIDE v2.5 09-Mar-2018 16:19:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @chirp_test_OpeningFcn, ...
                   'gui_OutputFcn',  @chirp_test_OutputFcn, ...
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


% --- Executes just before chirp_test is made visible.
function chirp_test_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to chirp_test (see VARARGIN)

% Choose default command line output for chirp_test
clc
handles.output = hObject;
 handles.vehicle={'3.0','2.0','100','120','1745','5.','0.'};  %FSAE Car
%handles.vehicle={'6.0','3.0','1000','600','2745','20','0.'}; %Analytic car

handles.DF = str2double(handles.vehicle(1)); 
handles.DR = str2double(handles.vehicle(2)) ;
handles.WF = str2double(handles.vehicle(3)); 
handles.WR = str2double(handles.vehicle(4)) ;
handles.L  = str2double(handles.vehicle(5)); 
handles.SR = str2double(handles.vehicle(6)) ;
handles.KP = str2double(handles.vehicle(7)); 
handles.SPEED = str2double(get(handles.speed,'String'));

set(handles.cDF,'String',['DF = ' char(handles.vehicle(1)) ' deg/g'])
set(handles.cDR,'String',['DR = ' char(handles.vehicle(2)) ' deg/g'])
set(handles.cWF,'String',['WF = ' char(handles.vehicle(3)) ' kg'])
set(handles.cWR,'String',['WR = ' char(handles.vehicle(4)) ' kg'])
set(handles.cWB,'String',['WB = ' char(handles.vehicle(5)) ' mm'])
set(handles.cSR,'String',['SR = ' char(handles.vehicle(6)) ' deg/deg'])
set(handles.cKP,'String',['k'' = ' char(handles.vehicle(7))])

handles.fft_window= 14;
handles.fft_window_description= 'rectwin        - Rectangular window.';
% Update handles structure
guidata(hObject, handles);
make_xfers(hObject);

% UIWAIT makes chirp_test wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = chirp_test_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function sine_type_Callback(hObject, eventdata, handles)


function square_type_Callback(hObject, eventdata, handles)


function initial_freq_Callback(hObject, eventdata, handles)
make_xfers(hObject)

function initial_freq_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function final_freq_Callback(hObject, eventdata, handles)
make_xfers(hObject)

function final_freq_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function sps_Callback(hObject, eventdata, handles)
make_xfers(hObject)

function sps_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function vehicle_menu_Callback(hObject, eventdata, handles)

options.Resize='on';
options.WindowStyle='normal';

prompt={'Front Cornering Compliance deg/g','Rear Cornering Compliance deg/g',...
    'Front Mass (kg)','Rear Mass (kg)','Wheelbase (mm.)',...
    'Overall Steer Ratio','Inertia to Mass Index' };

answer=inputdlg(prompt,'Chirp_test Input',1,handles.vehicle,options);

handles.DF = str2double(answer(1)); 
handles.DR = str2double(answer(2)); 
handles.WF = str2double(answer(3)); 
handles.WR = str2double(answer(4)); 
handles.L  = str2double(answer(5)); 
handles.SR = str2double(answer(6)); 
handles.KP = str2double(answer(7)) ;

set(handles.cDF,'String',['DF = ' char(answer(1)) ' deg/g'])
set(handles.cDR,'String',['DR = ' char(answer(2)) ' deg/g'])
set(handles.cWF,'String',['WF = ' char(answer(3)) ' kg'])
set(handles.cWR,'String',['WR = ' char(answer(4)) ' kg'])
set(handles.cWB,'String',['WB = ' char(answer(5)) ' mm'])
set(handles.cSR,'String',['SR = ' char(answer(6)) ' deg/deg'])
set(handles.cKP,'String',['k'' = ' char(answer(7))])

handles.vehicle=[answer(1),answer(2),answer(3),answer(4),answer(5),answer(6),answer(7)];
speed      = str2double(get(handles.speed,'String'));
wb         = handles.L/1000.       ;
u          = speed*.2778   ;
conv       = 9.806*180./pi;
wgtdist    = handles.WF/(handles.WF+handles.WR);
b     = wb*wgtdist; 
a     = wb-b ;      
ackpg = conv*wb/(u^2); 
guidata(hObject, handles);
make_xfers(hObject)

function speed_Callback(hObject, eventdata, handles)
make_xfers(hObject)

function speed_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function x=make_xfers(hObject)
clc
handles=guidata(hObject);
% handles.output = hObject;
df=handles.DF;
dr=handles.DR;
l =handles.L;
wf=handles.WF;
wr=handles.WR;
sr=handles.SR;
speed=str2double(get(handles.speed,'String')); 
kp=handles.KP;
wb=l/1000 ;
a=wb*wr /(wf+wr); 
b=wb-a; 
u=speed*.2778; 
deg2rad= pi/180;
conv=9.806*180/pi;
 
% YAW VELOCITY TRANSFER FUNCTION Numerator factors:
 	r2=0.;	
    r1=a*b*conv*u  / (df*wb);
    r0=a*b*conv^2 / (df*dr*wb);
    
% lateral acceleration numerator factors:
    a2=a*b^2*conv*u / (df*wb*(kp+1));
    a1=a*b^2*conv^2 / (df*dr*wb);
    a0=a*b*conv^2*u / (df*dr*wb);
 
 % sideslip numerator factors:
    b2=0.;
    b1=a*b^2*conv / (df*wb*(kp+1));
    b0=a*b*conv*wb*(b*conv-dr*u^2)/(df*dr*wb^2*u);
    
 % common denominator factors:
    d2=a*b*u / (kp+1);
    d1=a*b*conv*(a*(df+dr*(kp+1))+b*(df*(kp+1)+dr))/(df*dr*wb*(kp+1));
    d0=a*b*conv*(conv*wb+u^2*(df-dr)) / (df*dr*u*wb);
     
   % inputs to transfer functions are radians of steer.
   % output of Ay is m/sec^2
   
rsys   = tf([r2 r1 r0],[d2 d1 d0]); % yawrate by steer 
bsys   = tf([b2 b1 b0],[d2 d1 d0]); % sideslip by steer
aysys  = tf([a2 a1 a0],[d2 d1 d0]); % ay by steer  
bgsys  = bsys/aysys;                % sideslip by g 

swgain = str2double(get(handles.SW_AMP,'String'));  

% r_ss     = dcgain(rsys) * swgain/sr   %actual
% beta_ss  = dcgain(bsys) * swgain/sr
% ay_ss    = dcgain(aysys)* swgain/sr/pi/180 
% betag_ss = dcgain(bgsys)* conv

h   = get(handles.signal_length,'Children'); % who are the elements of signal length
inx = find(cell2mat(get(h,'Value')) >0); % which one is pushed
segment_length=str2num(get(h(inx),'String')); % Get the value of the current length selection
 
h   = get(handles.chirp_type,'Children'); % who are the elements of signal types
inx = find(cell2mat(get(h,'Value')) > 0); % which one is pushed
signal_type=get(h(inx),'String'); % Get the value of the current signal type selection

sps = str2double(get(handles.sps,'String'));

dt   = 1/sps ; % time sample increment in seconds
time = 0:dt:segment_length; % time samples in seconds

f0 = str2double(get(handles.initial_freq,'String')); % Frequency of wave at t0
f1 = str2double(get(handles.final_freq,'String'));% Frequency of wave at time(end)
set(handles.pulse_parameters,'Visible','Off')
set(handles.chirp_parameters,'Visible','On')
set(handles.signal_length,'Visible','On')

switch signal_type
    case 'Sine'
        steer = chirp(time,f0,time(end),f1,[],-90)*swgain;
    case 'Square Sine'
        steer= sign(chirp(time,f0,time(end),f1,[],-90))*swgain;
    case 'Cosine'
        steer=chirp(time,f0,time(end),f1,[],0)*swgain;
    case 'Square Cosine'
        steer= sign(chirp(time,f0,time(end),f1,[],0))*swgain;
    case 'Pulse'
        set(handles.pulse_parameters,'Visible','On')
        set(handles.signal_length,'Visible','Off')
        set(handles.chirp_parameters,'Visible','Off')
        power = str2num(get(handles.power,'String'));
        fintim = str2num(get(handles.fintim,'String'));
        tmid   = str2num(get(handles.tmid,'String'));
        pwidth = str2num(get(handles.pwidth,'String')) ;
        time = 0:dt:fintim;
        steer=(-2./pi*atan(abs((time-tmid)./(pwidth/2)).^power)+1.).*swgain; 
end
conv= 180/pi;
axes(handles.steer_axes)
% Plot the timeseries
plot(time,steer,'r-');
%  ylim([-25 25])
 grid on
 xlabel('Time  (sec.)')
 ylabel('Steer Amplitude')

 %plot the PSD
h = spectrum.welch;
axes(handles.steer_psd)

psd(h,steer,'Fs',1/dt);
xlim([0 4])
 
r    = lsim(rsys ,steer/sr,time); %deg/sec   actual 
beta = lsim(bsys ,steer/sr,time); %deg
ay   = lsim(aysys,steer/sr,time); %m/sec^2

nfft = pow2(round(log2(length(steer))));

switch handles.fft_window
case 1
[sstxy,f]  = tfestimate(steer,ay,  bartlett(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,bartlett(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  bartlett(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   bartlett(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 2
[sstxy,f]  = tfestimate(steer,ay,  barthannwin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,barthannwin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  barthannwin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   barthannwin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 3    
[sstxy,f]  = tfestimate(steer,ay,  blackman(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,blackman(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  blackman(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   blackman(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 4        
[sstxy,f]  = tfestimate(steer,ay,  blackmanharris(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,blackmanharris(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  rectwin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   blackmanharris(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 5        
[sstxy,f]  = tfestimate(steer,ay,  bohmanwin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,bohmanwin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  blackmanharris(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   bohmanwin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 6       
[sstxy,f]  = tfestimate(steer,ay,  chebwin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,chebwin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  recchebwintwin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   chebwin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 7    
[sstxy,f]  = tfestimate(steer,ay,  flattopwin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,flattopwin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  flattopwin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   flattopwin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 8    
[sstxy,f]  = tfestimate(steer,ay,  gausswin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,gausswin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  gausswin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   gausswin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 9   
[sstxy,f]  = tfestimate(steer,ay,  hamming(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,hamming(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  hamming(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   hamming(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 10   
[sstxy,f]  = tfestimate(steer,ay,  hann(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,hann(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  hann(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   hann(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 11   
[sstxy,f]  = tfestimate(steer,ay,  kaiser(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,kaiser(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  kaiser(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   kaiser(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 12   
[sstxy,f]  = tfestimate(steer,ay,  nuttallwin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,nuttallwin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  nuttallwin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   nuttallwin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 13   
[sstxy,f]  = tfestimate(steer,ay,  parzenwin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,parzenwin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  parzenwin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   parzenwin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 14   
[sstxy,f]  = tfestimate(steer,ay,  rectwin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,rectwin(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  rectwin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   rectwin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 15   
[sstxy,f]  = tfestimate(steer,ay,  tukeywin(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,tukeywin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[betagtxy,f]= tfestimate(ay,beta,  tukeywin(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   tukeywin(nfft),nfft/2,nfft,sps); % yawv by steer transfer function
case 16   
[sstxy,f]  = tfestimate(steer,ay,  triang(nfft),nfft/2,nfft,sps); % ayg by steer transfer function
[betatxy,f]= tfestimate(steer,beta,triang(nfft),nfft/2,nfft,sps); % beta by steer transfer function
[betagtxy,f]= tfestimate(ay,beta,  triang(nfft),nfft/2,nfft,sps); % beta by ay transfer function
[yawvtxy,f]= tfestimate(steer,r,   triang(nfft),nfft/2,nfft,sps); % yawv by steer transfer function

end   
    
[mag,phase,w] = bode(rsys);
mag           = squeeze(mag)*swgain/sr;  % correct
w             = squeeze(w);

axes(handles.steer_psd);
ylabel('Power/Frequency')   %rewrite the default y label

axes(handles.yawrate_axes);
yawv_gain     = abs(yawvtxy) * swgain;
 
plot(f,yawv_gain,'r.',w/2/pi,mag,'b-');
xlim([0 4])
grid on
ylabel('Yawrate Gain')
set(gca,'XTickLabel',[])
legend('Process','Theory')
legend boxoff
set(handles.r_vts,'String',num2str(100/swgain*mag(1),4))

[mag,phase,w]=bode(bgsys);
mag = squeeze(mag)*conv*9.8;
w   = squeeze(w);
axes(handles.sideslip_axes);
beta_gain =  abs(betagtxy) *conv*9.8;
plot(f,beta_gain,'r.',w/2/pi,mag,'b-');
set(handles.window_type,'String',handles.fft_window_description);
xlim([0 4])
grid on
ylabel('Sideslip Gain')
set(gca,'XTickLabel',[])
set(handles.beta_vts,'String',num2str(mag(1),4))

[mag,phase,w]=bode(aysys);
mag=squeeze(mag)*swgain/sr/pi/180 ;
w=squeeze(w);
axes(handles.ay_axes);
ay_gain       = abs(sstxy)*swgain / (9.8*180/pi);

plot(f,ay_gain ,'r.',w/2/pi,mag,'b-');
xlim([0 4])
grid on
ylabel('Lateral Accel. Gain')
set(gca,'XTickLabel',[])
set(handles.ss_vts,'String',num2str(100/swgain*mag(1),3))
set(handles.ss_speed,'String',['at ' num2str(speed) ' kph'])


function SW_AMP_Callback(hObject, eventdata, handles)
make_xfers(hObject)

function SW_AMP_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function signal_length_SelectionChangeFcn(hObject, eventdata, handles)
make_xfers(hObject)

function chirp_type_SelectionChangeFcn(hObject, eventdata, handles)
make_xfers(hObject)


function power_Callback(hObject, eventdata, handles)
make_xfers(hObject)


function power_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function fintim_Callback(hObject, eventdata, handles)

sps = str2double(get(handles.sps,'String'));
leng= str2double(get(handles.fintim,'String')) * sps;
newleng=pow2(round(log2(leng)))/sps;
set(handles.fintim,'String',num2str(newleng));

make_xfers(hObject)


function fintim_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function tmid_Callback(hObject, eventdata, handles)
make_xfers(hObject)


function tmid_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pwidth_Callback(hObject, eventdata, handles)
make_xfers(hObject)


function pwidth_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function fft_windows_Callback(hObject, eventdata, handles)
S={'bartlett       - Bartlett window.',...
'barthannwin    - Modified Bartlett-Hanning window.',... 
'blackman       - Blackman window.',...
'blackmanharris - Minimum 4-term Blackman-Harris window.',...
'bohmanwin      - Bohman window.',...
'chebwin        - Chebyshev window.',...
'flattopwin     - Flat Top window.',...
'gausswin       - Gaussian window.',...
'hamming        - Hamming window.',...
'hann           - Hann window.',...
'kaiser         - Kaiser window.',...
'nuttallwin     - Nuttall defined minimum 4-term Blackman-Harris window.',...
'parzenwin      - Parzen (de la Valle-Poussin) window.',...
'rectwin        - Rectangular window.',...
'tukeywin       - Tukey window.',...
'triang         - Triangular window.'};
[selection,ok]=listdlg('ListString',S,'SelectionMode','single','ListSize',[400,220],...
'InitialValue',14,'Name','FFT Processing Window Selection','PromptString','Select a window:');
handles.fft_window = selection; 
handles.fft_window_description = cell2mat(S(selection));
guidata(hObject, handles);
make_xfers(hObject)
