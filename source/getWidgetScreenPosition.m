function position = getWidgetScreenPosition(widget, units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getWidgetScreenPosition: get the position of a widget in screen coords
% usage:  position = getWidgetScreenPosition(widget, units)
%
% where,
%    widget is a graphics component
%    units is an optional MATLAB graphics unit mode. Default is 'pixels'
%    position is the position of the widget in screen coordinates
%
% The Position property of MATLAB graphics components gives the position of
%   a graphics widget relative to the lower left corner of its parent
%   widget. This function determines the position of the widget relative to
%   the lower left corner of the screen.
%
% See also: getWidgetFigurePosition
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('units', 'var') || isempty(units)
    units = 'pixels';
end

% Get a reference to the parent widget
parent = widget.Parent;

% Record the original unit settings so we can restore them at the end
original_parent_units = parent.Units;
original_widget_units = widget.Units;

% Set parent figure unit setting to the desired output units
parent.Units = units;

% Set the widget units to 'normalized'
widget.Units = 'normalized';

% Get the parent figure's screen position
switch class(parent)
    case 'matlab.ui.Figure'
        parent_position = parent.Position;
    otherwise
        parent_position = getWidgetScreenPosition(parent, units);
end

% Get the widgets position relative to the parent position
widget_position = widget.Position;

% Compute the screen position of the widget
position = [0, 0, 0, 0];
position(1) = parent_position(1) + widget_position(1)*parent_position(3);
position(2) = parent_position(2) + widget_position(2)*parent_position(4);
position(3) = widget_position(3)*parent_position(3);
position(4) = widget_position(4)*parent_position(4);

% Restore the original unit settings of the widgets
parent.Units = original_parent_units;
widget.Units = original_widget_units;