function varargout = nlsr(varargin)
% NLSR M-file for nlsr.fig
%      NLSR, by itself, creates a new NLSR or raises the existing
%      singleton*.
%
%      H = NLSR returns the handle to a new NLSR or the handle to
%      the existing singleton*.
%
%      NLSR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NLSR.M with the given input arguments.
%
%      NLSR('Property','Value',...) creates a new NLSR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before nlsr_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to nlsr_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help nlsr

% Last Modified by GUIDE v2.5 01-Feb-2019 17:25:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @nlsr_OpeningFcn, ...
                   'gui_OutputFcn',  @nlsr_OutputFcn, ...
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


% --- Executes just before nlsr is made visible.
function nlsr_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nlsr (see VARARGIN)

% Choose default command line output for nlsr
handles.output = hObject;
handles.max_swa=.9*100;
set(handles.figure1,'Name',['NLSR  Bill Cobb  zzvyb6@yahoo.com    ' date])
% Update handles structure
guidata(hObject, handles);
draw_srnl(handles)
% UIWAIT makes nlsr wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = nlsr_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function SRa0_Callback(hObject, eventdata, handles)
% hObject    handle to SRa0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SRa0 as text
%        str2double(get(hObject,'String')) returns contents of SRa0 as a double
set(handles.slider_SRa0,'Value',str2double(get(handles.SRa0,'String')))
draw_srnl((handles))

% --- Executes during object creation, after setting all properties.
function SRa0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SRa0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SRa1_Callback(hObject, eventdata, handles)
% hObject    handle to SRa1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SRa1 as text
%        str2double(get(hObject,'String')) returns contents of SRa1 as a double
set(handles.slider_SRa1,'Value',str2double(get(handles.SRa1,'String')))
draw_srnl((handles))

% --- Executes during object creation, after setting all properties.
function SRa1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SRa1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SRb_Callback(hObject, eventdata, handles)
% hObject    handle to SRb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SRb as text
%        str2double(get(hObject,'String')) returns contents of SRb as a double
set(handles.slider_SRb,'Value',str2double(get(handles.SRb,'String')))
draw_srnl((handles))

% --- Executes during object creation, after setting all properties.
function SRb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SRb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SRc_Callback(hObject, eventdata, handles)
% hObject    handle to SRc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SRc as text
%        str2double(get(hObject,'String')) returns contents of SRc as a double
set(handles.slider_SRc,'Value',str2double(get(handles.SRc,'String')))
draw_srnl((handles))

% --- Executes during object creation, after setting all properties.
function SRc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SRc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SRa2_Callback(hObject, eventdata, handles)
% hObject    handle to SRa2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SRa2 as text
%        str2double(get(hObject,'String')) returns contents of SRa2 as a double
set(handles.slider_SRa2,'Value',str2double(get(handles.SRa2,'String')))
draw_srnl((handles))

% --- Executes during object creation, after setting all properties.
function SRa2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SRa2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function draw_srnl(handles)
max_swa = handles.max_swa;
SR(1)   = str2double(get(handles.SRa0,'String')); 
SR(2)   = str2double(get(handles.SRa1,'String')); 
SR(3)   = str2double(get(handles.SRa2,'String')); 
SR(4)   = str2double(get(handles.SRb,'String')); 
SR(5)   = str2double(get(handles.SRc,'String')); 

swa=[-.9*handles.max_swa:.9*handles.max_swa];
[sr,rwa]= sr_func(SR,swa);
cla
switch get(handles.plot_sr,'Value')
    case 1
    plot(swa,sr,[-90 90],[mean(sr) mean(sr)],'--')
    ylabel('Overall Steer Ratio (deg/deg)')
    xlabel('Steering Wheel Angle (deg)')
    yl=get(gca,'Ylim');
    % xlim([-500 500]);
    ylim([1 1.3*str2num(get(handles.SRa0,'String'))]);

    yl=get(gca,'Ylim');
    text(-.83*handles.max_swa,yl(2)-.25,'Dashed Line represents the avg. ratio ±90 deg.','color',[0 0 1])
    text(-.86*handles.max_swa,yl(2)-.75,['= ' num2str(round(100*mean(sr))/100) ' : 1'],'color',[0 0 1])
    vref(0)
    grid on
otherwise
    plot(swa,rwa,'o')
    ylabel('Road Wheel Angles (deg)')
    xlabel('Steering Wheel Angle (deg)')
%     yl=get(gca,'Ylim');
    % ylim([1 1.3*str2num(get(handles.SRa0,'String'))]);

    % yl=get(gca,'Ylim');
    % text(-.83*handles.max_swa,yl(2)-.25,'Dashed Line represents the avg. ratio ±90 deg.','color',[0 0 1])
    % text(-.86*handles.max_swa,yl(2)-.75,['= ' num2str(round(100*mean(sr))/100) ' : 1'],'color',[0 0 1])
    vref(0);href(0)
    grid on
end
function ref= vref(pt)
for n=1:length(pt)
    line([pt(n) pt(n)],ylim,'color',[.01 .01 .01])
end
function [RATIO,RWA] = sr_func(SR,swa)
A0  = SR(1);
A1  = SR(2);
A2  = SR(3);
B   = SR(4);
C   = SR(5);
RATIO = A0 + A1/10^3*(swa) + A2/10^6*(swa).^2 + B*cos(2*(swa- C)/57.3) ;
RWA   = cumtrapz(swa,1./RATIO);
RWA   = RWA-max(RWA)/2.;

function set_range_Callback(hObject, eventdata, handles)
answer = inputdlg('Select Maximum Steer Angle','Range',1,{'500'})
handles.max_swa = str2num(char(answer));
guidata(hObject, handles);
draw_srnl((handles))

function slider_SRa0_Callback(hObject, eventdata, handles)
set(handles.SRa0,'String',get(handles.slider_SRa0,'Value'))
draw_srnl((handles))

function slider_SRa0_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider_SRa1_Callback(hObject, eventdata, handles)
set(handles.SRa1,'String',get(handles.slider_SRa1,'Value'))
draw_srnl((handles))

function slider_SRa1_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider_SRa2_Callback(hObject, eventdata, handles)
set(handles.SRa2,'String',get(handles.slider_SRa2,'Value'))
draw_srnl((handles))

function slider_SRa2_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider_SRb_Callback(hObject, eventdata, handles)
set(handles.SRb,'String',get(handles.slider_SRb,'Value'))
draw_srnl((handles))

function slider_SRb_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider_SRc_Callback(hObject, eventdata, handles)
set(handles.SRc,'String',get(handles.slider_SRc,'Value'))
draw_srnl((handles))

function slider_SRc_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function uipanel2_SelectionChangeFcn(hObject, eventdata, handles) 
draw_srnl(handles) 