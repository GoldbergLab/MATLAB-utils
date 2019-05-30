function overlayImage = overlayMask(image, mask, color, transparency)
% overlayMask: create an overlay image using an input image and a mask
% usage:  overlayImage = overlayMask(im, mask, 'green', 0.5)
%
% where,
%    image is an array that represents a 2D image. It can be grayscale 
%       (NxM) or color (NxMx3). If it is a double array, it must be in the
%       range [0, 1].
%    overlayMask is an array that represents a 2D binary mask with the same
%       size as the image. If it is not a logical array, it will be
%       converted to one. Regions that are interpreted as logical "true"
%       will be overlaid on top of the image with the given color and
%       transparency
%    color is a color value to use to overlay the overlayMask. It can be
%       specified as a 0-1 RGB triplet (like [0.2, 0.7, 0.9]), a color name 
%       (like 'pale green'), or a matlab color character (like 'b')
%    transparency is a transparency value from 0 to 1 to use to overlay the
%       overlayMask
%
% overlayMask takes a 2D image and a 2D mask and overlays the 
%
% See also: <related functions>

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

% Check that dimensions of image and overlayMask are appropriate
if ndims(mask) ~= 2
    error(['overlayMask must be 2D. Instead, overlayMask was ', ndims(mask),'D'])
end
switch ndims(image)
    case 2
        if ~all(size(image) == size(mask))
            [a, b] = size(image);
            [a2, b2] = size(mask);
            error(['If image is NxM, overlay mask must also have dimensions of NxM. Instead, image had dimensions ', a, 'x', b, ' and overlayMask had size ', a2, 'x', b2]);
        end
    case 3
        [a, b, c] = size(image);
        [a2, b2] = size(mask);
        if c ~= 3
            error(['If image is 3D, the third dimension must have size 3. Instead, image was ', a, 'x', b, 'x', c]);
        end
        if a ~= a2 || b ~= b2
            error(['If image is NxMx3, overlayMask must be NxM. Instead, image was ', a, 'x', b, 'x', c, ' and overlayMask was ', a2, 'x', b2]);
        end
end

% Check that transparency is in [0, 1]
if transparency < 0 || transparency > 1
    error(['transparency must be in the range [0, 1]. Instead, transparency was ', transparency])
end

% Convert color input to an RGB triplet
color = rgb(color);

% Transform overlayMask to an appropriate data type with appropriate
% scaling for the image
mask = logical(mask);
switch class(image)
    case {'single', 'double'}
        maxVal = max(image(:));
        minVal = min(image(:));
        if minVal < 0 || maxVal > 1
            error(['Input image is of type double - its values must be in the range [0, 1]. Instead it had the range [', num2str(minVal), ', ', num2str(maxVal), ']'])
        end
        mask = 1*mask;
    case {'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}
        mask = cast(mask, class(image))*intmax(class(image));
    otherwise
        error(['image must be a numeric class. Instead, it was', class(image)]);
end
colorMask = cat(3, mask*color(1), mask*color(2), mask*color(3));

originalClass = class(image);
overlayImage = double(image)/(1+transparency) + double(colorMask)*transparency/(1+transparency);
overlayImage = cast(overlayImage, originalClass);
