function [cropped_mask, xlimits, ylimits] = cropMask(mask, pad)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cropMask: Crop the 2D mask to the bounding box containing true values
% usage:  cropped_mask = cropMask(mask)
%         [cropped_mask, xlimits, ylimits] = cropMask(mask)
%
% where,
%    mask is a 2D logical array, or a 3D (N x H x W) stack of 2D logical
%       arrays.
%    cropped_mask is a 2D logical array containing only the smallest region 
%       of "mask" hat contains true values, or a 3D stack of 2D logical
%       arrays, containing the smallest region that encompasses the true
%       values in any stack slice.
%    xlimits is a 1x2 vector containing the minimum and maximum x
%       coordinates of true values within the mask.
%    ylimits is a 1x2 vector containing the minimum and maximum y
%       coordinates of true values within the mask.
%    pad is an optional integer indicating how much extra mask to take
%       around the edge of the cropped region. If the padding overlaps the 
%       edge of the mask, then less padding will be produced. Default is no
%       padding.
%
% <long description>
%
% See also: <related functions>
%
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('pad', 'var') || isempty(pad)
    pad = 0;
end

% Find the minimum and maximum coordinates for the true values along each
% axis.
[xlimits, ylimits] = getMaskLim(mask, pad);

if isempty(xlimits) || isempty(ylimits)
    cropped_mask = [];
    return 
end

switch ndims(mask)
    case 2
        cropped_mask = mask(xlimits(1):xlimits(2), ylimits(1):ylimits(2));
    case 3
        cropped_mask = mask(:, xlimits(1):xlimits(2), ylimits(1):ylimits(2));
    otherwise
        error('Mask must be a 2D or 3D logical array.');
end