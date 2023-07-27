function [tuneParameters, tuneFunction] = imtune(imageData)

if ndims(imageData) == 3
    % Loapply for RGB channel
    otherChannels = 1:ndims(imageData);
    colorChannel = find(size(imageData) == 3, 1);
    if isempty(colorChannel)
        imageData = squeeze(imageData);
    else
        otherChannels(otherChannels == colorChannel) = [];
        imageData = permute(imageData, [otherChannels, colorChannel]);
        colorChannel = ndims(imageData);
    end
else
    colorChannel = [];
end

f = figure('Toolbar', 'none', 'Menubar', 'none', 'NumberTitle', false, ...
            'Name', 'imtune', ...
            'WindowButtonMotionFcn', @mouseMotionHandler, ...
            'WindowButtonDownFcn', @mouseButtonDownHandler, ...
            'WindowButtonUpFcn', @mouseButtonUpHandler, ...
            'CloseRequestFcn', @closeFunction);

ax1 = axes(f, 'Units', 'normalized', 'Position', [0.05, 0.2, 0.9, 0.75]);
hold(ax1, 'on');
ax2 = axes(f, 'Units', 'normalized', 'Position', [0.05, 0.05, 0.75, 0.15]);
hold(ax2, 'on');
applyButton = uicontrol(f, 'Units', 'normalized', ...
    'Style','pushbutton', 'String', 'Apply', ...
    'Position', [0.825, 0.13, 0.15, 0.07], 'Callback', @applyFunction);
CancelButton = uicontrol(f, 'Units', 'normalized', ...
    'Style','pushbutton', 'String', 'Cancel', ...
    'Position', [0.825, 0.05, 0.15, 0.07], 'Callback', @cancelFunction);

im = imshow(imageData, 'Parent', ax1);
if isempty(colorChannel)
    histogram(imageData(:))
else
    axis(ax2, 'auto');
    r = imageData(:, :, 1);
    g = imageData(:, :, 2);
    b = imageData(:, :, 3);
    histogram(r(:), 'Parent', ax2, 'FaceColor', 'red',   'EdgeColor', 'red');
    histogram(g(:), 'Parent', ax2, 'FaceColor', 'green', 'EdgeColor', 'green');
    histogram(b(:), 'Parent', ax2, 'FaceColor', 'blue',  'EdgeColor', 'blue');
    axis(ax2, 'manual');
end

maxVal = getMaxVal(imageData);

xlim(ax2, [0, maxVal]);

xl = xlim(ax2);
yl = ylim(ax2);

p = rectangle('Position', [xl(1), yl(1), diff(xl), diff(yl)], 'FaceColor', [1, 0, 0, 0.1]);

f.UserData.maxVal = maxVal;
f.UserData.OriginalImageData = imageData;
f.UserData.Image = im;
f.UserData.Highlight = p;
f.UserData.HistogramAxes = ax2;
f.UserData.Dragging = [false, false];
f.UserData.DragMargin = 0.03;
f.UserData.Immortal = true;

uiwait(f);

tuneParameters = getParams(f);
if tuneParameters.minVal == 0 && tuneParameters.maxVal == maxVal
    % Params didn't change
    tuneFunction = @(imageData)imageData;
else
    tuneFunction = @(imageData)tuneImage(imageData, tuneParameters);
end

f.UserData.Immortal = false;
delete(f);


function maxVal = getMaxVal(imageData)
imageClass = class(imageData);

switch imageClass
    case 'uint8'
        maxVal = 2^8-1;
    case 'uint16'
        maxVal = 2^16-1;
    case 'int16'
        maxVal = 2^15-1;
    case 'double'
        maxVal = 1;
    otherwise
        error('Unrecognized image class: %s', imageClass);
end

function params = getParams(fig)
params.minVal = fig.UserData.Highlight.Position(1);
params.maxVal = fig.UserData.Highlight.Position(1) + fig.UserData.Highlight.Position(3);

function newImageData = tuneImage(imageData, params)
newMinVal = params.minVal;
newMaxVal = params.maxVal;
oldMaxVal = getMaxVal(imageData);

newImageData = imageData;
newImageData(newImageData < newMinVal) = newMinVal;
newImageData(newImageData > newMaxVal) = newMaxVal;
newImageData = (newImageData - newMinVal) * (oldMaxVal / (newMaxVal - newMinVal));

function adjustImagePreview(fig)
params = getParams(fig);

imageData = fig.UserData.OriginalImageData;
newImageData = tuneImage(imageData, params);
fig.UserData.Image.CData = newImageData;

