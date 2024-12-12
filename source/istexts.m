function tf = istexts(A)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% istext: check if input is a 1D text array
% usage:  tf = istexts(A)
%
% where,
%    A is the input to check
%    tf is a logical indicating whether or not the input is a char/string
%
% Check if input is a 1D text array (cell array of char arrays or a 1xN or
%   Nx1 string)
%
% See also: ischar, isstring, iscellstr
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tf = (iscell(A) && all(cellfun(@ischar, A))) || (isstring(A) && isvector(A));