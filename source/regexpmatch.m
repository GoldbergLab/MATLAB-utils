function matches = regexpmatch(cell_arr, expression)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% regexpmatch: find which strings in an array match a regular expression
% usage:  matches = regexpmatch(cell_arr, expression)
%
% where,
%    cell_arr is a 1D cell array of strings
%    expression is a regular expression
%    matches is a 1D logical array indicating which strings within cell_arr
%       matched the given expression
%
% Get a simple logical mask indicating which strings within cell_arr
%   match the regular expression, and which do not.
%
% See also: regexp
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(cell_arr)
    matches = logical.empty();
else
    matches = cellfun(@(match)~isempty(match), regexp(cell_arr, expression));
end