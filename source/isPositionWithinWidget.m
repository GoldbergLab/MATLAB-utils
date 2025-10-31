function inside = isPositionWithinWidget(widget, position, units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% isPositionWithinWidget: Determine if position is within widget boundaries
% usage:  inside = isPositionWithinWidget(widget, position)
%         inside = isPositionWithinWidget(widget, position, units)
%
% where,
%    widget is a graphics object
%    position is a 1x2 array representing a position within the figure
%       ancenstor of the given widget. The position will be interpreted
%       as the specified units, or if not specified, will be interpreted as
%       the units of the figure.
%    units is optionally the units to interpret the given position as. If
%       omitted, the given position will be interpreted in the units of the
%       figure
%    inside is a logical indicating whether or not the position is within
%       the bounds of the widget.
%
% <long description>
%
% See also: <related functions>
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    widget (1, 1) matlab.graphics.Graphics
    position (1, 2) {mustBeNumeric}
    units {mustBeGraphicsUnit} = ancestor(widget, 'figure').Units
end

% Get handle to figure containing the widget
fig = ancestor(widget, 'figure');

% Get widget position in pixels relative to figure
widgetPosition = getpixelposition(widget, true);

if ~strcmp(units, 'pixels')
    rect = hgconvertunits(fig, [position 0 0], units, 'pixels', fig);
    position = rect(1:2);
end

x = position(1);
y = position(2);
x0 = widgetPosition(1);
y0 = widgetPosition(2);
w =  widgetPosition(3);
h =  widgetPosition(4);

inside = (x >= x0) && (y >= y0) && (x <= x0 + w) && (y <= y0 + h);