function mustBeFieldOf(name, structure)
%   Argument validator that ensures the argument is a field of the given
%       structure
%
%   See also mustBeTextScalar, mustBeNonzeroLengthText, validators. 
    
if ~isfield(structure, name)
    error("MATLAB_utils:mustBeFieldOf", '%s is not a field of the given structure', name);
end