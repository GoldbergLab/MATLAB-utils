function newVideoData = addVideoSyncTags(videoPathIn, videoPathOut, bitXs, bitYs, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addVideoSyncTags: Add synchronization tags to a video
% usage: newVideoData = addVideoSyncTags(videoPathIn, videoPathOut, bitXs, 
%                           bitYs, options)
%
% where,
%    videoPathIn is a path to an input video
%    videoPathOut is a path to the output video to save
%    bitXs is one or more pixel X-values for where to put the sync tags
%    bitYs is one or more pixel Y-values for where to put the sync tags
%    Name/Value pairs can include:
%       EnlargedSize
%       BitRadius
%       BackgroundRadius
%       ProgressBar
%    newVideoData is the sync tagged video as a 4D array
%
% This video adds synchronization tags to a video so a photodetector 
%   mounted to the screen can record frame changes precisely. It's possible
%   to add an arbitrary number of sync tags to each frame; each sync tag 
%   displays one bit of the frame number.
% Sync tags are black filled circles with either a white or black circle
%   inside to represent a 1 or a 0 bit.
% bitXs and bitYs define the X and Y coordinates of each bit of the sync
%   tag circle centers. For convenience, if one of these is a vector, and 
%   the other is a scalar, the scalar one is repeated to match the length 
%   of the vector one.
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    videoPathIn {mustBeText}
    videoPathOut {mustBeText}
    bitXs double = [31, 88, 145, 202]
    bitYs double = 40
    options.EnlargedSize = []   % width x height
    options.BitRadius = 20;
    options.BackgroundRadius = 35;
    options.ProgressBar = false
end

% Load the video data as a 4D array
videoData = loadVideoData(videoPathIn, false);
disp("Done loading video.")

% Check that video is 4D, not 3D
if ndims(videoData) ~= 4
    error("This video does not appear to be in color. At the moment, addVideoSyncTag only works with color video");
end

% Get current shape of video
[H, W, C, N] = size(videoData);
if C ~= 3
    error('Video must have three color channels');
end

% If user passed a non-empty value for EnlargedSize, pad the border of the
%   video to match the desired size.
if ~isempty(options.EnlargedSize)
    if ~isvector(options.EnlargedSize) || length(options.EnlargedSize) ~= 2
        error('EnlargedSize must be a 2-long vector')
    end
    eW = options.EnlargedSize(1);
    eH = options.EnlargedSize(2);
    if eW < W || eH < H
        error('EnlargedSize must be greater than or equal to the current video size');
    end
    % Determine how much padding is necessary
    padX = eW - W;
    padY = eH - H;
    padLeft = floor(padX / 2);
    padTop = floor(padY / 2);
    % Create a larger array to hold the enlarged video
    newVideoData = zeros([eH, eW, C, N]);
    % Place the video in the correct place in the larger array
    newVideoData(padTop:padTop+H-1, padLeft:padLeft+W-1, :, :) = videoData;
else
    % No enlargement requested
    newVideoData = videoData;
end

% Determine how many bits user requests
nBits = max(length(bitXs), length(bitYs));
% If x value is scalar, repeat it
if isscalar(bitXs)
    bitXs = repmat(bitXs, [1, nBits]);
end
% If y value is scalar, repeat it
if isscalar(bitYs)
    bitYs = repmat(bitYs, [1, nBits]);
end

% Get bit bounding box (faster to only operate on bounding box than whole frame)
r = max(options.BitRadius, options.BackgroundRadius);
minX = max(round(min(bitXs) - r), 1);
maxX = min(round(max(bitXs) + r), W);
minY = max(round(min(bitYs) - r), 1);
maxY = min(round(max(bitYs) + r), H);
% Display a progress bar
if options.ProgressBar
    pb = ProgressBar('Adding sync tags to video...');
end
for f = 1:N
    if options.ProgressBar
        pb.Progress = f/N;
        drawnow();
    end
    % Draw black backgrounds
    for k = 1:nBits
        newVideoData(minY:maxY, minX:maxX, :, f) = drawCircle(newVideoData(minY:maxY, minX:maxX, :, f), bitXs(k)-minX, bitYs(k)-minY, options.BackgroundRadius, 0);
    end
    % Draw white on bits
    bitValues = bitget(f, 1:nBits);
    for k = 1:nBits
        if bitValues(k)
            newVideoData(minY:maxY, minX:maxX, :, f) = drawCircle(newVideoData(minY:maxY, minX:maxX, :, f), bitXs(k)-minX, bitYs(k)-minY, options.BitRadius, 255);
        end
    end
end
if options.ProgressBar
    delete(pb);
end

disp('Saving video...');
saveVideoData(newVideoData, videoPathOut);
disp('...done saving video');

function imageData = drawCircle(imageData, x, y, r, c)
% drawCircle  Draw a circle outline into a color image.
%
%   imgOut = drawCircle(img, x, y, r, c)
%
% Inputs
%   img : 2D grayscale image
%   x   : horizontal center coordinate (column)
%   y   : vertical center coordinate (row)
%   r   : circle radius, in pixels
%   c   : value to write to all color channels
%
% Output
%   imgOut : image with circle drawn
%
% Notes
%   - Circles extending beyond the image boundary are clipped safely.
%   - x and y may be non-integers.
%   - This draws a 1-pixel-ish outline, not a filled disk.

    if ~isscalar(x) || ~isscalar(y) || ~isscalar(r) || ~isscalar(c)
        error('x, y, r, and c must be scalars.');
    end
    if r < 0
        error('r must be nonnegative.');
    end

    % Bounding box, clipped to image limits
    [nRows, nCols, ~] = size(imageData);
    colMin = max(1, floor(x - r - 1));
    colMax = min(nCols, ceil(x + r + 1));
    rowMin = max(1, floor(y - r - 1));
    rowMax = min(nRows, ceil(y + r + 1));

    if colMin > colMax || rowMin > rowMax
        return;
    end

    [X, Y] = meshgrid(colMin:colMax, rowMin:rowMax);
    D = sqrt((X - x).^2 + (Y - y).^2);

    % Pixels near the target radius become the circle
    mask = repmat(abs(D) <= r, [1, 1, 3]);

    subImg = imageData(rowMin:rowMax, colMin:colMax, :);
    subImg(mask) = c;
    imageData(rowMin:rowMax, colMin:colMax, :) = subImg;
