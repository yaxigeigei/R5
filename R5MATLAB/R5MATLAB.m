function varargout = R5MATLAB(varargin)
% R5MATLAB MATLAB code for R5MATLAB.fig
%      R5MATLAB, by itself, creates a new R5MATLAB or raises the existing
%      singleton*.
%
%      H = R5MATLAB returns the handle to a new R5MATLAB or the handle to
%      the existing singleton*.
%
%      R5MATLAB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in R5MATLAB.M with the given input arguments.
%
%      R5MATLAB('Property','Value',...) creates a new R5MATLAB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before R5MATLAB_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to R5MATLAB_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help R5MATLAB

% Last Modified by GUIDE v2.5 29-May-2015 13:49:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @R5MATLAB_OpeningFcn, ...
                   'gui_OutputFcn',  @R5MATLAB_OutputFcn, ...
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


% --- Executes just before R5MATLAB is made visible.
function R5MATLAB_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to R5MATLAB (see VARARGIN)

% Choose default command line output for R5MATLAB
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes R5MATLAB wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Create global variable of serial communication object
serialObj = SerialObject('COM1', 'BaudRate', 115200, 'GuiHandle', handles, 'Listen', true);
setappdata(handles.output, 'serialObj', serialObj);

% Try loading existing analysis configuration
axes(handles.axes3);
if exist('cfg_analysis.mat', 'file')
    load('cfg_analysis.mat');
    setappdata(handles.output, 'anaCfg', anaCfg);
    anaCfg.ShowBaseline();
    anaCfg.ShowROI(handles.roiTable);
end
axis off ij equal;

% Try loading last time camera configuration
imaqreset;  % Make sure no camera is used
imaqInfo = imaqhwinfo; % Get all information
adaptorList = imaqInfo.InstalledAdaptors; % Get adaptor list
isFoundAdp = false;
if exist('cfg_gui_lastime.mat', 'file')
    load('cfg_gui_lastime.mat');
    
    % Restore GUI contents
    set(handles.saveMovCheckbox, 'Value', saveMov);
    set(handles.comPopmenu, 'Value', comPortIdx);
    set(handles.epochTimeEdit, 'String', epochTime);
    
    % Check default adaptor
    if ismember(adaptorName, adaptorList)
        set(handles.adaptorPopmenu, 'String', adaptorList);
        set(handles.adaptorPopmenu, 'Value', find(ismember(adaptorList, adaptorName)));
        camList = imaqhwinfo(adaptorName);
        if ~isempty(camList.DeviceIDs)
            camNames = cell(length(camList.DeviceIDs), 1);
            for i = 1 : length(camList.DeviceIDs)
                camNames{i} = camList.DeviceInfo(i).DeviceName;
            end
            set(handles.camPopmenu, 'String', camNames);
            % Check default camera
            if ismember(camName, camNames)
                camIdx = find(ismember(camNames, camName));
                set(handles.camPopmenu, 'Value', camIdx);
                formatList = camList.DeviceInfo(camIdx).SupportedFormats;
                formatIdx = find(ismember(formatList, formatName));
                set(handles.formatPopmenu, 'String', formatList);
                % Check default format
                if ismember(formatName, formatList)
                    filename = ['cfg_cam_' camName '_' formatName '.mat'];
                    if exist(filename, 'file')
                        load(filename);
                    else
                        cam = videoinput(adaptorName, camIdx, formatName);
                        cam.Name = [ camName '_' formatName ];
                    end
                    setappdata(handles.output, 'cam', cam);
                    set(handles.formatPopmenu, 'Value', formatIdx);
                    set(handles.historyListbox, 'String', { 'The camera is ready now' });
                end
            end
        else
            set(handles.camPopmenu, 'Value', 1);
            set(handles.camPopmenu, 'String', { 'No camera detected' });
            set(handles.formatPopmenu, 'Value', 1);
            set(handles.formatPopmenu, 'String', { 'Select a camera first' });
        end
        isFoundAdp = true;
    end
end

if ~isFoundAdp
    set(handles.adaptorPopmenu, 'String', [ 'Select an adaptor' adaptorList ]);
end


% --- Outputs from this function are returned to the command line.
function varargout = R5MATLAB_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;





% --- Executes during object creation, after setting all properties.
function comPopmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to comPopmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function comPopmenu_Callback(hObject, eventdata, handles)
% hObject    handle to comPopmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns comPopmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from comPopmenu


