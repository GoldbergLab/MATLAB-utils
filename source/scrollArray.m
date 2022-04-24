function scrolledArray = scrollArray(array, steps, rate, padVal, offset, window)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <function name>: <short description>
% usage:  [<output args>] = <function name>(<input args>)
%
% Produce a "scrolled" version of an array
%
% where,
%    <arg1> is <description>
%    <arg2> is <description>
%    <argN> is <description>
%    array is an N-dimensional array
%    rate is a scalar or 1xN array representing how much to shift array per
%       step. If scalar, array will be shifted along first dimension. The
%       rate can have non-integer values, in which case the best
%       approximation of integer shifts will be made.
%    steps is the number of steps to shift
%    padVal is the value to fill array in with where the array is partly 
%       out of "view"
%    offset is a scalar or 1xN array representing an initial array offset.
%       offset must either be a scalar or have the same shape as rate.
%    scrolledArray is an (N+1) dimensional array. If array is of size 
%       [a, b, ... n], scrolledArray will have size [a, b, ..., n, steps],
%       unless array was a vector, in which case the singleton dimension 
%       will be the dimension in which the stacking will occur.
%
% This function "scrolls" an array, producing a stacked scrolled version
%   of the array. For example:
%
%   >> scrollArray([1, 2, 3, 4], 5)
%
%   ans =
%
%       1     2     3     4
%       0     1     2     3
%       0     0     1     2
%       0     0     0     1
%       0     0     0     0
%
%   >> scrollArray([1, 2, 3, 4], 5, [0, 0.5])
%
%   ans =
%
%       1     2     3     4
%       1     2     3     4
%       0     1     2     3
%       0     1     2     3
%       0     0     1     2
%
% It works in an analogous way for arbitary dimensional arrays. Each layer 
%   is produced similarly to circshift, except instead of circularly 
%   shifting an array so values that fall off the end and wrap around to 
%   the beginning, values that are pushed off the array are truncated, and
%   new space in the array is filled with padVal.
% The original purpose of this function was to produce "scrolling" videos
%   of an image, so the image "scrolled" past the viewer.
%
% See also: circshift, padarray
%
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Figure out which dimension the array should get stacked on
if length(size(array)) == 2
    % This is either a scalar, a vector, or a 2D matrix. If it's a scalar 
    %   or a vector, one of the two dimensions will have length 1. In that
    %   case, it's natural to stack on the first singleton dimension
    %   If neither dimension has length 1, so it's a 2D array, and we
    %   should stack on the 3rd dimension.
    stackDim = find(size(array)==1, 1, 'first');
    if isempty(stackDim)
        % It's a 2D array
        stackDim = length(size(array)) + 1;
        defaultRateDim = 1;
    else
        % It's a scalar or vector
        defaultRateDim = 3-stackDim;
    end
else
    % This is an N-dimensional array (N > 2) - just stack on the N+1
    %   dimension.
    stackDim = length(size(array)) + 1;
    defaultRateDim = 1;
end

if ~exist('offset', 'var') || isempty(offset)
    offset = 0;
end
if ~exist('padVal', 'var') || isempty(padVal)
    padVal = 0;
end
if ~exist('rate', 'var') || isempty(rate)
    rate = zeros([1, defaultRateDim]);
    rate(defaultRateDim) = 1;
end
if ~exist('window', 'var') || isempty(window)
    window = size(array);
end

scrolledArray = [];
for k = 0:steps-1
    shift = floor(rate*k + offset);
    % Pad array to shift the array at the desired rate
    paddedArray = padarray(array, abs(shift), padVal, 'post');
    % Shift array so it moves in the correct direction
    paddedArray = circshift(paddedArray, shift);
    % Slice the excess off the end of the array
    paddedArray = multiSlice(paddedArray, ones(size(size(array))), window);
    % Stack the shifted array on the end of the output array
    scrolledArray = cat(stackDim, scrolledArray, paddedArray);
end

function array = multiSlice(array, start, stop)
idx = arrayfun(@(a, b)a:b, start, stop, 'UniformOutput', false);
array = array(idx{:});