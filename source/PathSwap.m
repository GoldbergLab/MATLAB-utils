function varargout = PathSwap(varargin)
% PATHSWAP MATLAB code for PathSwap.fig
%      PATHSWAP, by itself, creates a new PATHSWAP or raises the existing
%      singleton*.
%
%      H = PATHSWAP returns the handle to a new PATHSWAP or the handle to
%      the existing singleton*.
%
%      PATHSWAP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PATHSWAP.M with the given input arguments.
%
%      PATHSWAP('Property','Value',...) creates a new PATHSWAP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PathSwap_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PathSwap_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PathSwap

% Last Modified by GUIDE v2.5 08-Jun-2022 17:29:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PathSwap_OpeningFcn, ...
                   'gui_OutputFcn',  @PathSwap_OutputFcn, ...
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

% --- Executes just before PathSwap is made visible.
function PathSwap_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PathSwap (see VARARGIN)

% Choose default command line output for PathSwap
handles.output = 0;

if isempty(varargin)
    msgbox('PathSwap must be called with a cell array of paths to switch drive letters for.', 'Incorrect number of arguments');
    delete(hObject);
end

handles.alteredPaths = {};

handles.originalPaths = varargin{1};
if ischar(handles.originalPaths)
    handles.originalPaths = {handles.originalPaths};
end

if length(varargin) >= 2
    handles.searchStringEdit.String = varargin{2};
end
if length(varargin) >= 3
    handles.replaceStringEdit.String = varargin{3};
end

handles = updateOriginalPaths(handles);
handles = updateAlteredPaths(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PathSwap wait for user response (see UIRESUME)
uiwait(handles.figure1);

function handles = updateOriginalPaths(handles)
handles.originalText.String = handles.originalPaths;

function handles = updateAlteredPaths(handles)
handles.alteredPaths = {};
for k = 1:length(handles.originalPaths)
    handles.alteredPaths{k} = swapPath(handles.originalPaths{k}, handles.searchStringEdit.String, handles.replaceStringEdit.String);
end
handles.alteredText.String = handles.alteredPaths;

function alteredPath = swapPath(originalPath, searchStrings, replaceStrings)
if ischar(searchStrings)
    searchStrings = charMatrixToCell(searchStrings);
end
if ischar(replaceStrings)
    replaceStrings = charMatrixToCell(replaceStrings);
end

alteredPath = originalPath;
for k = 1:min(length(searchStrings), length(replaceStrings))
    searchString = searchStrings{k};
    replaceString = replaceStrings{k};
    alteredPath = strrep(alteredPath, searchString, replaceString);
end

function cellText = charMatrixToCell(charMatrix)
cellText = {};
for k = 1:size(charMatrix, 1)
    cellText{end+1} = charMatrix(k, :);
end

% --- Outputs from this function are returned to the command line.
function varargout = PathSwap_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
handles = guidata(hObject);
varargout{1} = handles.output;
delete(handles.figure1);


function searchStringEdit_Callback(hObject, eventdata, handles)
% hObject    handle to searchStringEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of searchStringEdit as text
%        str2double(get(hObject,'String')) returns contents of searchStringEdit as a double

handles = guidata(hObject);
handles = updateAlteredPaths(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function searchStringEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to searchStringEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function replaceStringEdit_Callback(hObject, eventdata, handles)
% hObject    handle to replaceStringEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of replaceStringEdit as text
%        str2double(get(hObject,'String')) returns contents of replaceStringEdit as a double

handles = guidata(hObject);
handles = updateAlteredPaths(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function replaceStringEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to replaceStringEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AcceptButton.
function AcceptButton_Callback(hObject, eventdata, handles)
% hObject    handle to AcceptButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = handles.alteredPaths;
guidata(hObject, handles);
figure1_CloseRequestFcn(handles.figure1, eventdata, handles)


% --- Executes on button press in CancelButton.
function CancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to CancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = 0;
guidata(hObject, handles);
figure1_CloseRequestFcn(handles.figure1, eventdata, handles)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else
    delete(hObject);
end


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on searchStringEdit and none of its controls.
function searchStringEdit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to searchStringEdit (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
