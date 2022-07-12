function [cropped_mask, xlimits, ylimits, zlimits] = crop3Mask(mask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% crop3Mask: Crop the 3D mask to the bounding box containing true values
% usage:  cropped_mask = crop3Mask(mask)
%         [cropped_mask, xlimits, ylimits, zlimits] = crop3Mask(mask)
%
% where,
%    mask is a 3D logical array
%    cropped_mask is a 3D logical array containing only the smallest region 
%       of "mask" hat contains true values
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

% Find the minimum and maximum coordinates for the true values along each
% axis.
[xlimits, ylimits, zlimits] = get3MaskLim(mask);
cropped_mask = mask(xlimits(1):xlimits(2), ylimits(1):ylimits(2), zlimits(1):zlimits(2));