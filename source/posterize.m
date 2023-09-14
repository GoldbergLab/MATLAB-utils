function imageOut = posterize(imageIn, numColors)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% posterize: Reduce the number of unique colors in an image
% usage:  imageOut = posterize(imageIn, numColors)
%
% where,
%    imageIn is a 3D (HxWxC) array representing an RGB image
%    numColors is a positive integer indicating how many unique colors the 
%       output image should have.
%    imageOut is a 3D array with the same dimensions as imageIn
%       representing a posterized version of imageIn
%
% See https://en.wikipedia.org/wiki/Posterization
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Record the original image's numerical class
originalClass = class(imageIn);

% Get the size of the image
[H, W, nChan] = size(imageIn);

% Flatten the image into a list of pixel RGBs
flatImage = double(reshape(imageIn, [H*W, nChan]));

% Cluster the pixels
[idx, C] = kmeans(flatImage, numColors, 'Distance', 'cityblock');

% Reconstitute a posterized image using the cluster centroids
imageOut = reshape(C(idx, :), [H, W, nChan]);

% Cast the resulting image back to the original numerical class.
imageOut = cast(imageOut, originalClass);
