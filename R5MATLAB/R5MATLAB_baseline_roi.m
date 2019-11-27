function varargout = R5MATLAB_baseline_roi(varargin)
% R5MATLAB_BASELINE_ROI MATLAB code for R5MATLAB_baseline_roi.fig
%      R5MATLAB_BASELINE_ROI, by itself, creates a new R5MATLAB_BASELINE_ROI or raises the existing
%      singleton*.
%
%      H = R5MATLAB_BASELINE_ROI returns the handle to a new R5MATLAB_BASELINE_ROI or the handle to
%      the existing singleton*.
%
%      R5MATLAB_BASELINE_ROI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in R5MATLAB_BASELINE_ROI.M with the given input arguments.
%
%      R5MATLAB_BASELINE_ROI('Property','Value',...) creates a new R5MATLAB_BASELINE_ROI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before R5MATLAB_baseline_roi_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to R5MATLAB_baseline_roi_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help R5MATLAB_baseline_roi

% Last Modified by GUIDE v2.5 29-May-2015 20:02:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @R5MATLAB_baseline_roi_OpeningFcn, ...
                   'gui_OutputFcn',  @R5MATLAB_baseline_roi_OutputFcn, ...
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


% --- Executes just before R5MATLAB_baseline_roi is made visible.
function R5MATLAB_baseline_roi_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to R5MATLAB_baseline_roi (see VARARGIN)

% Choose default command line output for R5MATLAB_baseline_roi
handles.output = hObject;
% Store main window handle into handles
handles.main = varargin{1};
% Update handles structure
guidata(hObject, handles);

% UI modification
axes(handles.axes1);
axis off;
% Try to load previous analysis configuration
if isappdata(handles.main.output, 'anaCfg');
    RefreshUI(handles);
end

% UIWAIT makes R5MATLAB_baseline_roi wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = R5MATLAB_baseline_roi_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~LoadAnalysisCfg(handles)
    msgbox('Could not find "cfg_analysis.mat" file');
end

function success = LoadAnalysisCfg(handles)
success = exist('cfg_analysis.mat', 'file');
if success
    load('cfg_analysis.mat');
    setappdata(handles.main.output, 'anaCfg', anaCfg);
    RefreshUI(handles);
end

function RefreshUI(handles)
% Get global variable
anaCfg = getappdata(handles.main.output, 'anaCfg');
% Refresh main window
axes(handles.main.axes3)
anaCfg.ShowBaseline();
anaCfg.ShowROI(handles.main.roiTable);
% Refresh this window
axes(handles.axes1);
anaCfg.ShowBaseline();
anaCfg.ShowROI(handles.main.roiTable);
set(handles.listbox, 'String', { 1:length(anaCfg.roiSet) });
if size(anaCfg.roiSet, 1) > 0
    set(handles.listbox, 'Value', size(anaCfg.roiSet, 1));
end



% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
anaCfg = getappdata(handles.main.output, 'anaCfg');
save('cfg_analysis.mat', 'anaCfg');
RefreshUI(handles);




% --- Executes on button press in baselineButton.
function baselineButton_Callback(hObject, eventdata, handles)
% hObject    handle to baselineButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isappdata(handles.main.output, 'anaCfg')
    anaCfg = getappdata(handles.main.output, 'anaCfg');
else
    anaCfg = AnalysisConfig();
end

if isappdata(handles.main.output, 'cam')
    cam = getappdata(handles.main.output, 'cam');
    anaCfg.AcquireBaseline(cam);
    setappdata(handles.main.output, 'anaCfg', anaCfg);
    RefreshUI(handles);
    msgbox('Baseline Obtained','Finish');
else
    msgbox('No camera available');
end



% --- Executes on button press in addRoiButton.
function addRoiButton_Callback(hObject, eventdata, handles)
% hObject    handle to addRoiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isappdata(handles.main.output, 'anaCfg')
    anaCfg = getappdata(handles.main.output, 'anaCfg');
    roiTypes = get(handles.modePopmenu, 'String');
    typeIdx = get(handles.modePopmenu, 'Value');
    switch roiTypes{typeIdx}
        case 'Tracking'
            anaCfg.roiSet{end+1} = RoiTracking();
        case 'Trigger'
            anaCfg.roiSet{end+1} = RoiTrigger();
        otherwise
    end
    axes(handles.axes1);
    anaCfg.roiSet{end}.SelectNew();
    if isempty(anaCfg.roiSet{end}.mask) % in case user canceled the selection
        anaCfg.roiSet(end) = [];
    end
    setappdata(handles.main.output, 'anaCfg', anaCfg);
    RefreshUI(handles);
