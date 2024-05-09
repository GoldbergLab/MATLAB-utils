function position = getPositionWithUnits(gobject, units, indices)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getPositionWithUnits: get a graphics object's position in a given unit
% usage:  position = getPositionWithUnits(gobject, units)
%
% where,
%    gobject is a graphics object that has the "Position" property
%    units is a valid MATLAB graphics position unit (one of 'pixels',
%       'normalized', 'inches', 'centimeters', 'points', or 'characters'
%    position is a 1x4 vector of position values in the requested units, in
%       the same format as the Position property of graphics objects
%
% It is a common task to get the position of a graphics object with a
%   particular unit, but without actually changing the units of that
%   object. This function sets the units, gets the position, then restores
%   the original units.
%
% See also: setPositionWithUnits, changePositionWithUnits
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    gobject
    units (1, :) char {mustBeMember(units, {'pixels', 'normalized', 'inches', 'centimeters', 'points', 'characters'})}
    indices double = 1:4
end

% Save original units so it can be restored afterwards
originalUnits = gobject.Units;
% Set units to the desired units
gobject.Units = units;
% Get the position in the desired units
position = gobject.Position(indices);
% Restore the original units
gobject.Units = originalUnits;