function varargout = nonlin(varargin)
% NONLIN M-file for nonlin.fig
%      NONLIN, by itself, creates a new NONLIN or raises the existing
%      singleton*.
%
%      H = NONLIN returns the handle to a new NONLIN or the handle to
%      the existing singleton*.
%
%      NONLIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NONLIN.M with the given input arguments.
%
%      NONLIN('Property','Value',...) creates a new NONLIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before nonlin_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to nonlin_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help nonlin

% Last Modified by GUIDE v2.5 15-Jan-2025 15:19:30

%Handy FSAE Car tire properties:
% FY5=[-2.5309      0.28826      0.20599       1.5077  0.]
% MZ5= [0.0038654     0.015978      0.18495       3.0585 0. ]

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @nonlin_OpeningFcn, ...
                   'gui_OutputFcn',  @nonlin_OutputFcn, ...
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


% --- Executes just before nonlin is made visible.
function nonlin_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nonlin (see VARARGIN)
% Choose default command line output for nonlin:
movegui(hObject,'center')
%clc
handles.output = hObject;
handles.Options = optimset('Display','off','LargeScale','On');

global WF WR L SPEED TARGET A B IZZ FY5 MZ5 LTF LTR
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA TOEINF TOEINR WHL_LIFT
global time ayss rss 
global ay r beta rwan
global rear_axle_steer PWR
global fylf fyrf fylr fyrr nlf nrf nlr nrr ALPHALF ALPHARF ALPHAR


clear  ayg deltaf beta speed

fy_d1 = str2double(get(handles.FY_D1,'String'));
fy_d2 = str2double(get(handles.FY_D2,'String'));
fy_b  = str2double(get(handles.FY_B,'String'));
fy_c  = str2double(get(handles.FY_C,'String'));
fy_bp = str2double(get(handles.FY_Bp,'String'));
FY5   =[fy_d1 fy_d2 fy_b fy_c fy_bp];

mz_d1 = str2double(get(handles.MZ_D1,'String'));
mz_d2 = str2double(get(handles.MZ_D2,'String'));
mz_b  = str2double(get(handles.MZ_B,'String'));
mz_c  = str2double(get(handles.MZ_C,'String'));
mz_bp = str2double(get(handles.MZ_Bp,'String'));
MZ5   = [mz_d1 mz_d2 mz_b mz_c mz_bp];

