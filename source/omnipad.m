function array = omnipad(array, padSize, padVal, direction)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% omnipad: A modified version of padarray that accepts negative pad sizes
% usage:  paddedArray = omnipad(array, padSize)
% usage:  paddedArray = omnipad(array, padSize, padVal)
% usage:  paddedArray = omnipad(array, padSize, padVal, direction)
%
% where,
%    paddedArray is the padded output array
%    array is an N-D array
%    padSize is an 1xM vector, where M <= N, representing the size of the
%       padding for each dimension. If M < N, any dimensions numbered
%       greater than M will be left unpadded. Negative numbers will reverse
%       the direction of the padding. For example, if direction is 'pre',
%       and one of the values in padSize is negative, that particular
%       dimension will be applied as if direction were 'post'.
%    direction is either 'pre', 'post', or (default) 'both', indicating
%       which side of the array to pad, modified by the sign of each
%       element of padSize.
%
% This is a wrapper for the MATLAB builtin padsize that allows and sensibly
%   handles negative elements of the padSize array. Negative values will 
%   reverse the direction of the padding. For example, if direction is 
%   'pre', and one of the values in padSize is negative, that particular
%   dimension will be applied as if direction were 'post'. Otherwise, the
%   behavior should be the same as padarray.
%
% See also: padarray
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('padVal', 'var') || isempty(padVal)
    padVal = 0;
end
if ~exist('direction', 'var') || isempty(direction)
    direction = 'both';
end

negativePadSize = padSize;
negativePadSize(padSize>0) = 0;
negativePadSize = abs(negativePadSize);
positivePadSize = padSize;
positivePadSize(padSize<0) = 0;
positivePadSize = abs(positivePadSize);

switch direction
    case 'pre'
        array = padarray(array, negativePadSize, padVal, 'post');
        array = padarray(array, positivePadSize, padVal, 'pre');
    case 'post'
        array = padarray(array, negativePadSize, padVal, 'pre');
        array = padarray(array, positivePadSize, padVal, 'post');
    case 'both'
        array = padarray(array, abs(padSize), padVal, 'both');
end