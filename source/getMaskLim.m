function [xlimits, ylimits] = getMaskLim(mask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get3MaskLim: Get the smallest bounding box containing all true values
% usage:  [xlimits, ylimits, zlimits] = get3MaskLim(mask)
%
% where,
%    mask is a 2D logical array
%    xlimits is a 1x2 vector containing the minimum and maximum x
%       coordinates of true values within the mask.
%    ylimits is a 1x2 vector containing the minimum and maximum y
%       coordinates of true values within the mask.
%    zlimits is a 1x2 vector containing the minimum and maximum z
%       coordinates of true values within the mask.
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

% Generate 3D coordinate index lists based on the flattened 1D indices of 
% the true values
[x, y] = ind2sub(size(mask), find(mask > 0));

% Find the minimum and maximum coordinates for the true values along each
% axis.
xlimits = [min(x), max(x)];
ylimits = [min(y), max(y)];