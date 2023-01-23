function saveVideoData(videoData, filename, varargin)

if nargin >=3 && ~isempty(varargin{1})
    videoType = varargin{1};
else
    if ndims(videoData) == 3
        videoType = 'Grayscale AVI';
    elseif ndims(videoData) == 4
        videoType = 'Uncompressed AVI';
    end
end

if nargin >= 4
    fps = varargin{2};
else
    fps = 30;
end

v = VideoWriter(filename, videoType);
v.FrameRate = fps;
open(v);
videoSize = size(videoData);
% for k = 1:videoSize(3)
%     writeVideo(v, videoData(:, :, k));
% end
if isa(videoData, 'double') && max(videoData(:)) > 1
    videoData = uint8(videoData);
end
if ndims(videoData) == 3
    videoSizeAdjusted = [videoSize(1:2), 1, videoSize(3)];
else
    videoSizeAdjusted = videoSize;
end
videoData = reshape(videoData, videoSizeAdjusted);
writeVideo(v, videoData);
close(v);