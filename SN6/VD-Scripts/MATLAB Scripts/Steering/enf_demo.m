function varargout = enf_demo(varargin)
% ENF_DEMO M-file for enf_demo.fig
%      ENF_DEMO, by itself, creates a new ENF_DEMO or raises the existing
%      singleton*.
%
%      H = ENF_DEMO returns the handle to a new ENF_DEMO or the handle to
%      the existing singleton*.
%
%      ENF_DEMO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ENF_DEMO.M with the given input arguments.
%
%      ENF_DEMO('Property','Value',...) creates a new ENF_DEMO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before enf_demo_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to enf_demo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help enf_demo

% Last Modified by GUIDE v2.5 08-May-2018 19:46:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @enf_demo_OpeningFcn, ...
                   'gui_OutputFcn',  @enf_demo_OutputFcn, ...
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


% --- Executes just before enf_demo is made visible.
function enf_demo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to enf_demo (see VARARGIN)

% Choose default command line output for enf_demo
handles.output = hObject;

global enfb enfc enf_hys mz_freq mz_max
mz_freq = str2num(get(handles.MZ_FREQ,'String'));
mz_max  = str2num(get(handles.MZ_MAX,'String'));
enfb    = str2num(get(handles.ENFB,'String'));
enfc    = str2num(get(handles.ENFC,'String'));
enf_hys = str2num(get(handles.ENF_HYS,'String'));

set(handles.cENF_HYS,'String',num2str(enf_hys))
set(handles.cMZ_MAX,'String',num2str(mz_max))
set(handles.cENFB,'String',num2str(enfb))
set(handles.cENFC,'String',num2str(enfc))
set(handles.cMZ_FREQ,'String',num2str(mz_freq))

axes(handles.axes1)
xlabel('Aligning Moment Input (Nm)')
ylabel('Steer Angle (deg)')
% Update handles structure
guidata(hObject, handles);
show_enf(hObject, eventdata, handles)

% UIWAIT makes enf_demo wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = enf_demo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function ENF_HYS_Callback(hObject, eventdata, handles)
global enfb enfc enf_hys mz_freq mz_max
enf_hys =  get(handles.ENF_HYS,'Value') ;
set(handles.cENF_HYS,'String',num2str(enf_hys))
show_enf(hObject, eventdata, handles)

function ENF_HYS_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MZ_MAX_Callback(hObject, eventdata, handles)
global enfb enfc enf_hys mz_freq mz_max
mz_max =  get(handles.MZ_MAX,'Value') ;
set(handles.cMZ_MAX,'String',num2str(mz_max))
show_enf(hObject, eventdata, handles)

function MZ_MAX_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ENFB_Callback(hObject, eventdata, handles)
global enfb enfc enf_hys mz_freq mz_max
enfb =  get(handles.ENFB,'Value') ;
set(handles.cENFB,'String',num2str(enfb))
show_enf(hObject, eventdata, handles)


function ENFB_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ENFC_Callback(hObject, eventdata, handles)
global enfb enfc enf_hys mz_freq mz_max
enfc =  get(handles.ENFC,'Value') ;
set(handles.cENFC,'String',num2str(enfc))
show_enf(hObject, eventdata, handles)

function ENFC_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function MZ_FREQ_Callback(hObject, eventdata, handles)
global enfb enfc enf_hys mz_freq mz_max
%mz_freq = str2num(get(handles.MZ_FREQ,'Value'));
mz_freq =  get(handles.MZ_FREQ,'Value');
set(handles.cMZ_FREQ,'String',num2str(mz_freq))
show_enf(hObject, eventdata, handles)


function MZ_FREQ_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function show_enf(hObject, eventdata, handles)
global enfb enfc enf_hys mz_freq mz_max
period= 1/mz_freq;        % test period
dt=.025;                % sample rate (sec)
hys=tf([1],[enf_hys,1]);    % hysteresis transfer function
tmax=1.25*period;       % time for a complete startup plus 1 full cycle
t=0:dt:tmax;            % timebase
mz= mz_max*sin(2*pi*mz_freq*t);  % Mz application signal
steer=lsim([1],[enf_hys,1],enf_fcn([enfb,enfc],mz),t);    % The enchilada
pt1= round((tmax-period)/dt);  % points to skip on startup
axes(handles.axes1)
plot(mz(pt1:end),steer(pt1:end),'.-')
grid on
xlabel('Aligning Moment Input (Nm)')
ylabel('Steer Angle (deg)')
vref(0),href(0)
xlim([-300 300])
ylim([-1  1])