function array = paddedSlice(array, padval, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% paddedSlice: Slice an array, but pad result for out-of-bounds slices
% usage:  array = paddedSlice(array, padval, slice1, slice2, ..., sliceN)
%
% where,
%    array is an N-D array
%    padval is the value the result should be padded with if necessary
%    slice1, slice2, ... sliceN are one or more expressions for slicing the
%       input array, of the same type you would use when indexing an array,
%       as in 
%           array(slice1, slice2, ..., sliceN)
%       Logical indexing is not supported.
%
% Slice an array such that the result is padded if the slicing operation
%   goes out of bounds, instead of throwing an error.
%
% See also: padarray
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

% Pre-allocate a vector to hold the amount the input array needs to be
%   pre-padded and post-padded in each dimension
prePad = zeros(1, ndims(array));
postPad = zeros(1, ndims(array));

% Loop over slice dimensions
for dim = 1:length(varargin)
    % Get the smallest and largest slice indices
    x0 = min(slices{dim});
    x1 = max(slices{dim});
    if x0 < 1
        % Min slice index is less than 1; array needs to be pre-padded
        prePad(dim) = 1 - x0;
    else
        % No pre-padding necessary for this dimension
        prePad(dim) = 0;
    end
    if x1 > arraySize(dim)
        % Max slice index is greater than the length of the array; array
        %   needs to be post-padded
        postPad(dim) = x1 - arraySize(dim);
    else
        % No post-padding necessary for this dimension
        postPad(dim) = 0;
    end

    % Adjust slice indices based on amount of pre-padding
    slices{dim} = slices{dim} + prePad(dim);
end

% Pre-pad array where necessary
array = padarray(array, prePad, padval, 'pre');
% Post-pad array where necessary
array = padarray(array, postPad, padval, 'post');

% Slice padded array
array = array(slices{:});