% --- Executes on button press in comButton.
function comButton_Callback(hObject, eventdata, handles)
% hObject    handle to comButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject, 'String'), 'Connect')
    portList = cellstr(get(handles.comPopmenu, 'String'));
    portName = portList{ get(handles.comPopmenu, 'Value') };
    % Create global variable of serial communication object
    serialObj = SerialObject(portName, 'BaudRate', 115200, 'GuiHandle', handles, 'Listen', true);
    setappdata(handles.output, 'serialObj', serialObj);
else
    serialObj = get(handles.output, 'serialObj');
    serialObj.Close(handles);
end


function commandEdit_Callback(hObject, eventdata, handles)
% hObject    handle to commandEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of commandEdit as text
%        str2double(get(hObject,'String')) returns contents of commandEdit as a double


% --- Executes during object creation, after setting all properties.
function commandEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to commandEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on commandEdit and none of its controls.
function commandEdit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to commandEdit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pause(0.01);
    sendCommand(handles);
end


function sendCommand(handles)
serialObj = getappdata(handles.output, 'serialObj');
command = get(handles.commandEdit, 'String');
if ~isempty(command)
    try
        if strcmp(command, 'clc')
            set(handles.historyListbox, 'String', { });
        else
            if strcmp(command, 'd') % fake dropping for testing and debugging
                if isappdata(handles.output, 'anaRt')
                    anaRt = getappdata(handles.output, 'anaRt');
                    anaRt.LogDropping();
                end
            end
            serialObj.Send(command, true, handles);
        end
        set(handles.commandEdit, 'String', '');
    catch
    end
end


% --- Executes on selection change in historyListbox.
function historyListbox_Callback(hObject, eventdata, handles)
% hObject    handle to historyListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns historyListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from historyListbox


% --- Executes during object creation, after setting all properties.
function historyListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to historyListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% Clear the box for tidyness
set(hObject, 'String', { });





% --- Executes during object creation, after setting all properties.
function adaptorPopmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adaptorPopmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in adaptorPopmenu.
function adaptorPopmenu_Callback(hObject, eventdata, handles)
% hObject    handle to adaptorPopmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns adaptorPopmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from adaptorPopmenu

adpList = cellstr(get(hObject,'String'));
adpIdx = get(hObject,'Value');
adpSelected = adpList{adpIdx};

if ~strcmp(adpSelected, 'Select an adaptor')
    if strcmp(adpList{1}, 'Select an adaptor')
        set(hObject, 'String', adpList(2:end));
        set(hObject, 'Value', adpIdx-1);
    end
    camList = imaqhwinfo(adpSelected);
    if ~isempty(camList.DeviceIDs)
        camNames = cell(length(camList.DeviceIDs), 1);
        for i = 1 : length(camList.DeviceIDs)
            camNames{i} = camList.DeviceInfo(i).DeviceName;
        end
        set(handles.camPopmenu, 'String', camNames);
    else
        set(handles.camPopmenu, 'Value', 1);
        set(handles.camPopmenu, 'String', { 'No camera detected' });
        set(handles.formatPopmenu, 'Value', 1);
        set(handles.formatPopmenu, 'String', { 'Select a camera first' });
    end
end


% --- Executes during object creation, after setting all properties.
function camPopmenu_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in cameraPopmenu.
function camPopmenu_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns cameraPopmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cameraPopmenu

% Load video format list into the popmenu
adpList = cellstr(get(handles.adaptorPopmenu,'String'));
adpIdx = get(handles.adaptorPopmenu,'Value');
adpSelected = adpList{adpIdx};

camIdx = get(handles.camPopmenu, 'Value');
camList = cellstr(get(handles.camPopmenu, 'String'));
camSelected = camList{camIdx};

if ~strcmp(camSelected, 'No camera detected') && ...
    ~strcmp(camSelected, 'Select an adaptor first')
    camList = imaqhwinfo(adpSelected);
    set(handles.formatPopmenu, 'String', camList.DeviceInfo(camIdx).SupportedFormats);
    set(handles.formatPopmenu, 'Value', 1);
end


% --- Executes on selection change in formatPopmenu.
function formatPopmenu_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns formatPopmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from formatPopmenu

adpList = cellstr(get(handles.adaptorPopmenu,'String'));
adpIdx = get(handles.adaptorPopmenu,'Value');
adpSelected = adpList{adpIdx};

camList = cellstr(get(handles.camPopmenu, 'String'));
camIdx = get(handles.camPopmenu, 'Value');
camSelected = camList{camIdx};

formatList = cellstr(get(handles.formatPopmenu, 'String'));
formatIdx = get(handles.formatPopmenu, 'Value');
formatSelected = formatList{formatIdx};

