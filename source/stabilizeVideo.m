function stabilizedVideoData = stabilizeVideo(videoData, stationaryX, stationaryY, crop)

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
xRange = xMax - xMin;
yRange = yMax - yMin;
xMid = round((xMin + xMax)/2);
yMid = round((yMin + yMax)/2);

videoSize = size(videoData);

% Generate blank video data to hold output
stabilizedVideoData = zeros(videoSize, class(videoData));

h = size(videoData, 1);
w = size(videoData, 2);

x1s = zeros([1, numFrames]);
x2s = zeros([1, numFrames]);
y1s = zeros([1, numFrames]);
y2s = zeros([1, numFrames]);

for frameNum = 1:numFrames
    dx = xMid - stationaryX(frameNum);
    dy = yMid - stationaryY(frameNum);

    if color
        [shiftedFrame, x1, y1, x2, y2] = shiftFrame(squeeze(videoData(:, :, :, frameNum)), dx, dy);
        stabilizedVideoData(y1:y2, x1:x2, :, frameNum) = shiftedFrame;
    else
        [shiftedFrame, x1, y1, x2, y2] = shiftFrame(squeeze(videoData(:, :, frameNum)), dx, dy);
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
end

function [shiftedFrame, x1, y1, x2, y2] = shiftFrame(frame, dx, dy)
[h, w] = size(frame);
x1 = max(1, 1 + dx);
y1 = max(1, 1 + dy);
x2 = min(w, w + dx);
y2 = min(h, h + dy);
if ndims(frame) == 2
    shiftedFrame = frame(max(1, 1-dy):min(h, h-dy), max(1, 1-dx):min(w, w-dx));
else
    shiftedFrame = frame(max(1, 1-dy):min(h, h-dy), max(1, 1-dx):min(w, w-dx), :);
end