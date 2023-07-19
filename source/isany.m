function [tf, tf_mask] = isany(A, dataTypes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% isany: Determine if an object is any of multiple types
% usage:  tf = isany(A, dataTypes)
%         [tf, tf_mask] = isany(A, dataTypes)
%
% where,
%    A is any object
%    dataTypes is a char array or a cell array of char arrays representing
%       one or more class names to compare the class of A to
%    tf is a boolean indicating whether A matched one or more of the
%       provided dataTypes
%    tf_mask is a 1D boolean array indicating whether A matched each of the
%       provided dataTypes
%
% This is a convenience function to fill a gap left by the built in "isa"
%   function. Instead of testing against only one type, it can test against
%   multiple types simultaneously
%
% See also: isa
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrap dataTypes in cell array if it was provided as a single char array
if ischar(dataTypes)
    dataTypes = {dataTypes};
end

% Check which types match
tf_mask = cellfun(@(e)isa(A, e), dataTypes);

% Determine if any types match
tf = any(tf_mask);