if ~strcmp(formatSelected, 'Select a camera first')
    % Try deleting existing videoinput(cam) object
    % in case the cam is loaded but not corretly
    try
        cam = getappdata(handles.output, 'cam'); % No cam will return []
        delete(cam);
    catch
    end
    % Load camera or create anew
    filename = ['cfg_cam_' camSelected '_' formatSelected '.mat'];
    if exist(filename, 'file')
        load(filename);
    else
        cam = videoinput(adpSelected, camIdx, formatSelected);
        cam.Name = [ camSelected '_' formatSelected ];
    end
    setappdata(handles.output, 'cam', cam);
    msgbox('The camera is ready now', 'Ready');
end


% --- Executes during object creation, after setting all properties.
function formatPopmenu_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in previewButton.
function previewButton_Callback(hObject, eventdata, handles)
if isappdata(handles.output, 'cam')
    if get(hObject, 'Value')
        set(hObject, 'String', 'Stop');
        vidLooper = VideoLooper();
        vidLooper.Preview(handles);
    else
        % Retrieve global variable
        cam = getappdata(handles.output, 'cam');
        % Clear all associated callbacks
        cam.FramesAcquiredFcn = { };
        % Keep trying to close the camera until it is really closed
        while isrunning(cam)
            stop(cam);
            pause(0.1);
        end
        cam.StopFcn = { };
        % Restore GUI
        set(hObject, 'String', 'Preview');
        set(hObject, 'Value', 0);
    end
else
    MissingCamError();
    set(hObject, 'Value', 0);
end


% --- Executes on button press in prevCfgButton.
function prevCfgButton_Callback(hObject, eventdata, handles)
% hObject    handle to prevCfgButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of prevCfgButton
if isappdata(handles.output, 'cam')
    cam = getappdata(handles.output, 'cam');
    preview(cam);
else
    MissingCamError();
end



function MissingCamError()
msgbox('You need to select a camera first', 'No Camera Selected');



% --- Executes on button press in configButton.
function configButton_Callback(hObject, eventdata, handles)
if isappdata(handles.output, 'cam')
    cam = getappdata(handles.output, 'cam');
    src = getselectedsource(cam);
    inspect(cam);
    inspect(src);
else
    MissingCamError();
end


% --- Executes on button press in saveCamButton.
function saveCamButton_Callback(hObject, eventdata, handles)
if isappdata(handles.output, 'cam')
    cam = getappdata(handles.output, 'cam');
    save(['cfg_cam_' cam.Name '.mat'], 'cam');
    msgbox('The current camera settings have been saved','Saved');
else
    MissingCamError();
end





% --- Executes on button press in baselineButton.
function baselineButton_Callback(hObject, eventdata, handles)
R5MATLAB_baseline_roi(handles);



% --- Executes on button press in startButton.
function startButton_Callback(hObject, eventdata, handles)
if get(hObject, 'Value')
    if isappdata(handles.output, 'anaCfg')
        if isappdata(handles.output, 'cam')
            set(hObject, 'String', 'Stop');
            vidLooper = VideoLooper();
            vidLooper.Start(handles);
        else
            MissingCamError();
        end
    else
        msgbox('You need to configure the analysis first', 'Analysis Configuration Missing');
    end
else
    % Retrieve global variable
    cam = getappdata(handles.output, 'cam');
    % Keep trying to close the camera until it is really closed
    while isrunning(cam)
        stop(cam);
        pause(0.1);
    end
    % Clear frame callback
    cam.FramesAcquiredFcn = { };
    cam.StopFcn = { };
    % Saving the data
    anaRt = getappdata(handles.output, 'anaRt');
    anaRt.trialProceed = true;
    anaRt.FinishEpoch();
    anaRt.ExportData();
    % Restore GUI
    set(hObject, 'String', 'Start');
    set(handles.pauseButton, 'Value', 0);
    set(handles.pauseButton, 'String', 'Pause');
    set(handles.frInBuffText, 'String', '');
end


% --- Executes on button press in pauseButton.
function pauseButton_Callback(hObject, eventdata, handles)
por = false;
if isappdata(handles.output, 'anaRt') && get(handles.startButton, 'Value')
    anaRt = getappdata(handles.output, 'anaRt');
    if strcmp(anaRt.rtMode, 'trials')
        if get(hObject, 'Value')
            anaRt.trialProceed = false;
            set(hObject, 'String', 'Resume');
        else
            anaRt.trialProceed = true;
            set(hObject, 'String', 'Pause');
        end
        setappdata(handles.output, 'anaRt', anaRt); % Save global variable
        por = true;
    end
end
if ~por
    set(hObject, 'Value', ~get(hObject, 'Value'));
end



