function [stabilizedVideoData, dx, dy] = stabilizeVideo(videoData, stationaryX, stationaryY, crop)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stabilizeVideo: Stabilize a video with an array of stationary coordinates
% usage:  stabilizedVideoData = stabilizeVideo(videoData, stationaryX, stationaryY, crop)
%
% where,
%    videoData is a 3D (H x W x N) or 4D (H x W x 3 x N) array representing
%       video data
%    stationaryX is a 1D (1 x N) array of x coordinates for a stationary
%       marker
%    stationaryY is a 1D (1 x N) array of y coordinates for a stationary
%       marker
%    crop is an optional boolean flag indicating whether or not to crop the
%       video after stabilizing. If false, there will be black regions
%       around the edge of the frames. If true, there will be no black
%       regions, but the output frame size will be smaller than the 
%       original. Default is true.
%
% Motion stabilize a video. By providing the x and y coordinates of a
%   marker in a video, the video's frame locations can be adjusted so the
%   marker position does not change throughout the video.
%
% See also: loadVideoData
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if we need default crop value
if ~exist('crop', 'var') || isempty(crop)
    crop = true;
end

% Check validity of inputs
assert(any(ndims(videoData) == [3, 4]), 'Video data must be a 3D (H x W x N) or 4D (H x W x C x N) array.');
if ndims(videoData) == 4
    numFrames = size(videoData, 4);
    color = true;
    assert(size(videoData, 3) == 3, 'If video data is a 4D array, the 3rd axis must be a color channel with length 3');
    assert(numFrames == length(stationaryX), 'Stationary coordinate array lengths must match the number of frames in the video');
else
    numFrames = size(videoData, 3);
    color = false;
    assert(numFrames == length(stationaryX), 'Stationary coordinate array lengths must match the number of frames in the video');
end
assert(isvector(stationaryX) && isvector(stationaryY), 'Stationary coordinate arrays must be 1D');
assert(length(stationaryX) == length(stationaryY), 'Stationary coordinate arrays must be the same length');

% Determine size of output video
xMin = min(stationaryX);
xMax = max(stationaryX);
yMin = min(stationaryY);
yMax = max(stationaryY);
xMid = round((xMin + xMax)/2);
yMid = round((yMin + yMax)/2);

videoSize = size(videoData);

% Generate blank video data to hold output
stabilizedVideoData = zeros(videoSize, class(videoData));

x1s = zeros([1, numFrames]);
x2s = zeros([1, numFrames]);
y1s = zeros([1, numFrames]);
y2s = zeros([1, numFrames]);

dx = zeros([1, numFrames]);
dy = zeros([1, numFrames]);

% Loop over each frame and offset its position to stabilize the marker.
for frameNum = 1:numFrames
    dx(frameNum) = xMid - stationaryX(frameNum);
    dy(frameNum) = yMid - stationaryY(frameNum);

    if color
        [shiftedFrame, x1, y1, x2, y2] = shiftFrame(squeeze(videoData(:, :, :, frameNum)), dx(frameNum), dy(frameNum));
        stabilizedVideoData(y1:y2, x1:x2, :, frameNum) = shiftedFrame;
    else
        [shiftedFrame, x1, y1, x2, y2] = shiftFrame(squeeze(videoData(:, :, frameNum)), dx(frameNum), dy(frameNum));
        stabilizedVideoData(y1:y2, x1:x2, frameNum) = shiftedFrame;
    end
    x1s(frameNum) = x1;
    y1s(frameNum) = y1;
    x2s(frameNum) = x2;
    y2s(frameNum) = y2;
end

if crop
    % Crop edges of stabilized video
    if color
        stabilizedVideoData = stabilizedVideoData(max(y1s):min(y2s), max(x1s):min(x2s), :, :);
    else
        stabilizedVideoData = stabilizedVideoData(max(y1s):min(y2s), max(x1s):min(x2s), :);
    end

    dx = dx - max(x1s) + 1;
    dy = dy - max(y1s) + 1;
end

function [shiftedFrame, x1, y1, x2, y2] = shiftFrame(frame, dx, dy)
% Shift a single frame by the requested amount, and return it, along with
%   the upper left and lower right coordinates of the resultant shifted 
%   frame.
[h, w] = size(frame,[1,2]);
x1 = max(1, 1 + dx);
y1 = max(1, 1 + dy);
x2 = min(w, w + dx);
y2 = min(h, h + dy);
if ndims(frame) == 2
    shiftedFrame = frame(max(1, 1-dy):min(h, h-dy), max(1, 1-dx):min(w, w-dx));
else
    shiftedFrame = frame(max(1, 1-dy):min(h, h-dy), max(1, 1-dx):min(w, w-dx), :);
end