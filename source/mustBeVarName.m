function mustBeVarName(name)
%   Argument validator that ensures the argument is a valid MATLAB 
%       variable name
%
%   See also mustBeTextScalar, mustBeNonzeroLengthText, validators. 
    
if ~isvarname(name)
    throwAsCaller(MException(message("MATLAB:validators:mustBeVarName")))
end