% --- Executes on button press in saveMovCheckbox.
function saveMovCheckbox_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of saveMovCheckbox

function epochTimeEdit_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of epochTimeEdit as text
%        str2double(get(hObject,'String')) returns contents of epochTimeEdit as a double

% --- Executes during object creation, after setting all properties.
function epochTimeEdit_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end








% --- Executes when entered data in editable cell(s) in roiTable.
function roiTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to roiTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in saveTuneButton.
function saveTuneButton_Callback(hObject, eventdata, handles)
roiInfo = get(handles.roiTable, 'Data');
if ~isempty(roiInfo) && isappdata(handles.output, 'anaCfg')
    anaCfg = getappdata(handles.output, 'anaCfg');
    roiIndTrg = anaCfg.GetRoiTypeInd();
    for i = 1 : length(roiIndTrg)
        anaCfg.roiSet{roiIndTrg(i)}.SaveFirstRule(roiInfo(i,:));
    end
    setappdata(handles.output, 'anaCfg', anaCfg);
    save('cfg_analysis.mat', 'anaCfg');
    msgbox('The current tunning parameters are saved', 'Saved');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% Save the current user options on GUI
adaptorName = GetPopmenuInfo(handles.adaptorPopmenu);
camName = GetPopmenuInfo(handles.camPopmenu);
formatName = GetPopmenuInfo(handles.formatPopmenu);
comPortIdx = get(handles.comPopmenu, 'Value');
saveMov = get(handles.saveMovCheckbox, 'Value');
epochTime = get(handles.epochTimeEdit, 'String');
hotCmds = { get(handles.hotCmd1Edit, 'String'), get(handles.hotCmd2Edit, 'String'), ...
    get(handles.hotCmd3Edit, 'String'), get(handles.hotCmd4Edit, 'String') };

save('cfg_gui_lastime', 'comPortIdx', 'adaptorName', 'camName', 'formatName', ...
    'saveMov', 'epochTime', 'hotCmds');

% Reset Image Acquisition Toolbox
imaqreset;

try
    % Close serial communication and clear memory
    fclose(handles.serialObj);
    delete(handles.serialObj);
    % Restore button name
    set(hObject, 'String', 'Connect');
catch
end
% Hint: delete(hObject) closes the figure
delete(hObject);



function [ itemSelected, itemList, itemIdx ] = GetPopmenuInfo(popmenuHandle)
itemList = cellstr(get(popmenuHandle, 'String'));
itemIdx = get(popmenuHandle,'Value');
itemSelected = itemList{itemIdx};






% --- Executes during object creation, after setting all properties.
function hotCmd1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hotCmd1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function hotCmd1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hotCmd1Edit as text
%        str2double(get(hObject,'String')) returns contents of hotCmd1Edit as a double

% --- Executes on button press in hotCmd1Button.
function hotCmd1Button_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd1Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sendHotCommand(handles.hotCmd1Edit, handles);





% --- Executes during object creation, after setting all properties.
function hotCmd2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hotCmd2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function hotCmd2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hotCmd2Edit as text
%        str2double(get(hObject,'String')) returns contents of hotCmd2Edit as a double

% --- Executes on button press in hotCmd2Button.
function hotCmd2Button_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd2Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sendHotCommand(handles.hotCmd2Edit, handles);





% --- Executes during object creation, after setting all properties.
function hotCmd3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hotCmd3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function hotCmd3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hotCmd3Edit as text
%        str2double(get(hObject,'String')) returns contents of hotCmd3Edit as a double

% --- Executes on button press in hotCmd3Button.
function hotCmd3Button_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd3Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sendHotCommand(handles.hotCmd3Edit, handles);





% --- Executes during object creation, after setting all properties.
function hotCmd4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hotCmd4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function hotCmd4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hotCmd4Edit as text
%        str2double(get(hObject,'String')) returns contents of hotCmd4Edit as a double

% --- Executes on button press in hotCmd4Button.
function hotCmd4Button_Callback(hObject, eventdata, handles)
% hObject    handle to hotCmd4Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sendHotCommand(handles.hotCmd4Edit, handles);


function sendHotCommand(cmdSourceHandle, handles)
command = get(cmdSourceHandle, 'String');
if ~isempty(command)
    try
        if strcmp(command, 'clc')
            set(handles.historyListbox, 'String', { });
        elseif strcmp(command, 'd')
            % Fake dropping for testing and debugging
            if isappdata(handles.output, 'anaRt')
                anaRt = getappdata(handles.output, 'anaRt');
                anaRt.LogDropping();
            end
        else
            SerialSend(handles, command, true);
        end
    catch
    end
end
