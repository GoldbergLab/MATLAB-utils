function positions = getUIPositionInUnits(widgets, units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getUIPositionInUnits: Get widget position in the given units
% usage:  positions = getUIPositionInUnits(widgets, units)
%
% where,
%    widgets is a UI widget, or array of them
%    units is a char array representing the units to get the position in
%       ('normalized', 'inches', 'centimeters', 'points', 'pixels', or 
%       'characters')
%    positions is a Nx4 array representing the position of the one or more
%       widgets in the requested units.
%
% Get the position(s) of the given widget(s) in the given units, leaving 
%   the widget(s) with the same units it started with.
%
% See also: setUIPositionInUnits
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    widgets matlab.graphics.Graphics
    units char
end

% Initialize positions
positions = zeros(length(widgets), 4);
% Loop over widgets
for k = 1:length(widgets)
    widget = widgets(k);
    originalUnits = widget.Units;
    widget.Units = units;
    positions(k, :) = widget.Position;
    widget.Units = originalUnits;
end