function setUIPositionInUnits(widgets, positions, units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setUIPositionInUnits: Set widget position in the given units
% usage:  getUIPositionInUnits(widgets, positions, units)
%
% where,
%    widgets is a UI widget, or array of them
%    positions is a Nx4 array representing the position of the one or more
%       widgets to set in the requested units.
%    units is a char array representing the units to set the position in
%       ('normalized', 'inches', 'centimeters', 'points', 'pixels', or 
%       'characters')
%
% Set the position(s) of the given widget(s) in the given units, leaving 
%   the widget(s) with the same units it started with.
%
% See also: getUIPositionInUnits
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    widgets matlab.graphics.Graphics
    positions (:, 4) double
    units char
end

% Loop over widgets
for k = 1:length(widgets)
    widget = widgets(k);
    originalUnits = widget.Units;
    widget.Units = units;
    widget.Position = positions(k, :);
    widget.Units = originalUnits;
end