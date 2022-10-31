function [boundary_mask, filled_mask, xyConnected] = drawMaskPolygon(xy, mask_size, fillMask)

% Get coordinates of polygon 
xyConnected = calculateMaskPolygon(xy);
boundaryIdx = sub2ind(mask_size, xyConnected(:, 1), xyConnected(:, 2));
% Create a blank mask
boundary_mask = false(mask_size);
% Place polygon on mask
boundary_mask(boundaryIdx) = true;
% Fill mask
if fillMask
    filled_mask = imfill(boundary_mask, round(mean(xy, 1)));
else
    filled_mask = [];
end