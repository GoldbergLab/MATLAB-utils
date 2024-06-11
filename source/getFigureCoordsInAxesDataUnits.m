function position = getFigureCoordsInAxesDataUnits(coords, ax, fig, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getFigureCoordsInAxesDataUnits: convert figure units to axes data units
% usage:  position = getFigureCoordsInAxesDataUnits(coords, ax, fig)
%         position = getFigureCoordsInAxesDataUnits(coords, ax)
%         position = getFigureCoordsInAxesDataUnits(coords)
%         position = getFigureCoordsInAxesDataUnits(__, Name/Value, ...)
%
% where,
%    coords is either a 1x2 or 1x4 numerical array representing either an
%       (x, y) coordinate pair in figure units, or a (x, y, w, h) position
%       vector.
%    ax is an axes object with the desired coordinate system to convert the
%       coordinates to. If omitted, the current axes will be used (gca)
%    fig is a figure which the given coords are from. If omitted, the
%       figure ancestor of ax will be used.
%    Name/Value arguments can include:
%       FigureUnits: The units that the coordinates are given in, one of 
%           'pixels', 'normalized', 'inches', 'centimeters', 'points', or 
%           'characters'. If omitted, the given figure's current Units 
%           property will be used
%
% This takes coordinates in a figure's coordinate system and converts it to
%   axes data units.
%
% See also: getPositionWithUnits, getWidgetFigurePosition
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    coords (1, :) numerictype
    ax (1, 1) matlab.graphics.axis.Axes = gca()
    fig (1, 1) matlab.ui.Figure = ancestor(ax, 'matlab.ui.Figure')
    options.FigureUnits = fig.Units
end

% Check that coords is correct length
assert(any(length(coords)==[2, 4]), 'coords must have length 2 or 4')

if ax.Parent == fig
    % axes' immediate parent is the figure
    axPosition = getPositionWithUnits(ax, options.FigureUnits);
else
    % axes' immediate parent is not the figure
    axPosition = getWidgetFigurePosition(ax, options.FigureUnits);
end

% Get axes data limits
xl = xlim(ax);
yl = ylim(ax);

% Initialize position vector
position = zeros(1, 4);
% Convert first two coordinates
position(1) = (xl(1)+(coords(1)-axPosition(1))/axPosition(3)*(xl(2)-xl(1)));
position(2) = (yl(1)+(coords(2)-axPosition(2))/axPosition(4)*(yl(2)-yl(1)));
% If width and height were supplied, convert them too
if length(coords) > 2
    position(3) = coords(3)/axPosition(3)*(xl(2)-xl(1));
    position(4) = coords(4)/axPosition(4)*(yl(2)-yl(1));
end