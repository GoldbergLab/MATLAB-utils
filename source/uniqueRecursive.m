function C = uniqueRecursive(A, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% uniqueRecursive: Find the unique values of an array after flattening
% usage: C = uniqueRecursive(A, varargin)
%
% where,
%    A is the input cell array, which may have nested sub-arrayes
%    varargin are any arguments that would normally be passed into unique
%    C is a flat cell array of unique elements from A and A's subarrays
%
% This function is designed to extend the functionality of the built in 
%   'unique' function to nested cell arrays.
%
% See also: unique
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check which elements are sub-cell-arrays
isSubArray = cellfun(@iscell, A);
% Extract list of sub arrays
subA = A(isSubArray);
% Extract list of regular elements
A = A(~isSubArray);
C = A;
for k = 1:length(subA)
    % Get recursive unique elements for each sub array
    newC = uniqueRecursive(subA{k}, varargin{:});
    C = {C{:}, newC{:}}; %#ok<CCAT> 
end
% Find overall unique elements
C = unique(C, varargin{:});