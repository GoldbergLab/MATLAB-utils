function tf = istext(A)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% istext: check if input is a char array or a string
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

tf = ischar(A) || isstring(A);