function [xlimits, ylimits] = getMaskLim(mask, pad)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getMaskLim: Get the smallest bounding box containing all true values
% usage:  [xlimits, ylimits] = getMaskLim(mask)
%
% where,
%    mask is either
%       - a 2D logical array
%       - a 3D (N x H x W) stack of 2D logical arrays
%       If a stack of masks is provided, the smallest xlimits and ylimits
%       that enclose every true value in every slice is found.
%    xlimits is a 1x2 vector containing the minimum and maximum x
%       coordinates of true values within the mask.
%    ylimits is a 1x2 vector containing the minimum and maximum y
%       coordinates of true values within the mask.
%    pad is an optional integer indicating how much extra mask to take
%       around the edge of the true region. If the padding overlaps the 
%       edge of the mask, then less padding will be produced. Default is no
%       padding.
%
% Get the smallest bounding box containing all true values, with optional
%   padding.
%
% See also: cropMask, plotMask, get3MaskLim
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if default pad value is needed
if ~exist('pad', 'var') || isempty(pad)
    pad = 0;
end

if ndims(mask) == 3
    mask = squeeze(any(mask, 1));
end

% Generate 2D coordinate index lists based on the flattened 1D indices of 
% the true values
[x, y] = ind2sub(size(mask), find(mask > 0));

% Find the minimum and maximum coordinates for the true values along each
% axis.
xlimits = [min(x), max(x)];
ylimits = [min(y), max(y)];

if pad ~= 0
    % Pad limits
    xlimits = xlimits + [-pad, pad];
    ylimits = ylimits + [-pad, pad];

    % Ensure limits do not exceed boundaries of mask
    xlimits(1) = max(1, xlimits(1));
    ylimits(1) = max(1, ylimits(1));
    xlimits(2) = min(size(mask, 1), xlimits(2));
    ylimits(2) = min(size(mask, 2), ylimits(2));
end
