function overlay = compareMaskOverlays(image, mask1, mask2, color, transparency, origin)

if ~exist('origin', 'var') || isempty(origin)
    origin = [1, 1];
end

overlay1 = overlayMask(image, mask1, color, transparency, origin);
overlay2 = overlayMask(image, mask2, color, transparency, origin);
original = overlayMask(image, mask1*0, color, transparency, origin);

horizontal_dimension = ndims(overlay1)-1;

overlay = cat(horizontal_dimension, overlay1, original, overlay2);
