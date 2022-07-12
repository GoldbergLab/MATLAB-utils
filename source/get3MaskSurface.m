function surface_mask = get3MaskSurface(mask, kernel)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get3MaskSurface: Isolate the true voxels on the surface of true regions
% usage:  surface_mask = get3MaskSurface(mask)
%         surface_mask = get3MaskSurface(mask, kernel)
%
% where,
%    mask is a 3D logical mask
%    kernel is an optional argument indicating what convolution kernel to
%       use for counting neighbors. If not supplied, the default kernel
%       will count any voxel as a neighbor if it lies within a 3x3x3 cube 
%       centered on the voxel in question.
%    surface_mask is a 3D logical mask for which the true voxels are the
%       subset of true voxels in the original mask which are on the surface
%       of true regions.
%
% This function creates a new 3D mask for which vodels are true if they are
%   true in the original mask, and have at least one false neighbor in the
%   original mask. The result is a mask of only the "surfaces" of true
%   regions. With the default kernel, the surface finding algorithm is 
%   stable, in that applying it more than once iteratively has no 
%   additional effect; the surface of a surface mask is the surface mask itself.
%
% See also: plot3Mask
%
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('kernel', 'var') || isempty(kernel)
    % Create a neighbor-counting convolution kernel
    kernel = ones([3, 3, 3]);
    kernel(2, 2, 2) = 0;
end

% For speed, crop mask to the region containing true values
[cropped_mask, xlimits, ylimits, zlimits] = crop3Mask(mask);

% Convolve kernel to determine how many true neighbors each voxel has
n = convn(cropped_mask, kernel, 'same');

% A surface voxel is any voxel that is itself true, and has less then the 
%   max possible # of true neighbors.
cropped_surface_mask = cropped_mask & (n < sum(kernel, 'all'));

% Reconstitute surface mask into full size of original mask.
surface_mask = zeros(size(mask));
surface_mask(xlimits(1):xlimits(2), ylimits(1):ylimits(2), zlimits(1):zlimits(2)) = cropped_surface_mask;