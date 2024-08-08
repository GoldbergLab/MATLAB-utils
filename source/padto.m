function B = padto(A, padtosize, padval, direction)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% padto: Pad an array up to the given size
% usage:  [B] = padto(A, padtosize, padval, direction)
%
% where,
%    A is an input array
%    padtosize is the desired output array size with padding
%    padval is a value to pad with, or 'circular', 'replicate', or
%       'symmetric' (see padarray documentation)
%    direction is 'both' (default), 'pre', or 'post' (see padarray
%       documentation)
%    B is the output array
%
% This function behaves like padarray, but instead of providing the amount
%   to pad the array with, you can supply the desired final size of the
%   array after padding.
%
% See also: padarray, omnipad
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    A
    padtosize
    padval
    direction {mustBeMember(direction, {'both', 'post', 'pre'})} = 'both'
end

arraySize = size(A);

switch direction
    case 'pre'
        prePadSize = padtosize - arraySize;
        postPadSize = zeros(size(padtosize));
    case 'post'
        prePadSize = zeros(size(padtosize));
        postPadSize = padtosize - arraySize;
    case 'both'
        prePadSize = ceil((padtosize - arraySize)/2);
        postPadSize = floor((padtosize - arraySize)/2);
end

if any(prePadSize)
    A = padarray(A, prePadSize, padval, 'pre');
end
if any(postPadSize)
    A = padarray(A, postPadSize, padval, 'post');
end

B = A;