WF        = str2double(get(handles.WF,'String'));
WR        = str2double(get(handles.WR,'String'));
set(handles.WT','String',num2str(WF + WR))
set(handles.WGTDIST,'String',num2str(100*(WF/(WF+WR)),'%4.1f'))
IZZ       = str2double(get(handles.IZZ,'String'));
L         = str2double(get(handles.L,'String'));
TLLTD     = str2double(get(handles.TLLTD,'String'))/100;
DELTAWT   = str2double(get(handles.DELTAWT,'String'))/100;
MAX_SPEED = str2double(get(handles.MAX_SPEED,'String'));
TARGET    = str2double(get(handles.TARGET,'String'));
TOEINF    = str2double(get(handles.TOEINF,'String'));
TOEINR=0;
% now patch in the results for the default panel values:  CAPS are GLOBAL
WB=L/1000;
A=WB*WR/(WF+WR);
B=WB*WF/(WF+WR);
% IZZ=(WF+WR)*A*B 
% set(handles.IZZ,'String',num2str(IZZ))
set(handles.HOLDOFF,'Value',1)
% Update handles structure
guidata(hObject, handles);
fy_plot(hObject)
mz_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end
% UIWAIT makes nonlin wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = nonlin_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function WF_Callback(hObject, eventdata, handles)
global WF WR IZZ L A B
WF=str2double(get(handles.WF,'String'));
if WF > 3000 | WF < 50
    warndlg({'Parameter out of range:','Front Weight (kg)'},'Nonlin Input Error !');
else
    IZZ=(WF+WR)*1;
    set(handles.IZZ,'String',num2str(IZZ))
    set(handles.WT','String',num2str(WF + WR))
    set(handles.WGTDIST,'String',num2str(100*(WF/(WF+WR)),'%4.1f'))
    WB=L/1000;
    A=WB*WR/(WF+WR);
    B=WB*WF/(WF+WR);
    % Update handles structure
    guidata(hObject, handles);
    fy_plot(hObject)
    mz_plot(hObject)
   if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end

end 

function WF_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function WR_Callback(hObject, eventdata, handles)
global WF WR IZZ L A B
WR=str2double(get(handles.WR,'String'));
if WR > 5000 | WR < 50    
    warndlg({'Parameter out of range:','Rear Weight (kg)'},'Nonlin Input Error !');
else
    IZZ=(WF+WR)*1;
    set(handles.IZZ,'String',num2str(IZZ))
    set(handles.WT','String',num2str(WF + WR))
    set(handles.WGTDIST,'String',num2str(100*(WF/(WF+WR)),'%4.1f'))
    WB=L/1000;
    A=WB*WR/(WF+WR);
    B=WB*WF/(WF+WR);
    % Update handles structure
    guidata(hObject, handles);
    fy_plot(hObject)
    mz_plot(hObject)
    if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end
end

function WR_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function L_Callback(hObject, eventdata, handles)
global L A B WF WR
L=str2double(get(handles.L,'String'));
if L > 3000 | L < 1000
   warndlg({'Parameter out of range:','Wheelbase (mm)'},'Nonlin Input Error !');
else
    WB=L/1000;
    A=WB*WR/(WF+WR);
    B=WB*WF/(WF+WR);
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end

end

function L_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function TLLTD_Callback(hObject, eventdata, handles)
global TLLTD
TLLTD=str2double(get(handles.TLLTD,'String'))/100;
if TLLTD > .99 | TLLTD < .1
    warndlg({'Parameter out of range:','TLLTD (%)'},'Nonlin Input Error !');
else
   if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end

end

function TLLTD_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function IZZ_Callback(hObject, eventdata, handles)
global IZZ
IZZ=str2double(get(handles.IZZ,'String'));
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function IZZ_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function FY_D1_Callback(hObject, eventdata, handles)
global FY
FY5(1)=str2double(get(handles.FY_D1,'String'));
fy_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end


function FY_D1_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MZ_D1_Callback(hObject, eventdata, handles)
global MZ5
MZ5(1)=str2double(get(handles.MZ_D1,'String'));
mz_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end


function MZ_D1_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function FY_D2_Callback(hObject, eventdata, handles)
global FY5
FY5(2)=str2double(get(handles.FY_D2,'String'));
fy_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function FY_D2_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MZ_D2_Callback(hObject, eventdata, handles)
global MZ5
MZ5(2)=str2double(get(handles.MZ_D2,'String'));
mz_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function MZ_D2_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function FY_B_Callback(hObject, eventdata, handles)
global FY5
FY5(3)=str2double(get(handles.FY_B,'String'));
fy_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function FY_B_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MZ_B_Callback(hObject, eventdata, handles)
global MZ5
MZ5(3)=str2double(get(handles.MZ_B,'String'));
mz_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function MZ_B_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function FY_C_Callback(hObject, eventdata, handles)
global FY5
FY5(4)=str2double(get(handles.FY_C,'String'));
fy_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end


function FY_C_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MZ_C_Callback(hObject, eventdata, handles)
global MZ5
MZ5(4)=str2double(get(handles.MZ_C,'String'));
mz_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function MZ_C_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function DELTAWT_Callback(hObject, eventdata, handles)
global DELTAWT 
DELTAWT =str2double(get(handles.DELTAWT,'String'))/100;
if DELTAWT > .99 | DELTAWT < 0
    warndlg({'Parameter out of range:','Total Load Transfer (F + R) (kg)'},'Nonlin Input Error !')
else
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end
end




function DELTAWT_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function TARGET_Callback(hObject, eventdata, handles)
global TARGET 
TARGET =str2double(get(handles.TARGET,'String'))
if TARGET < 25
   warndlg({'Parameter out of range:','Circle Radius (m)'},'Nonlin Input Error !');
else
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end

end


function TARGET_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MAX_SPEED_Callback(hObject, eventdata, handles)
global MAX_SPEED 
MAX_SPEED =str2double(get(handles.MAX_SPEED,'String'));
if MAX_SPEED > 200
    0 | MAX_SPEED < 10
    warndlg({'Parameter out of range:','Max. Test Speed (kph)'},'Nonlin Input Error !');
else
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end

end


function MAX_SPEED_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function q=fy_plot(hObject)
handles=guidata(hObject);
global WF WR FY5
% Just so you-all know this goes against my grain:
% don't need to make all new plots, just replot the FY values.
% If there is time, I'll re-do this to make it faster.
slips=(0:-.2:-15)'; % Negative slip angles for +FY
fzf = -9.806*(WF/2)*ones(length(slips),1);
fyf = Pacejka5_Model(FY5,[slips,fzf]);
% df = (FY5(1) + FY5(2)/1000.*9.806*(-WF/2))*9.806*(-WF/2);    

axes(handles.FY_Axes)
% dr = (FY5(1) + FY5(2)/1000.*9.806*(-WR/2))*9.806*(-WR/2);    
% fyr= dr.*sin(FY5(4).*atan(FY5(3).*slip));
fzr = -9.806*(WR/2)*ones(length(slips),1); 
fyr = Pacejka5_Model(FY5,[slips,fzr]);

% set(handles.CSF1,'String',num2str(-Pacejka5_Model(FY5,[-1,-9.806*WF/2])/(-9.806*WF/2),'%5.3f'))
% set(handles.CSR1,'String',num2str(-Pacejka5_Model(FY5,[-1,-9.806*WR/2])/(-9.806*WR/2),'%5.3f'))

set(handles.CSF1,'String',num2str(Pacejka5_Model(FY5,[-1,-9.806*WF/2]),'%5.1f'))
set(handles.CSR1,'String',num2str(Pacejka5_Model(FY5,[-1,-9.806*WR/2]),'%5.1f'))

plot(slips,fyf,'r-',slips,fyr,'b-')
set(gca, 'XDir', 'reverse')
xlabel('Slip Angle (deg.)')
title('Lateral Force (N)')
legend('Front','Rear','Location','SouthEast');legend boxoff
grid on
href(0)
drawnow

function q=mz_plot(hObject)
handles=guidata(hObject);
global WF WR MZ5
%Just so you-all know this goes against my grain:
% don't need to make all new plots, just replot the FY values.
% If there is time, I'll re-do this to make it faster.

slips =(0:.2:15)'; % positive slip angles. for positve mz
  fzf   = -9.806*(WF/2)*ones(length(slips),1);
mzf   = Pacejka5_Model(MZ5,[slips,fzf]); 
  fzr   = -9.806*(WR/2)*ones(length(slips),1); 
mzr   =Pacejka5_Model(MZ5,[slips,fzr]);

% set(handles.NSF1,'String',num2str(Pacejka5_Model(MZ5,[ 1,-9.806*WF/2])/(-9.806*WF/2),'%5.3f'))
% set(handles.NSR1,'String',num2str(Pacejka5_Model(MZ5,[ 1,-9.806*WR/2])/(-9.806*WR/2),'%5.3f'))

set(handles.NSF1,'String',num2str(Pacejka5_Model(MZ5,[ 1,-9.806*WF/2]),'%5.2f'))
set(handles.NSR1,'String',num2str(Pacejka5_Model(MZ5,[ 1,-9.806*WR/2]),'%5.2f'))
axes(handles.MZ_Axes)
plot(slips,mzf,'r-',slips,mzr,'b-')
xlabel('Slip Angle (deg.)')
title('Aligning Moment (Nm)')
legend('Front','Rear');legend boxoff;
grid on
href(0)
drawnow

function q=iso4138(hObject)
handles = guidata(hObject);
if get(handles.PROFILE,'Value') > 0
    profile on
end

global WF WR L SPEED TARGET A B IZZ FY5 MZ5 LTF LTR
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA WHL_LIFT TOEINF
global time ayss dwt_data
global fylf fyrf fylr fyrr nlf nrf nlr nrr 

clear  ayg deltaf beta speed  
dwt_data =[];
set(handles.WHL_LIFT,'String',' ');
ENFB=str2double(get(handles.ENFB,'String')); 
ENFC=str2double(get(handles.ENFC,'String')); 
set(handles.ML,'String',' ')
set(handles.ML_SPD,'String',' ')

% Compute a turn delta for a starting off point of 1 degrees RWA.
h        = waitbar(0,'Working','Name','ISO4138 Procedure in Progress...');
total_lt = DELTAWT*(WF+WR); 
LTF      = TLLTD*total_lt;
LTR      = (1-TLLTD)*total_lt;
delta0   = 180/pi*L/1000/TARGET;  % initial guess for 20 kph (deg RWA).
i          = 0;
%     axes(handles.FY_Axes)
%     cla
%     hold on
%     axes(handles.MZ_Axes)
%     cla
%     hold on
 
for SPEED  = 20:2.5:MAX_SPEED    % kph increments in a constant radius test
    delta  = fsolve(@wac_2dof,delta0,handles.Options);    % 30 degrees initial steer angle
    pp     = polyfit(time(end-50:end),ayss(end-50:end),1); % must be real steady state
    if pp(1) < .001
        i         = i+1;
        deltaf(i) = delta;
        ayg(i)    = AYG;
        beta(i)   = BETA;
        speed(i)  = SPEED;
        delta0    = delta;
        alphaf(i) = (ALPHALF+ALPHARF)/2;
        dwt_data(i,:) = [SPEED AYG alphaf(i) 9.8*AYG*LTF];
    end
    waitbar(SPEED/MAX_SPEED,h,['Speed = ' num2str(SPEED,'%4.1f') ' kph'])
    axes(handles.FY_Axes)
    hold on
    plot(ALPHALF(end),fylf,'r.',ALPHARF(end),fyrf,'m.')
    plot(ALPHAR(end),fylr,'b.',ALPHAR(end),fyrr,'k.')
    axes(handles.MZ_Axes)
    hold on
    plot(-ALPHALF(end),-nlf,'r.',-ALPHARF(end),-nrf,'m.')
    plot(-ALPHAR(end),-nlr,'b.',-ALPHAR(end),-nrr,'k.')
    
end

inx= find(diff(deltaf) < 0);
ayg(inx:end)=[];
deltaf(inx:end)=[];
beta(inx:end)=[];
speed(inx:end)=[];
alphaf(inx:end)=[];
tol=.99;
% Spline fittings have more freedom, ...
% dsp     = csaps(ayg,deltaf,tol);
dsp     = spline(ayg,deltaf);

dspd    = fnder(dsp);
K       = fnval(dspd,ayg);
% bsp     = csaps(ayg,beta,tol);
bsp     = spline(ayg,beta);

bspd    = fnder(bsp);
DR      = -fnval(bspd,ayg) ; % in a constant radius test, the sideslip gain is the rear cornering compliance.
DF      = DR+K;
% bu      = csaps(speed,beta,tol);
bu      = spline(speed,beta);

tan_spd = fnzeros(bu);
spspd  = spline(ayg,speed);
% spdf    = spline(ayg,K);
% spdfdd   = fnder(spdf,2);
% MAXLAT = max(max(fnzeros(spdfdd)))
MAXLAT=ayg(end)
maxlat_spd = fnval(spspd,MAXLAT(end));
set(handles.ML,'String','N/A')
if isempty(MAXLAT)
    disp('Max Lat Slip Gradient not reached')
    spdfdd=fnder(spdfd);
    maxlat=fnzeros(spdfdd);
    set(handles.ML,'String',num2str(MAXLAT(end),5))
    set(handles.ML_SPD,'String','N/A')
else
    %     disp([SPEED, RADIUS, MAXLAT maxlat_spd])
    set(handles.ML,'String',num2str(MAXLAT(end),4))
    set(handles.ML_SPD,'String',num2str(maxlat_spd,3))
end

if isempty(tan_spd)
    set(handles.TITLE_BLOCK,'String',['Tangent Speed = ' 'DNA ',  ' kph,  Highest Ay = ' num2str(ayg(end),'%5.3f') ' g'])
else
    set(handles.TITLE_BLOCK,'String',['Tangent Speed = ' num2str(tan_spd(1),'%4.1f') ' kph,  Highest Ay = ' num2str(ayg(end),'%5.3f') ' g'])
end
close(h)

axes(handles.axes1)
if get(handles.FREEZE_SCALE,'Value')
    axis manual
else
    axis auto
end

plot(ayg,DF,'r.-','LineWidth',2)
hold on
plot(ayg,DR,'b.-','LineWidth',2)
plot(ayg,K ,'k-','LineWidth',2)
set(handles.MAX_SPEED,'String',num2str(speed(end)))
ackpg=9.806*180/pi*str2double(get(handles.L,'STRING'))/1000/(speed(end)*.2778)^2;
plot(ayg(end),-ackpg,'Bo','MarkerSize',5,'MarkerFaceColor',[0 0 .1])
hold off
grid on
xlabel('Lateral Acceleration (g)')
ylabel('Cornering Compliances and Understeer (deg/g)')
yl=get(gca,'YLim');
if yl(2) < 2
    loc='NorthWest';
else
    loc='SouthEast';
end
legend('Front Cornering Compliance','Rear Cornering Compliance','Understeer',['-(Ackerman Gradient @ ',num2str(speed(end)),' kph)'],'Location',loc);legend boxoff
sidetext('Bill Cobb   01/05/2016   zzvyb6@yahoo.com')
if WHL_LIFT(1) set(handles.WHL_LIFT,'String','Front Wheel Lift','ForegroundColor',[1 0 0]);
elseif WHL_LIFT(2) set(handles.WHL_LIFT,'String','Rear Wheel Lift','ForegroundColor',[1 0 0]);
end
hold off

profile off
if get(handles.PROFILE,'Value') > 0
    profile viewer
    set(handles.PROFILE,'Value',0)
end
inx=find(ayg < .7);
ay=ayg(inx);
k =K(inx);
lin=sum(abs(diff(k)));
 
function DEBUG_Callback(hObject, eventdata, handles)
global WF WR L SPEED TARGET A B IZZ FY5 MZ5 LTF LTR
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA
{' SPEED ' 'DELTA ' 'ALPHALF' 'ALPHARF' ' ALPHAR' 'R    '  ' BETA  ' '  AYG  '}
[SPEED DELTA ALPHALF ALPHARF ALPHAR R BETA AYG ] 
set(handles.DEBUG,'Value',0)


function ENFB_Callback(hObject, eventdata, handles)
global ENFB
ENFB =str2double(get(handles.ENFB,'String'));
if ENFB > 5 | ENFB < 0
    warndlg({'Parameter out of range:','Mz Compliance Slope (deg/100Nm)'},'Nonlin Input Error !');
else
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end

end

function ENFB_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ENFC_Callback(hObject, eventdata, handles)
global ENFC
ENFC =str2double(get(handles.ENFC,'String'));
if ENFC > 1000 | ENFC < 10
   warndlg({'Parameter out of range:','Mz Compliance 37% Level (Nm)'},'Nonlin Input Error !');
else
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end
end


function ENFC_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function TOEINF_Callback(hObject, eventdata, handles)
global TOEINF
TOEINF =str2double(get(handles.TOEINF,'String'));
if TOEINF > 10 | TOEINF < -10
    warndlg({'Parameter out of range:','Total Front Toe (deg)'},'Nonlin Input Error !');
else
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end

end


function TOEINF_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function FREEZE_SCALE_Callback(hObject, eventdata, handles)




function ABOUT_Callback(hObject, eventdata, handles)
msgbox({'Programmed in Matlab by Bill Cobb','zzvyb6^@Yahoo.com  1/4/2016'},'About Nonlin')



function PRINT_Callback(hObject, eventdata, handles)

function PREVIEW_Callback(hObject, eventdata, handles)
printpreview(gcf);


function PRINT_PDF_Callback(hObject, eventdata, handles)
print(gcf,'Nonlin','-dpdf')

function BULKDATA_Callback(hObject, eventdata, handles)
global WF WR L SPEED TARGET A B IZZ FY5 MZ5 LTF LTR
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA TOEINF TOEINR WHL_LIFT

options.Resize='on';
options.WindowStyle='normal';

FY5=[0.98309   -0.062751     0.34636       1.137    0.058132];
MZ5=[-0.0034521    0.001797     0.28475      2.6516    0.036054];

defaultanswer={'DUN 245/40R18 227 kPa 07BMW530D 8" Rim ','1060','1000','2884','37','57','0.605','25.4',...
    '0.98309' '-0.062751' '0.34636' '1.137' '0.058132',...
    '-0.0034521' '0.001797' '0.28475' '2.6516' '0.036054'};
prompt={'Vehicle Description','Front Wgt.(kg)','Rear Wgt.(kg)',...    
    'Wheelbase (mm)','%Total Wgt. Transfer','TLLTD %',...
    'Mz Compliance Slope(deg/100Nm)','Mz Compliance 37% Level', ...
    'Tire Fy_D1','Tire Fy_D2','Tire FY_B','Tire Fy_C','Tire FY_Bp',...
    'Tire Mz_D1','Tire Mz_D2','Tire Mz_B','Tire Mz_C','Tire MZ_Bp'};
answer=inputdlg(prompt,'Nonlin Bulk Data Input',1,defaultanswer,options);
set(handles.VEHICLE,'String',answer(1));
set(handles.WF,'String',answer(2))
set(handles.WR,'String',answer(3))
set(handles.L, 'String',answer(4))
set(handles.DELTAWT,'String',answer(5))
set(handles.TLLTD,'String',answer(6))
set(handles.ENFB,'String',answer(7))
set(handles.ENFC, 'String',answer(8))
set(handles.FY_D1,'String',answer(9))
set(handles.FY_D2,'String',answer(10))
set(handles.FY_B ,'String',answer(11))
set(handles.FY_C ,'String',answer(12))
set(handles.FY_Bp,'String',answer(13))
set(handles.MZ_D1,'String',answer(14))
set(handles.MZ_D2,'String',answer(15))
set(handles.MZ_B, 'String',answer(16))
set(handles.MZ_C, 'String',answer(17))
set(handles.MZ_Bp ,'String',answer(18))

WF = str2double(get(handles.WF,'String'));
WR = str2double(get(handles.WR,'String'));
WT = WF + WR; 
set(handles.WT ,'String',num2str(WT));
set(handles.IZZ,'String',num2str(WT*(1+.1)));
set(handles.WGTDIST,'String',num2str(WF/(WF+WR),'%4.2f'));
IZZ   = str2double(get(handles.IZZ,'String'));
L     = str2double(get(handles.L,'String'));
L         = str2double(get(handles.L,'String'));
WB=L/1000;
A=WB*WR/(WF+WR) ;
B=WB*WF/(WF+WR) ;

TLLTD = str2double(get(handles.TLLTD,'String'))/100;
DELTAWT = str2double(get(handles.DELTAWT,'String'))/100;
fy_d1 = str2double(get(handles.FY_D1,'String'));
fy_d2 = str2double(get(handles.FY_D2,'String'));
fy_b  = str2double(get(handles.FY_B,'String'));
fy_c  = str2double(get(handles.FY_C,'String'));
fy_bp = str2double(get(handles.FY_Bp,'String'));
FY    =[fy_d1 fy_d2 fy_b fy_c fy_bp];

mz_d1 = str2double(get(handles.MZ_D1,'String'));
mz_d2 = str2double(get(handles.MZ_D2,'String'));
mz_b  = str2double(get(handles.MZ_B,'String'));
mz_c  = str2double(get(handles.MZ_C,'String'));
mz_bp = str2double(get(handles.MZ_Bp,'String'));
MZ    = [mz_d1 mz_d2 mz_b mz_c mz_bp];
TOEINF = 0;
set(handles.TOEINF,'String','0.')
set(handles.MAX_SPEED,'String','65')
MAX_SPEED=65;


% Update handles structure cause the plotters will need them.
guidata(hObject, handles);
fy_plot(hObject)
mz_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function certifyK0_Callback(hObject, eventdata, handles)
global WF WR L SPEED TARGET A B IZZ FY5 MZ5 LTF LTR
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA TOEINF TOEINR WHL_LIFT

options.Resize='on';
options.WindowStyle='normal';

defaultanswer={'DF=3.33,  DR=3.33,  K=0.00','1000','600.','2745','0','60','1.000','50',...
    '13.9994' '-0.00436336' '0.00998386' '2.14936' '0.000668417','0' '0' '0' '0' '0'};
prompt={'Vehicle Description','Front Wgt.(kg)','Rear Wgt.(kg)','Wheelbase (mm)','%Total Wgt. Transfer','TLLTD %','Mz Compliance Slope(deg/100Nm)','Mz Compliance 37% Level', ...
    'Tire Fy_D1','Tire Fy_D2','Tire FY_B','Tire Fy_C','Tire FY_Bp',...
    'Tire Mz_D1','Tire Mz_D2','Tire Mz_B','Tire Mz_C','Tire MZ_Bp' };
answer=inputdlg(prompt,'Nonlin Bulk Data Input',1,defaultanswer,options);
set(handles.VEHICLE,'String',answer(1));
set(handles.WF,'String',answer(2))
set(handles.WR,'String',answer(3))
set(handles.L, 'String',answer(4))
set(handles.DELTAWT,'String',answer(5))
set(handles.TLLTD,'String',answer(6))
set(handles.ENFB,'String',answer(7))
set(handles.ENFC, 'String',answer(8))
set(handles.FY_D1,'String',answer(9))
set(handles.FY_D2,'String',answer(10))
set(handles.FY_B ,'String',answer(11))
set(handles.FY_C ,'String',answer(12))
set(handles.FY_Bp,'String',answer(13))
set(handles.MZ_D1,'String',answer(14))
set(handles.MZ_D2,'String',answer(15))
set(handles.MZ_B, 'String',answer(16))
set(handles.MZ_C, 'String',answer(17))
set(handles.MZ_Bp, 'String',answer(18))

WF = str2double(get(handles.WF,'String')); 
WR = str2double(get(handles.WR,'String'));
WT = WF + WR ; 
set(handles.WT ,'String',num2str(WT));

L   = str2double(get(handles.L,'String'));
WB  = L/1000;
A   = WB*WR/(WF+WR); 
B   = WB*WF/(WF+WR); 


set(handles.IZZ,'String',num2str(WT*(1+.1)));
set(handles.WGTDIST,'String',num2str(WF/(WF+WR),'%4.2f'));
IZZ   = str2double(get(handles.IZZ,'String'));
L     = str2double(get(handles.L,'String'));
TLLTD = str2double(get(handles.TLLTD,'String'))/100;
DELTAWT = str2double(get(handles.DELTAWT,'String'))/100;
fy_d1 = str2double(get(handles.FY_D1,'String'));
fy_d2 = str2double(get(handles.FY_D2,'String'));
fy_b  = str2double(get(handles.FY_B,'String'));
fy_c  = str2double(get(handles.FY_C,'String'));
fy_bp  = str2double(get(handles.FY_Bp,'String'));
FY5    =[fy_d1 fy_d2 fy_b fy_c fy_bp];

mz_d1 = str2double(get(handles.MZ_D1,'String'));
mz_d2 = str2double(get(handles.MZ_D2,'String'));
mz_b  = str2double(get(handles.MZ_B,'String'));
mz_c  = str2double(get(handles.MZ_C,'String'));
mz_bp  = str2double(get(handles.MZ_Bp,'String'));
MZ5    = [mz_d1 mz_d2 mz_b mz_c mz_bp];
TOEINF = 0;
set(handles.TOEINF,'String','0.')
set(handles.TARGET,'String','33')
TARGET=33;
set(handles.MAX_SPEED,'String','100')
MAX_SPEED=100;

% Update handles structure cause the plotters will need them.
guidata(hObject,handles);
fy_plot(hObject)
mz_plot(hObject)

if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end


function ref= href(pt)
for n=1:length(pt)
    line(xlim,[pt(n) pt(n)],'color',[.01 .01 .01])
end
return

function ref= vref(pt)
for n=1:length(pt)
    line([pt(n) pt(n)],ylim,'color',[.01 .01 .01])
end
return


function HOLDOFF_Callback(hObject, eventdata, handles)
if (get(handles.HOLDOFF,'value') ==1)
     set(handles.HOLDOFF,'String','Run After Parameter Change')
 else
    set(handles.HOLDOFF,'String','Hold Off Solver')
    iso4138(hObject)
end


function PROFILE_Callback(hObject, eventdata, handles)




function fsaecark1_Callback(hObject, eventdata, handles)
global WF WR L SPEED TARGET A B IZZ FY5 MZ5 LTF LTR
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA TOEINF TOEINR WHL_LIFT

options.Resize='on';
options.WindowStyle='normal';

defaultanswer={'FSAE: DF=3.00, DR=2.00, K=1.00','80','120.','1600',...
    '0','60','1.000','50',...
    '1.4568e-005','-32.919',' 0.0074586','3.4627', '0'...
    '-0.002458','0.0019429','0.28312','0','0'};
prompt={'Vehicle Description','Front Wgt.(kg)','Rear Wgt.(kg)',...
    'Wheelbase (mm)','%Total Wgt. Transfer','TLLTD %',...
    'Mz Compliance Slope(deg/100Nm)','Mz Compliance 37% Level', ...
    'Tire Fy_D1','Tire Fy_D2','Tire FY_B','Tire Fy_C','Tire FY_Bp', ...
    'Tire Mz_D1','Tire Mz_D2','Tire Mz_B','Tire Mz_C','Tire MZ_Bp', };
answer=inputdlg(prompt,'Nonlin Bulk Data Input',1,defaultanswer,options);
set(handles.VEHICLE,'String',answer(1));
set(handles.WF,'String',answer(2))
set(handles.WR,'String',answer(3))
set(handles.L, 'String',answer(4))
set(handles.DELTAWT,'String',answer(5))
set(handles.TLLTD,'String',answer(6))
set(handles.ENFB,'String',answer(7))
set(handles.ENFC, 'String',answer(8))
set(handles.FY_D1,'String',answer(9))
set(handles.FY_D2,'String',answer(10))
set(handles.FY_B ,'String',answer(11))
set(handles.FY_C ,'String',answer(12))
set(handles.FY_Bp ,'String',answer(13))
set(handles.MZ_D1,'String',answer(14))
set(handles.MZ_D2,'String',answer(15))
set(handles.MZ_B, 'String',answer(16))
set(handles.MZ_C, 'String',answer(17))
set(handles.MZ_Bp, 'String',answer(18))

WF = str2double(get(handles.WF,'String')); 
WR = str2double(get(handles.WR,'String'));
WT = WF + WR ; 
set(handles.WT ,'String',num2str(WT));

L   = str2double(get(handles.L,'String'));
WB  = L/1000;
A   = WB*WR/(WF+WR); 
B   = WB*WF/(WF+WR); 


set(handles.IZZ,'String',num2str(WT*(1+.1)));
set(handles.WGTDIST,'String',num2str(WF/(WF+WR),'%4.2f'));
IZZ   = str2double(get(handles.IZZ,'String'));
L     = str2double(get(handles.L,'String'));
TLLTD = str2double(get(handles.TLLTD,'String'))/100;
DELTAWT = str2double(get(handles.DELTAWT,'String'))/100;
fy_d1 = str2double(get(handles.FY_D1,'String'));
fy_d2 = str2double(get(handles.FY_D2,'String'));
fy_b  = str2double(get(handles.FY_B,'String'));
fy_c  = str2double(get(handles.FY_C,'String'));
fy_bp  = str2double(get(handles.FY_Bp,'String'));
FY5    =[fy_d1 fy_d2 fy_b fy_c fy_bp];

mz_d1 = str2double(get(handles.MZ_D1,'String'));
mz_d2 = str2double(get(handles.MZ_D2,'String'));
mz_b  = str2double(get(handles.MZ_B,'String'));
mz_c  = str2double(get(handles.MZ_C,'String'));
mz_bp  = str2double(get(handles.MZ_Bp,'String'));
MZ5    = [mz_d1 mz_d2 mz_b mz_c mz_bp];
TOEINF = 0;
set(handles.TOEINF,'String','0.')
set(handles.TARGET,'String','33')
TARGET=33;
set(handles.MAX_SPEED,'String','100')
MAX_SPEED=100;

% Update handles structure cause the plotters will need them.
guidata(hObject,handles);
fy_plot(hObject)
mz_plot(hObject)

if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function validate_Callback(hObject, eventdata, handles)




function load_coefficients_Callback(hObject, eventdata, handles)
options.Resize='on';
options.WindowStyle='normal';

defaultanswer={'DF=3.00,  DR=2.00,  K=1.00','80','120.','1600',...
    '0','60','1.000','50','1.4568e-005','-32.919',' 0.0074586','3.4627', ...
    '-0.002458','0.0019429','0.28312','0'};
prompt={'Vehicle Description','Front Wgt.(kg)','Rear Wgt.(kg)',...
    'Wheelbase (mm)','%Total Wgt. Transfer','TLLTD %',...
    'Mz Compliance Slope(deg/100Nm)','Mz Compliance 37% Level', ...
    'Tire Fy_D1','Tire Fy_D2','Tire FY_B','Tire Fy_C','Tire Mz_D1',...
    'Tire Mz_D2','Tire Mz_B','Tire Mz_C' };
answer=inputdlg(prompt,'Nonlin Bulk Data Input',1,defaultanswer,options);
set(handles.VEHICLE,'String',answer(1));
set(handles.WF,'String',answer(2))
set(handles.WR,'String',answer(3))
set(handles.L, 'String',answer(4))
set(handles.DELTAWT,'String',answer(5))
set(handles.TLLTD,'String',answer(6))
set(handles.ENFB,'String',answer(7))
set(handles.ENFC, 'String',answer(8))
set(handles.FY_D1,'String',answer(9))
set(handles.FY_D2,'String',answer(10))
set(handles.FY_B ,'String',answer(11))
set(handles.FY_C ,'String',answer(12))
set(handles.FY_Bp ,'String',answer(13))
set(handles.MZ_D1,'String',answer(14))
set(handles.MZ_D2,'String',answer(15))
set(handles.MZ_B, 'String',answer(16))
set(handles.MZ_C, 'String',answer(17))
set(handles.MZ_Bp, 'String',answer(18))

function fetch_tire_Callback(hObject, eventdata, handles)
global WF WR FY5 MZ5
    if ~exist('handles.file')
        disp('Loading TTC Library Database')
        handles.file = 'C:\Documents and Settings\BillCobb\My Documents\FSAE\TTC_Library.xls';
        handles.sheet='Pacejka4';
        [x,handles.headers]=xlsread(handles.file,handles.sheet,'A1:F1');  % Get the database headers
        [handles.num,handles.items]=xlsread(handles.file,handles.sheet);  % Get all database entries
        handles.items(1,:)=[];  % delete header line
        handles.items(:,5:end)=[];
        handles.round   = char(handles.items(:,1));
        handles.tire_id = char(handles.items(:,2));
        handles.filen   = char(handles.items(:,3));
        handles.brand  = {[]};  % just in case you jump to a smaller database
        handles.pressures = round(handles.num(:,2)/6.89476);
        handles.coefs = handles.num(:,4:15);
        handles.loads = handles.num(:,16:20);

        for n=1:size(handles.tire_id,1)
            inx = findstr(handles.tire_id(n,:),' in');
            handles.rimwidths(n,1) = char(handles.tire_id(n,inx-1));
            tire_id{n}= char(handles.tire_id(n,:));
            x = char(tire_id(n));
            ins = findstr(x,' ');
            ts   =  x(ins(1):end);
            ins  = findstr(ts ,' on');
            if isempty(ins)
                handles.tsize{n,:} = strrep(ts(2:12),' ','');
            else
                handles.tsize{n,:}= strrep(ts(2:ins(1)),' ','');
            end
        end

        handles.tire_id = [char(handles.tire_id) blanks(length(handles.pressures))' num2str(handles.pressures) repmat(' psi',length(handles.pressures),1)];
        for n   = 1:size(handles.tire_id,1)
            inx    = findstr(handles.tire_id(n,:),' ');
            handles.brand{n,:} = handles.tire_id(n,1:inx(1)-1);
        end
        handles.brands = unique(handles.brand);
    end
disp('Library File loaded')
    handles.choice='Tire ID';
    handles.item = listdlg('PromptString',['Select ' handles.choice],'Name','FTA',...
        'SelectionMode','single','ListString', handles.tire_id ,'ListSize',[400 400]);

    handles.tire_id(handles.item,:);
    handles.selected_pressures = handles.pressures(handles.item);
    n  = length(handles.item);  % no. of tires permitted to survey
    nb = blanks(n)'; % no. of blank pads needed.
    handles.selected_tire_id = handles.tire_id(handles.item,:);
    handles.selected_coefs   = handles.coefs(handles.item,:);
    handles.selected_round   = handles.round(handles.item,:);
 

FY5(1) = handles.selected_coefs(1,1);
FY5(2) = handles.selected_coefs(1,2);
FY5(3) = handles.selected_coefs(1,3);
FY5(4) = handles.selected_coefs(1,4);
FY5(5) = handles.selected_coefs(1,5);

MZ5(1) = handles.selected_coefs(1,6);
MZ5(2) = handles.selected_coefs(1,7);
MZ5(3) = handles.selected_coefs(1,8);
MZ5(4) = handles.selected_coefs(1,9);
MZ5(5) = handles.selected_coefs(1,10);

set(handles.FY_D1,'String',num2str(FY5(1)))
set(handles.FY_D2,'String',num2str(FY5(2)))
set(handles.FY_B ,'String',num2str(FY5(3)))
set(handles.FY_C ,'String',num2str(FY5(4)))
set(handles.FY_Bp,'String',num2str(FY5(5)))
fy_plot(hObject)

set(handles.MZ_D1,'String',num2str(MZ5(1)))
set(handles.MZ_D2,'String',num2str(MZ5(2)))
set(handles.MZ_B ,'String',num2str(MZ5(3)))
set(handles.MZ_C ,'String',num2str(MZ5(4)))
set(handles.MZ_Bp,'String',num2str(MZ5(5)))
mz_plot(hObject)
set(handles.c_tire_id,'String',[handles.selected_tire_id handles.selected_round])
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end
guidata(hObject, handles); % Update handles structure


function Best_Toe_Callback(hObject, eventdata, handles)
global WF WR L SPEED TARGET A B IZZ FY5 MZ5 LTF LTR
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA TOEINF TOEINR WHL_LIFT
global dwt_data
figure('NumberTitle','off','Menubar','none','Name','Axle Toe Angle for Highest Fy at given Load Transfer')
colors = {'g-','b-','k-','m-','r-','r--','b--','k--','m--','g--'};
fz0= 9.806*WF/2;
p=0;
slipf = dwt_data(:,3);
dwtf  = dwt_data(:,4);
spdwf= spline(slipf,dwtf);

slip_levels =[0 -1 -2 -3 -4 ];
for dfzN =fnval(spdwf,slip_levels)
    p=p+1;  % load case #
    m=0;
    for slip = 6.:-.25: -6
        if isequal(slip,0)
            continue
        end
        dw = dfzN*sign(-slip);
        l_load =  fz0 - dw;
        r_load =  fz0 + dw;
        n=0;
        for toe = -7:.5: 7
            n=n+1;  %toe index
            %             fy_l =fnval(LATE_SLIP_VERT,{slip + toe/2,l_load}); % From ttc processing
            %             fy_r =fnval(LATE_SLIP_VERT,{slip - toe/2,r_load});
            fy_l = Pacejka5_Model(FY5,[slip + toe/2, l_load ]) ;  %Nonlinear tire FY representation
            fy_r = Pacejka5_Model(FY5,[slip - toe/2, r_load ]) ;  %Nonlinear tire FY representation
            fy(n) = fy_l + fy_r ;
            tow(n)= toe;
        end
        m  = m+1;
        sp = spline(tow,abs(fy));
        [best_fy(m),best_toe(m)]= fnmax(sp);
        SLIP(m) = slip;
    end
    plot(SLIP,best_toe,colors{p},'LineWidth',5)
    hold on
    cdfzN{p} = [num2str(round(dfzN)) ' N Load Transfer'];
end
grid
set(gca,'XDIR','reverse')

xlabel('Avg. Tire Slip Angle (deg)')
ylabel('Toe Setting at Highest Net Axle Tire Fy (deg)')
legend(cdfzN,'Location','SouthWest')

title(get(handles.VEHICLE,'String')) 
vref([slip_levels -slip_levels])
grid minor



function edit21_Callback(hObject, eventdata, handles)
global FY5 MZ5
eval(get(hObject,'string'))

if exist('FY5','var')
    set(handles.FY_D1,'string',num2str(FY5(1)))
    set(handles.FY_D2,'string',num2str(FY5(2)))
    set(handles.FY_B,'string',num2str(FY5(3)))
    set(handles.FY_C,'string',num2str(FY5(4)))
    set(handles.FY_Bp,'string',num2str(FY5(5)))
    fy_plot(hObject)
end

if exist('MZ5','var')
    set(handles.MZ_D1,'string',num2str(MZ5(1)))
    set(handles.MZ_D2,'string',num2str(MZ5(2)))
    set(handles.MZ_B,'string',num2str(MZ5(3)))
    set(handles.MZ_C,'string',num2str(MZ5(4)))
    set(handles.MZ_Bp,'string',num2str(MZ5(5)))
    mz_plot(hObject)
end

function edit21_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function certifyk2_Callback(hObject, eventdata, handles)
global WF WR L SPEED TARGET A B IZZ FY5  MZ5  LTF LTR 
global R BETA AYG MAX_SPEED TLLTD DELTAWT ALPHALF ALPHARF ALPHAR
global ENFB ENFC RADIUS DELTA TOEINF TOEINR WHL_LIFT

options.Resize='on';
options.WindowStyle='normal';

defaultanswer={'DF=5.00,  DR=3.00,  K=2.00','1000','600.', '2745' ,'0','60','1.000','50',...
    '14.0056'     '0.216855'    '0.0185895'      '2.10839'     '0.260385','0','0','0','0','0'};
prompt={'Vehicle Description','Front Wgt.(kg)','Rear Wgt.(kg)','Wheelbase (mm)','%Total Wgt. Transfer','TLLTD %',...
    'Mz Compliance Slope(deg/100Nm)','Mz Compliance 37% Level', ...
    'Tire Fy_D1','Tire Fy_D2','Tire FY_B','Tire Fy_C','Tire FY_Bp',...
    'Tire Mz_D1','Tire Mz_D2','Tire Mz_B','Tire Mz_C','Tire Mz_Bp' }; 
answer=inputdlg(prompt,'Nonlin Bulk Data Input',1,defaultanswer,options);
set(handles.VEHICLE,'String',answer(1));
set(handles.WF,'String',answer(2))
set(handles.WR,'String',answer(3))
set(handles.L, 'String',answer(4))
set(handles.DELTAWT,'String',answer(5))
set(handles.TLLTD,'String',answer(6))
set(handles.ENFB,'String',answer(7))
set(handles.ENFC, 'String',answer(8))
set(handles.FY_D1,'String',answer(9))
set(handles.FY_D2,'String',answer(10))
set(handles.FY_B ,'String',answer(11))
set(handles.FY_C ,'String',answer(12))
set(handles.FY_Bp,'String',answer(13))
set(handles.MZ_D1,'String',answer(14))
set(handles.MZ_D2,'String',answer(15))
set(handles.MZ_B, 'String',answer(16))
set(handles.MZ_C, 'String',answer(17))
set(handles.MZ_Bp,'String',answer(18))

WF = str2double(get(handles.WF,'String')); 
WR = str2double(get(handles.WR,'String'));
WT = WF + WR ; 
set(handles.WT ,'String',num2str(WT));

L   = str2double(get(handles.L,'String'));
WB  = L/1000;
A   = WB*WR/(WF+WR); 
B   = WB*WF/(WF+WR); 

set(handles.IZZ,'String',num2str(WT*(1+.1)));
set(handles.WGTDIST,'String',num2str(WF/(WF+WR),'%4.2f'));
IZZ   = str2double(get(handles.IZZ,'String'));
L     = str2double(get(handles.L,'String'));
TLLTD = str2double(get(handles.TLLTD,'String'))/100;
DELTAWT = str2double(get(handles.DELTAWT,'String'))/100;
fy_d1 = str2double(get(handles.FY_D1,'String'));
fy_d2 = str2double(get(handles.FY_D2,'String'));
fy_b  = str2double(get(handles.FY_B,'String'));
fy_c  = str2double(get(handles.FY_C,'String'));
fy_bp = str2double(get(handles.FY_Bp,'String'));
FY5   =[fy_d1 fy_d2 fy_b fy_c fy_bp];

mz_d1 = str2double(get(handles.MZ_D1,'String'));
mz_d2 = str2double(get(handles.MZ_D2,'String'));
mz_b  = str2double(get(handles.MZ_B,'String'));
mz_c  = str2double(get(handles.MZ_C,'String'));
mz_bp = str2double(get(handles.MZ_Bp,'String'));
MZ5   = [mz_d1 mz_d2 mz_b mz_c mz_bp];
TOEINF = 0;
set(handles.TOEINF,'String','0.')
set(handles.TARGET,'String','33')
TARGET=33;
set(handles.MAX_SPEED,'String','50')
MAX_SPEED=50;

% Update handles structure cause the plotters will need them.
guidata(hObject,handles);
fy_plot(hObject)
mz_plot(hObject)

if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end





function FY_Bp_Callback(hObject, eventdata, handles)
global FY
FY5(5)=str2double(get(handles.FY_Bp,'String'));
fy_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end


function FY_Bp_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MZ_Bp_Callback(hObject, eventdata, handles)
global MZ5
MZ5(5)=str2double(get(handles.MZ_Bp,'String'));
mz_plot(hObject)
if(get(handles.HOLDOFF,'Value')==0),iso4138(hObject),end



function MZ_Bp_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


