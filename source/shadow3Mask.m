function shadowed_mask = shadow3Mask(mask, axis, direction)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% shadow3Mask: Project the true values of a 3D mask in a direction
% usage:  shadowed_mask = shadow3Mask(mask, direction, side)
%
% where,
%    mask is a 3D logical array.
%    axis is either 1, 2, or 3, indicating which dimension the "shadow"
%       should be projected into.
%    direction is either -1, 0, or 1, indicating that the "shadow" should 
%       be projected either in the negative direction, positive direction,
%       or both directions. Default is 0.
%
% Take a 3D logical mask and project the true values along a specified, as
%   though they were casting a "shadow".
%
% See also: plot3Mask
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('direction', 'var') || isempty(direction)
    direction = 0;
end

% For convenience, permute mask so shadow axis is axis #1
permutation = 1:3;
permutation(1) = axis;
permutation(axis) = 1;
mask = permute(mask, permutation);

if direction == 0
    shadow = any(mask);
    reps = ones(1, 3);
    reps(1) = size(mask, 1);
    shadowed_mask = repmat(shadow, reps);
elseif direction == 1 || direction == -1
    order = 1:size(mask, 1);
    if direction == -1
        order = flip(order);
    end
    shadow = mask(1, :, :);
    shadowed_mask = false(size(mask));
    for c = order
        shadow = shadow | mask(c, :, :);
        shadowed_mask(c, :, :) = shadow;
    end
else
    error('direction argument must be -1, 0, or 1, not %s', direction);
end

% Un-permute mask 
shadowed_mask = permute(shadowed_mask, permutation);
