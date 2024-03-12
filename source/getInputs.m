function inputs = getInputs(titleText, names, defaults, descriptions)
% Create a simple GUI to get arbitrary user input
arguments
    titleText char
    names cell
    defaults cell
    descriptions cell
end

numInputs = length(names);

f = figure('NumberTitle', 'off', 'Name', titleText);
f.UserData.Cancelled = true;
titleLabel = uicontrol('Parent', f, 'String', titleText, 'Style', 'text', 'Units', 'normalized', 'Position', [0.01, 0.90, 0.98, 0.09], 'FontSize', 20);
inputPanel = uipanel('Parent', f, 'BorderType', 'beveledin', 'BorderWidth', 3, 'Units', 'normalized', 'Position', [0.01, 0.11, 0.98, 0.78]);
okButton = uicontrol('Parent', f, 'String', 'OK', 'Callback', @ok, 'Units', 'normalized', 'Position', [0.01, 0.01, 0.485, 0.09]);
cancelButton = uicontrol('Parent', f, 'String', 'Cancel', 'Callback', @cancel, 'Units', 'normalized', 'Position', [0.505, 0.01, 0.485, 0.09]);
inputLabels = gobjects(1, numInputs);
inputControls = gobjects(1, numInputs);
for inputNum = 1:numInputs
    default = defaults{inputNum};
    inputClass = class(default);
    switch inputClass
        case 'char'
            % Text input
            style = 'edit';
            string = default;
            value = [];
        case {'single', 'double', 'int8', 'int16', 'int64', 'int32', 'uint8', 'uint16', 'uint32', 'uint64'}
            % Numerical input
            style = 'edit';
            string = num2str(default);
            value = [];
        case 'logical'
            % Boolean input
            style = 'checkbox';
            string = '';
            value = default;
        case 'categorical'
            % List input
            style = 'popupmenu';
            string = categories(default)';
            value = find(strcmp(char(default), string), 1);
        otherwise
            error('Input %s has unsupported input class: %s', names{inputNum}, class(default));
    end

    labelPosition = [0, 1 - inputNum / numInputs, 0.29, 1 / numInputs];
    controlPosition = [0.3, 1 - inputNum / numInputs, 0.7, 1 / numInputs];

    if isempty(descriptions{inputNum})
        prompt = [names{inputNum}];
    else
        prompt = [names{inputNum}, ': ', descriptions{inputNum}];
    end
    
    % Create label
    inputLabels(inputNum) = uicontrol('Parent', inputPanel, 'Style', 'text', 'Units', 'normalized', 'String', prompt, 'Position', labelPosition, 'HorizontalAlignment', 'right');
    % Create control
    inputControls(inputNum) = uicontrol('Parent', inputPanel, 'Style', style, 'Units', 'normalized', 'String', string, 'Value', value, 'Position', controlPosition, 'HorizontalAlignment', 'left');
end

uiwait(f);

if ~isgraphics(f) || ~isvalid(f) || f.UserData.Cancelled
    inputs = {};
else
    inputs = cell(1, numInputs);
    for inputNum = 1:numInputs
        inputClass = class(defaults{inputNum});
        control = inputControls(inputNum);
        switch inputClass
            case 'char'
                % Text input
                inputs{inputNum} = control.String;
            case {'single', 'double', 'int8', 'int16', 'int64', 'int32', 'uint8', 'uint16', 'uint32', 'uint64'}
                % Numerical input
                inputs{inputNum} = cast(str2double(control.String), inputClass);
            case 'categorical'
                % List input
                 inputs{inputNum} = categorical(control.String(control.Value), categories(defaults{inputNum}));
            otherwise
                error('Input %s has unsupported input class: %s', names{inputNum}, class(defaults{inputNum}));
        end
    end
end

try
    close(f);
catch
end

function ok(src, ~)
    src.Parent.UserData.Cancelled = false;
    uiresume();
function cancel(src, ~)
    src.Parent.UserData.Cancelled = true;
    uiresume();
