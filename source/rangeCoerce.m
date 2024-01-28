function [newVal, inRange] = rangeCoerce(val, range)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <function name>: <short description>
% usage:             newVal = rangeCoerce(val, range)
%         [newVal, inRange] = rangeCoerce(val, range)
%
% where,
%    range is a two element numerical vector of the form [minVal, maxVal], 
%       where maxVal is greater than minVal
%    val is a numerical array of any size/dimension
%    newVal is a numerical array of the same size as val. Any elements of
%       val that fall between the minVal and maxVal entries of the range
%       input are the same in newVal. Any that are outside that range are
%       coerced to the boundary of the range. For example, if the range is
%       [5, 10], and an element of val is 12, that element of newVal would 
%       be 10, whereas 2 would be coerced to 5.
%    inRange is a logical array of the same size as val. It is equivalent
%       to the array given by the expression val == newVal.
%
% Take the input val, which can be a scalar or array, and coerce it into
%   the range given.
%
% See also: max, min
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

newVal = max(val, range(1));
newVal = min(newVal, range(2));
if nargout > 1
    inRange = val == newVal;
end