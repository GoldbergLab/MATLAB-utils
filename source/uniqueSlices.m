function [C, ia, ic] = uniqueSlices(A, dim, setOrder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% uniqueSlices: find unique slices of an N-dimensional array
% usage:  C = uniqueSlices(A, dim, setOrder)
%         [C, ia, ic] = uniqueSlices(A, dim, setOrder)
%
% where,
%    A is an array of any dimensionality
%    dim is the dimension along which to find slices. For example, if the
%       size(A) = 100x300x200, and dim = 2, then slices of the form 
%       A(:, n, :) will be considered, and the output would be of the shape
%       100xMx200, where M <= 300, depending on how many unique slices
%       exist.
%    setOrder is a char array indicating whether or not to sort the output.
%       Options are 'stable' and 'sorted'. Default is 'sorted.
%    C is the same as A with non-unique slices remoted
%    ia, ic are index vectors representing the transformation from A to C
%    and C to A, such that 
%       C = A(:, ..., :, ia, :, ..., :)
%    and 
%       A = C(:, ..., :, ic, :, ..., :)
%
% This is an extension of the 'unique' function for N-dimensional arrays.
%   It allows you to find unique slices of an array of arbitrary
%   dimensionality. For 1D and 2D arrays, uniqueSlices(A, 1, setOrder) is
%   equivalent to unique(A, sortOrder, 'rows'), and will produce the same
%   output.
%
% See also: unique
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Handle argument defaults
if ~exist('setOrder', 'var') || isempty(setOrder)
    setOrder = 'sorted';
end

% Create list of slice dimensions
otherDims = 1:ndims(A);
otherDims(dim) = [];

% Record original array size
arraySize = size(A);

% Shuffle dimension order of A so that the slice dimension is axis 1
A = permute(A, [dim, otherDims]);
% Flatten slices so each slice is now a 1D row, making A into a 2D array
A = reshape(A, [arraySize(dim), prod(arraySize(otherDims))]);
% Find unique rows
[C, ia, ic] = unique(A, setOrder, 'rows');
% Reshape slices into their original size
C = reshape(C, [size(C, 1), arraySize(otherDims)]);
% Unshuffle the dimension order so that the slice dimension back in its
% original spot
C = ipermute(C, [dim, otherDims]);