function array = safeSlice(array, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% safeSlice: Slice an array, but automatically fix out-of-bounds slices
% usage:  array = safeSlice(array, slice1, slice2, ..., sliceN)
%
% where,
%    array is an N-D array
%    slice1, slice2, ... sliceN are one or more expressions for slicing the
%       input array, of the same type you would use when indexing an array,
%       as in 
%           array(slice1, slice2, ..., sliceN)
%       Logical indexing is not supported.
%
% Slice an array such that if the slicing operation goes out of bounds, 
%   the slicing indices are automatically adjusted to keep them in range
%   instead of throwing an error.
%
% See also: paddedSlice
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the slices
slices = varargin;

% Determine input array size
arraySize = size(array);

% Adjust row slicing behavior to match MATLAB
if arraySize(1) == 1 && arraySize(2) > 1 && length(slices) == 1
    slices = [{1}, slices];
end

% Loop over slice dimensions and remove  out of bounds indices
for dim = 1:length(slices)
    slices{dim}(slices{dim} < 1) = [];
    slices{dim}(slices{dim} > arraySize(dim)) = [];
end

% Slice padded array
array = array(slices{:});