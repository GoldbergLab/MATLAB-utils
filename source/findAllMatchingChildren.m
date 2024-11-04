function matchingChildren = findAllMatchingChildren(parent, matchFunction)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findAllMatchingChildren: Recursively find all matching graphics children
% usage:  [matchingChildren] = findAllMatchingChildren(parent, matchFunction)
%
% where,
%    parent is a graphics object
%    matchFunction is a function that takes a single graphics object and
%       returns either true (indicating it matches) or false (indicating it
%       doesn't match)
%    matchingChildren is a list of matching child graphics objects
%
% This function recursively searches through the graphics hierarchy
%   starting at the given parent graphics object to find any and all
%   children (and grandchildren, etc) of that parent which satisfy the
%   given matching function, meaning children that produce "true" when
%   passed into the matching function.
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    parent (1, 1) matlab.graphics.Graphics
    matchFunction (1, 1) function_handle
end

% Determine if the direct children match
matchingChildren = parent.Children(arrayfun(matchFunction, parent.Children))';

% Recursively search through each of the childrens' hierarchy
for child = parent.Children'
    matchingChildren = [matchingChildren, findAllMatchingChildren(child, matchFunction)]; %#ok<AGROW> 
end