function setPositionWithUnits(gobject, position, units, indices)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setPositionWithUnits: set a graphics object's position in a given unit
% usage:  setPositionWithUnits(gobject, position, units, indices)
%
% where,
%    gobject is a graphics object that has the "Position" property
%    position is a vector of position values in the requested units, where
%       each element of the position vector will be assigned to the
%       Position property at the corresponding index in indices
%    units is a valid MATLAB graphics position unit (one of 'pixels',
%       'normalized', 'inches', 'centimeters', 'points', or 'characters'
%    indices is an optional vector containing one or more numbers from 1 to
%       4, representing one or more indices in the gobject's Position 
%       property ([x, y, w, h]) to assign to. Default is 1:4.
%
% It is a common task to set the position of a graphics object with a
%   particular unit, but without actually changing the units of that
%   object. This function sets the units, sets the position, then restores
%   the original units.
%
% See also: getPositionWithUnits, changePositionWithUnits
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    gobject
    position (1, :) double
    units (1, :) char {mustBeMember(units, {'pixels', 'normalized', 'inches', 'centimeters', 'points', 'characters'})}
    indices double = 1:4
end

if length(position) ~= length(indices)
    error('position and indices must have the same length');
end

% Save original units so it can be restored afterwards
originalUnits = gobject.Units;
% Set units to the desired units
gobject.Units = units;
% Get the position in the desired units
gobject.Position(indices) = position;
% Restore the original units
gobject.Units = originalUnits;