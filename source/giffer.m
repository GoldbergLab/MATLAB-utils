function giffer(videoFileNameOrData, gifFileName, varargin)
% Create gif from a video file or data
% crop: optional = [x0, y0, f0, w, h, N]
%   x0 = upper left crop X
%   y0 = upper left crop Y
%   f0 = starting frame
%   w = crop width
%   h = crop height
%   N = number of frames
%   For any of these, use NaN to indicate fullest range of 
% stride = number of frames to skip over for each frame
% delay = delay between frames in seconds
% scale = scale factor to apply at the end. 1 = unchanged
if ischar(videoFileNameOrData)
    videoData = loadVideoData(videoFileNameOrData);
else
    videoData = videoFileNameOrData;
end
videoSize = size(videoData);
if nargin > 2 && ~isempty(varargin{1})
    crop = varargin{1};
else
    crop = [NaN, NaN, NaN, NaN, NaN, NaN];
end
if nargin > 3
    stride = varargin{2};
else
    stride = 1;
end
if nargin > 4
    delay = varargin{3};
else
    delay = 0.05;
end
if nargin > 5
    scale = varargin{4};
else
    scale = 1;
end
fullStart = [1, 1, 1];
fullStop = videoSize;
start = crop(1:3);
startTemp = start; startTemp(isnan(startTemp)) = 1;
stop = startTemp + crop(4:6);
start(isnan(start)) = fullStart(isnan(start));
stop(isnan(stop)) = fullStop(isnan(stop));

videoData = videoData(start(1):stop(1), start(2):stop(2), start(3):stride:stop(3));
[newW, newH, newN] = size(videoData);
if scale ~= 1
    videoData = imresize3(videoData, [newW*scale, newH*scale, newN]);
end
[newW, newH, newN] = size(videoData);
videoData = reshape(videoData, [newW, newH, 1, newN]);
imwrite(videoData, gifFileName, 'DelayTime', delay, 'LoopCount', Inf);