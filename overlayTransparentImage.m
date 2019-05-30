function compositeImage = overlayTransparentImage(image, overlayImage, color)
% overlayTransparentImage: create an overlay image using an input image and a mask
% usage:  overlayImage = overlayTransparentImage(im, mask, 'green', 0.5)
%
% where,
%    image is an array that represents a 2D image. It can be grayscale 
%       (NxM) or color (NxMx3). If it is a double array, it must be in the
%       range [0, 1].
%    overlayImage is an array that represents 2D transparency values with 
%       the same size as the image. The color, given by the "color"
%       argument will be overlaid onto the image with the transparency
%       given by the overlayImage array. overlayImage must be a double
%       array in the range [0, 1].
%    color is a color value to use to overlay the overlayImage. It can be
%       specified as a 0-1 RGB triplet (like [0.2, 0.7, 0.9]), a color name 
%       (like 'pale green'), or a matlab color character (like 'b')
%    compositeImage is the output array representing an RGB image 
%       consisting of the original image composited with the overlay image
%       as the alpha channel for a given color foreground
%
% overlayMask takes a 2D image and a 2D overlay image and combines them
%   using a given color and transparency.
%
% See also: overlayMask

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

% Check that dimensions of image and overlayMask are appropriate
if ndims(overlayImage) ~= 2
    error(['overlayMask must be 2D. Instead, overlayMask was ', num2str(ndims(overlayImage)),'D'])
end
switch ndims(image)
    case 2
        if ~all(size(image) == size(overlayImage))
            [a, b] = size(image);
            [a2, b2] = size(overlayImage);
            error(['If image is NxM, overlay mask must also have dimensions of NxM. Instead, image had dimensions ', a, 'x', b, ' and overlayMask had size ', a2, 'x', b2]);
        end
    case 3
        [a, b, c] = size(image);
        [a2, b2] = size(overlayImage);
        if c ~= 3
            error(['If image is 3D, the third dimension must have size 3. Instead, image was ', a, 'x', b, 'x', c]);
        end
        if a ~= a2 || b ~= b2
            error(['If image is NxMx3, overlayMask must be NxM. Instead, image was ', a, 'x', b, 'x', c, ' and overlayMask was ', a2, 'x', b2]);
        end
end

% Check that transparency is in [0, 1]
if any(overlayImage(:) < 0) || any(overlayImage(:) > 1)
    error('overlayImage must be in the range [0, 1]')
end
if ~strcmp(class(overlayImage), 'double')
    error('overlayImage must be of the type double')
end
% Convert color input to an RGB triplet
color = rgb(color);

originalImageClass = class(image);
% Cast image to double
image = double(image);
overlayImage3 = cat(3, overlayImage*color(1), overlayImage*color(2), overlayImage*color(3));
if length(size(image)) == 2
    image = cat(3, image, image, image);
end

compositeImage = overlayImage3 + image.*(1-overlayImage3);

cast(compositeImage, originalImageClass);
disp('done')