function closeFunction(fig, ~)
if ~fig.UserData.Immortal
    delete(fig);
end
uiresume(fig);

function applyFunction(button, ~)
fig = button.Parent;
closeFunction(fig);

function cancelFunction(button, ~)
fig = button.Parent;

% Reset selection before closing
xl = xlim(fig.UserData.HistogramAxes);
yl = ylim(fig.UserData.HistogramAxes);
fig.UserData.Highlight.Position = [xl(1), yl(1), diff(xl), diff(yl)];

if ~fig.UserData.Immortal
    delete(fig);
end
uiresume(fig);

function mouseButtonDownHandler(fig, ~)
dataPosition = figurePositionToDataPosition(fig.CurrentPoint, fig.UserData.Highlight.Parent);
mousePositionInHighlight = (dataPosition(1:2) - fig.UserData.Highlight.Position(1:2)) ./ fig.UserData.Highlight.Position(3:4);
if mousePositionInHighlight(2) >= 0 && mousePositionInHighlight(2) <= 1
    fig.UserData.Dragging = [false, false];
    if abs(mousePositionInHighlight(1)) < fig.UserData.DragMargin
        fig.UserData.Dragging(1) = true;
    end
    if abs(mousePositionInHighlight(1) - 1) < fig.UserData.DragMargin
        fig.UserData.Dragging(2) = true;
    end
end

function mouseButtonUpHandler(fig, ~)
fig.UserData.Dragging = [false, false];

function mouseMotionHandler(fig, ~)
dataPosition = figurePositionToDataPosition(fig.CurrentPoint, fig.UserData.Highlight.Parent, true);
mousePositionInHighlight = (dataPosition(1:2) - fig.UserData.Highlight.Position(1:2)) ./ fig.UserData.Highlight.Position(3:4);

if mousePositionInHighlight(2) >= 0 && mousePositionInHighlight(2) <= 1 && (abs(mousePositionInHighlight(1)) < fig.UserData.DragMargin || abs(mousePositionInHighlight(1) - 1) < fig.UserData.DragMargin)
    fig.Pointer = 'left';
else
    fig.Pointer = 'arrow';
end

if fig.UserData.Dragging(1)
    oldPosition = fig.UserData.Highlight.Position;
    newPosition = oldPosition;
    newPosition(1) = dataPosition(1);
    newPosition(3) = oldPosition(3) - (newPosition(1) - oldPosition(1));
    if newPosition(3) >= 0
        fig.UserData.Highlight.Position = newPosition;
    else
        fig.UserData.Dragging = [false, true];
        newPosition(1) = oldPosition(1) + oldPosition(3);
        newPosition(3) = abs(newPosition(3));
        fig.UserData.Highlight.Position = newPosition;
    end
    adjustImagePreview(fig);
end
if fig.UserData.Dragging(2)
    oldPosition = fig.UserData.Highlight.Position;
    newPosition = oldPosition;
    newPosition(3) = dataPosition(1) - oldPosition(1);
    if newPosition(3) >= 0
        fig.UserData.Highlight.Position = newPosition;
    else
        fig.UserData.Dragging = [true, false];
        newPosition(1) = oldPosition(1) - abs(newPosition(3));
        newPosition(3) = abs(newPosition(3));
        fig.UserData.Highlight.Position = newPosition;
    end
    adjustImagePreview(fig);
end

% if bottomLeft(2)
%     disp('Bottom');
% end
% if topRight(1)
%     disp('Right');
% end
% if topRight(2)
%     disp('Top');
% end
% if ~any(bottomLeft) && ~any(topRight)
%     disp('None');
% end

function dataPosition = figurePositionToDataPosition(figPosition, ax, clamp)
if ~exist('clamp', 'var')
    clamp = false;
end

xl = xlim(ax);
yl = ylim(ax);
axesOrigin = [xl(1), yl(1)];
axesWidth = [diff(xl), diff(yl)];
originalAxUnits = ax.Units;
ax.Units = ax.Parent.Units;
dataPosition = (figPosition - ax.Position(1:2)) .* axesWidth ./ ax.Position(3:4) + axesOrigin;
if clamp
    axesEnd = axesOrigin + axesWidth;
    dataPosition(dataPosition < axesOrigin) = axesOrigin(dataPosition < axesOrigin);
    dataPosition(dataPosition > axesEnd) = axesEnd(dataPosition > axesEnd);
end
ax.Units = originalAxUnits;