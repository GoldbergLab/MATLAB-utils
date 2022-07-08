function mask = coordsTo3Mask(maskSize, x, y, z)

if ~exist('maskSize') || isempty(maskSize)
    maskSize = [max(x), max(y), max(z)];
end
I = sub2ind(maskSize, x, y, z);

mask = false(maskSize);
mask(I) = true;