function mustNotBeFieldOf(name, structure)
%   Argument validator that ensures the argument is a NOT field of the 
%       given structure
%
%   See also mustBeFieldOf, mustBeTextScalar, validators. 
    
if isfield(structure, name)
    error("MATLAB_utils:mustNotBeFieldOf", '%s is a field of the given structure', name);
end