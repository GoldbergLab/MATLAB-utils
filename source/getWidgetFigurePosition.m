function position = getWidgetFigurePosition(widget, units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getWidgetFigurePosition: get the position of a widget in figure coords
% usage:  position = getWidgetFigurePosition(widget, units)
%
% where,
%    widget is a graphics component
%    units is an optional MATLAB graphics unit mode. Default is 'pixels'
%    position is the position of the widget in screen coordinates
%
% The Position property of MATLAB graphics components gives the position of
%   a graphics widget relative to the lower left corner of its parent
%   widget. This function determines the position of the widget relative to
%   the lower left corner of the figure ancestor of the widget.
%
% See also: getWidgetScreenPosition
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    widget (1, 1) matlab.graphics.Graphics
    units (1, :) char {mustBeMember(units, {'pixels', 'normalized', 'inches', 'centimeters', 'points', 'characters'})} = 'pixels'
end

fig = ancestor(widget,'figure');
if isempty(fig)
    error('getWidgetFigurePosition:NoFigure','Widget has no figure ancestor.');
end

position = getpixelposition(widget, true);

if ~strcmp(units, 'pixels')
    position = hgconvertunits(fig, position, 'pixels', units, fig);
end