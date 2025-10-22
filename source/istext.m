function tf = istext(A)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% istext: check if input is a text scalar (char array or a 1x1 string)
% usage:  tf = istext(A)
%
% where,
%    A is the input to check
%    tf is a logical indicating whether or not the input is a char/string
%
% See also: ischar, isstring, iscellstr
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tf = (ischar(A) && (isvector(A) || isempty(A))) || (isstring(A) && isscalar(A));