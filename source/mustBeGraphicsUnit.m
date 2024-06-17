function mustBeGraphicsUnit(units)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mustBeGraphicsUnit: Validate that value is a valid MATLAB graphics unit
% usage:  mustBeGraphicsUnit(units)
%
% where,
%    units is a char array or string representing a MATLAB graphics unit
%
% Valid graphics units are: 
%   'pixels', 'normalized', 'inches', 'centimeters', 'points', 'characters'
%
% This is a validator function designed to be used in a MATLAB arguments
%   block to validate that an argument is a valid MATLAB graphics unit
%
% See also: mustBeMember
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mustBeMember(units, {'pixels', 'normalized', 'inches', 'centimeters', 'points', 'characters'});