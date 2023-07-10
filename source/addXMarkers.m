function addXMarkers(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addXMarkers: add markers to x-axis of figure, typically for spectrograms
% usage: addXMarkers(times, color, height)
%        addXMarkers(times, color, height, bgcolor)
%        addXMarkers(times, titles, ___)
%        addXMarkers(ax, ___)
%
% where,
%    times is a Nx2 numerical array where times(k, 1) is the onset time of
%       the kth marker, and times(k, 2) is the offset time of the kth
%       marker.
%    color is a color descriptor for the face color of the markers
%    height is the desired height of the markers in pixels
%    bgcolor is an optional color for the background between the markers.
%       By default it is the same as the background color of the figure.
%    titles is an optional cell array of names to print on each marker.
%    ax is an optional argument specifying the axes to apply the markers
%       to. By default, they will be added to the current axes: gca()
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

argIdx = 1;

% Get axes on which to put markers
if length(varargin) >= argIdx
    if isa(varargin{argIdx}, 'matlab.graphics.axis.Axes')
        % User supplied axes
        ax = varargin{argIdx};
        argIdx = argIdx + 1;
    else
        % User did not supply axes - get existing or create new axes
        ax = gca();
    end
end

% Get marker times
if length(varargin) >= argIdx
    % User supplied times
    times = varargin{argIdx};
    argIdx = argIdx + 1;
else
    error('times is a required argument');
end

% Get titles of markers
if length(varargin) >= argIdx
    % Is this argument actually titles?
    if iscell(varargin{argIdx})
        % This must be the titles
        titles = varargin{argIdx};
        argIdx = argIdx + 1;
    else
        % This argument must not be titles - move on
        titles = {};
    end
end

% Get marker color
if length(varargin) >= argIdx
    % User supplied color
    color = varargin{argIdx};
    argIdx = argIdx + 1;
else
    % User did not supply color - use default
    color = 'red';
end

% Get marker height
if length(varargin) >= argIdx
    % User supplied marker height
    height = varargin{argIdx};
    argIdx = argIdx + 1;
else
    % User did not supply marker height - use default
    height = 10;
end

% Optional last argument
if length(varargin) >= argIdx
    % User supplied background color
    bgcolor = varargin{argIdx};
    argIdx = argIdx + 1;
else
    % User did not supply background color - use default.
    bgcolor = ax.Parent.Color;
end

% Turn off x-axis tick lines
ax.XRuler.TickDirection = 'none';

% Set up axes size
originalYLim = ylim(ax);
originalAxesUnits = ax.Units;
ax.Units = 'pixels';
originalAxesHeight = ax.Position(4);

% Convert height in pixels to frequency units
realHeight = height * diff(originalYLim) / originalAxesHeight;

% Change axes y limits to make space at bottom for markers
newY0 = originalYLim(1) - realHeight;
ylim(ax, [newY0, originalYLim(2)]);

% Lock y-axis zoom
z = zoom(ax);
z.Motion = 'horizontal';
z.Enable = 'on';

% Add background color
rectangle('Position', [0, newY0, diff(xlim(ax)), realHeight], 'FaceColor', bgcolor, 'EdgeColor', 'black');

% Loop over times to create markers
for k = 1:size(times, 1)
    x0 = times(k, 1);
    width = diff(times(k, :));
    % Create marker
    rectangle('Position', [x0, newY0, width, realHeight], 'Parent', ax, 'FaceColor', color, 'EdgeColor', 'none');
    if ~isempty(titles)
        % Add title
        text(ax, x0 + width/2, newY0 + realHeight/2, titles{k}, 'HorizontalAlignment', 'center');
    end
end

% Remove any tick labels on the markers
ax.YTick(ax.YTick < originalYLim(1)) = [];

ax.Units = originalAxesUnits;
