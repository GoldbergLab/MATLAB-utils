function position = getFigureCoordsInChildUnits(coords, child, fig, childUnits, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getFigureCoordsInChildUnits: convert figure units to a child's units
% usage:  position = getFigureCoordsInChildUnits(coords, child, fig)
%         position = getFigureCoordsInChildUnits(coords, child)
%         position = getFigureCoordsInChildUnits(coords)
%         position = getFigureCoordsInChildUnits(__, Name/Value, ...)
%
% where,
%    coords is either a 1x2 or 1x4 numerical array representing either an
%       (x, y) coordinate pair in figure units, or a (x, y, w, h) position
%       vector.
%    child is an child graphics object with the desired coordinate system 
%       to convert the coordinates to.
%    fig is a figure which the given coords are from. If omitted, the
%       figure ancestor of child will be used.
%    childUnits is the units to convert to. If omitted, the current units
%       of the child widget will be used.
%    Name/Value arguments can include:
%       FigureUnits: The units that the coordinates are given in, one of 
%           'pixels', 'normalized', 'inches', 'centimeters', 'points', or 
%           'characters'. If omitted, the given figure's current Units 
%           property will be used
%
% This takes coordinates in a figure's coordinate system and converts it to
%   child widget's coordinate system in the given units.
%
% See also: getPositionWithUnits, getWidgetFigurePosition,
%   getFigureCoordsInAxesDataUnits
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    coords (1, :) double
    child (1, 1) matlab.graphics.Graphics
    fig (1, 1) matlab.ui.Figure = ancestor(child, 'matlab.ui.Figure')
    childUnits {mustBeGraphicsUnit} = child.Units
    options.FigureUnits = fig.Units
end

% Check that coords is correct length
assert(any(length(coords)==[2, 4]), 'coords must have length 2 or 4')

if child.Parent == fig
    % child's immediate parent is the figure
    childPosition = getPositionWithUnits(child, options.FigureUnits);
else
    % child's immediate parent is not the figure
    childPosition = getWidgetFigurePosition(child, options.FigureUnits);
end

% Get size of child in requested units
wh = getPositionWithUnits(child, childUnits, [3, 4]);
width = wh(1);
height = wh(2);

% Initialize position vector
position = zeros(1, 4);

% Convert first two coordinates
position(1) = width * (coords(1)-childPosition(1))/childPosition(3);
position(2) = height * (coords(2)-childPosition(2))/childPosition(4);
% If width and height were supplied, convert them too
if length(coords) > 2
    position(3) = width * coords(3)/childPosition(3);
    position(4) = height * coords(4)/childPosition(4);
end