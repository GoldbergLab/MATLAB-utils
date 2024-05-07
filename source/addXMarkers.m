function rectangles = addXMarkers(times, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addXMarkers: add markers to x-axis of figure, typically for spectrograms
% usage: addXMarkers(times)
%        addXMarkers(times, Name, Value, ...)
%
% where,
%    times is a Nx2 numerical array where times(k, 1) is the onset time of
%       the kth marker, and times(k, 2) is the offset time of the kth
%       marker.
%    Name/value arguments can include:
%       Color: a color descriptor for the face color of the markers
%       Height: the desired height of the markers in pixels
%       BackgroundColor is an optional color for the background between the 
%           markers. By default it is the same as the background color of 
%           the figure.
%       Label is a char array to use to label the row of markers
%       Titles is a cell array of names to print on each marker.
%       Parent specifyies the axes to apply the markers to. By default, 
%           they will be added to the current axes: gca()
%       Y is the y-value (in axes units) to place the top of the markers,
%           or a grpahics object to align the markers to the bottom of.
%           If omitted, markers will be aligned with the bottom of the axes
%
% This function adds markers along the x-axis of an existing plot.
%   Typically this is used to add time markers to a spectrogram.
%
% See also: showAudioSpectrogram
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arguments
    times (:, 2) double
    options.Color = 'red'
    options.Height (1, 1) double = 10
    options.Label char = ''
    options.Titles cell {mustBeText} = {}
    options.Parent = gca()
    options.BackgroundColor = gca().Color
    options.Y = NaN
end

% Gather arguments
ax = options.Parent;
color = options.Color;
if isempty(options.BackgroundColor)
    bgcolor = ax.Parent.Color;
else
    bgcolor = options.BackgroundColor;
end
height = options.Height;
label = options.Label;
titles = options.Titles;
Y1 = options.Y;

% Turn off x-axis tick lines
ax.XRuler.TickDirection = 'none';

% Set up axes size
originalYLim = ylim(ax);
originalAxesUnits = ax.Units;
ax.Units = 'pixels';

% Convert height in pixels to frequency units
originalAxesHeight = ax.Position(4);
realHeight = height * diff(originalYLim) / originalAxesHeight;
if ~isgraphics(Y1) && isnan(Y1)
    % Use default position of markers (bottom of axes)
    % Change axes y limits to make space at bottom for markers
    newY0 = originalYLim(1) - realHeight;
    ylim(ax, [newY0, originalYLim(2)]);
else
    if isgraphics(Y1)
        if isprop(Y1, 'Position')
            Y1 = Y1.Position(3);
        elseif isprop(Y1, 'YData')
            Y1 = min(Y1.YData);
        end
    end
    newY0 = Y1 - realHeight;
    yl = ylim(ax);
    if newY0 < yl(1)
        ylim(ax, [newY0, yl(2)]);
    end
end

% Lock y-axis zoom
z = zoom(ax);
z.Motion = 'horizontal';
z.Enable = 'on';

rectangles = gobjects(1, size(times, 1)+1);

% Add background color
rectangles(end) = rectangle(ax, 'Position', [0, newY0, diff(xlim(ax)), realHeight], 'FaceColor', bgcolor, 'EdgeColor', 'black');

% Add label, if provided
if ~isempty(label)
    labelText = text(ax, 0, newY0 + realHeight/2, [label, ' '], 'HorizontalAlignment', 'right', 'Color', color, 'Units', 'data');
    labelText.Units = 'normalized';
end

% Loop over times to create markers
for k = 1:size(times, 1)
    x0 = times(k, 1);
    width = diff(times(k, :));
    % Create marker
    rectangles(k) = rectangle(ax, 'Position', [x0, newY0, width, realHeight], 'Parent', ax, 'FaceColor', color, 'EdgeColor', 'none');
    if ~isempty(titles)
        % Add title
        text(ax, x0 + width/2, newY0 + realHeight/2, titles{k}, 'HorizontalAlignment', 'center');
    end
end

% Remove any tick labels on the markers
ax.YTick(ax.YTick < originalYLim(1)) = [];

ax.Units = originalAxesUnits;
