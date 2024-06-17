function changePositionWithUnits(gobject, positionDelta, units, indices)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% changePositionWithUnits: change a graphics object's position in a given unit
% usage:  changePositionWithUnits(gobject, positionDelta, indices, units)
%
% where,
%    gobject is a graphics object that has the "Position" property
%    positionDelta is a vector of position deltas in the requested units, 
%       where each element of the positionDelta vector will be added to the
%       Position property at the corresponding index in indices
%    indices is a vector containing one or more numbers from 1 to 4,
%       representing one or more indices in the gobject's Position property
%       to assign to.
%    units is a valid MATLAB graphics position unit (one of 'pixels',
%       'normalized', 'inches', 'centimeters', 'points', or 'characters'
%
% It is a common task to change the position of a graphics object with a
%   particular unit, but without actually changing the units of that
%   object. This function sets the units, changes the position, then 
%   restores the original units.
%
% See also: getPositionWithUnits, setPositionWithUnits
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    gobject
    positionDelta (1, :) double
    units {mustBeTextScalar, mustBeGraphicsUnit}
    indices double = 1:4
end

if length(positionDelta) ~= length(indices)
    error('position delta and indices must have the same length');
end

% Save original units so it can be restored afterwards
originalUnits = gobject.Units;
% Set units to the desired units
gobject.Units = units;
% Get the position in the desired units
gobject.Position(indices) = gobject.Position(indices) + positionDelta;
% Restore the original units
gobject.Units = originalUnits;