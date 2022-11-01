function mask = createCircleMask(radius)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% createCircleMask: Generate a logical mask with a circle pattern
% usage:  mask = createCircleMask(radius)
%
% where,
%    radius is an integer specifying the radius of the circle. The
%       resulting mask will be a square with side length = 2 * radius + 1
%    mask is a square 2D logical mask with side length = 2 * radius + 1
%
% Create a square mask with a circular pattern of true values with the
%   specified radius.
%
% See also: plotMask
%
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

w = 2*radius + 1;
mask = false(w);
[x, y] = ind2sub(size(mask), 1:(w*w));
idx = round((x - (radius + 1)) .^ 2 + (y - (radius + 1)) .^ 2) <= radius*radius;
mask(idx) = true;
