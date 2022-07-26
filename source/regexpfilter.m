function filtered_cell_arr = regexpfilter(cell_arr, expression)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% regexpfilter: filter an array of strings by a regular expression
% usage:  filtered_cell_arr = regexpfilter(cell_arr, expression)
%
% where,
%    cell_arr is a 1D cell array of strings
%    expression is a regular expression
%    filtered_cell_arr is a cell array of strings containing only the
%       strings from cell_arr that matched the expression
%
% Get a filtered list of strings that consists only of the original strings
%   in the cell_arr that match the given regular expression.
%
% See also: regexp, regexpmatch
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matches = regexpmatch(cell_arr, expression);
filtered_cell_arr = cell_arr(matches);