else
    msgbox('Baseline needs to be acquried first', 'Baseline');
end


% --- Executes on button press in delRoiButton.
function delRoiButton_Callback(hObject, eventdata, handles)
% hObject    handle to delRoiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(handles.main.output, 'anaCfg')
    anaCfg = getappdata(handles.main.output, 'anaCfg');
    if ~isempty(anaCfg.roiSet)
        idx = get(handles.listbox, 'Value');
        anaCfg.roiSet(idx) = [ ];
        setappdata(handles.main.output, 'anaCfg', anaCfg);
        RefreshUI(handles);
    end
else
    msgbox('Baseline needs to be acquried first','Baseline');
end


% --- Executes on selection change in modePopmenu.
function modePopmenu_Callback(hObject, eventdata, handles)
% hObject    handle to modePopmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns modePopmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modePopmenu


% --- Executes during object creation, after setting all properties.
function modePopmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modePopmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on selection change in listbox.
function listbox_Callback(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox
if isappdata(handles.main.output, 'anaCfg')
    anaCfg = getappdata(handles.main.output, 'anaCfg');
    if ~isempty(anaCfg.roiSet)
        t = anaCfg.roiSet{get(hObject,'Value')}.infoTable;
        set(handles.infoTable, 'ColumnName', t.Properties.VariableNames);
        set(handles.infoTable, 'Data', table2cell(t));
    end
end

% --- Executes during object creation, after setting all properties.
function listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addRuleButton.
function addRuleButton_Callback(hObject, eventdata, handles)
% hObject    handle to addRuleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(handles.main.output, 'anaCfg')
    anaCfg = getappdata(handles.main.output, 'anaCfg');
    if ~isempty(anaCfg.roiSet)
        idx = get(handles.listbox, 'Value');
        anaCfg.roiSet{idx}.AddRule();
        setappdata(handles.main.output, 'anaCfg', anaCfg);
        
        t = anaCfg.roiSet{idx}.infoTable;
        set(handles.infoTable, 'ColumnName', t.Properties.VariableNames);
        set(handles.infoTable, 'Data', table2cell(t));
    end
else
    msgbox('Baseline needs to be acquried first','Baseline');
end


% --- Executes on button press in delRuleButton.
function delRuleButton_Callback(hObject, eventdata, handles)
% hObject    handle to delRuleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(handles.main.output, 'anaCfg')
    anaCfg = getappdata(handles.main.output, 'anaCfg');
    if ~isempty(anaCfg.roiSet)
        selectedCell = get(handles.infoTable, 'UserData');
        if ~isempty(selectedCell)
            roiIdx = get(handles.listbox, 'Value');
            anaCfg.roiSet{roiIdx}.DeleteRule(selectedCell(1));
            setappdata(handles.main.output, 'anaCfg', anaCfg);

            t = anaCfg.roiSet{roiIdx}.infoTable;
            set(handles.infoTable, 'ColumnName', t.Properties.VariableNames);
            set(handles.infoTable, 'Data', table2cell(t));
        end
    end
else
    msgbox('Baseline needs to be acquried first','Baseline');
end


% --- Executes when entered data in editable cell(s) in infoTable.
function infoTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to infoTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
if isappdata(handles.main.output, 'anaCfg')
    anaCfg = getappdata(handles.main.output, 'anaCfg');
    if ~isempty(anaCfg.roiSet)
        idx = get(handles.listbox, 'Value');
        newInfo = get(handles.infoTable, 'Data');
        anaCfg.roiSet{idx}.SaveRule(newInfo);
        setappdata(handles.main.output, 'anaCfg', anaCfg);
    end
else
    msgbox('Baseline needs to be acquried first','Baseline');
end


% --- Executes when selected cell(s) is changed in infoTable.
function infoTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to infoTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'UserData', eventdata.Indices);
