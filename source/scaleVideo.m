function newVideoData = scaleVideo(videoData, scale)
% scaleVideo: Change the scale of each frame of a video
% usage:  resizedVideoData = scaleVideo(videoData, scale)
%
% where,
%    videoData is an array of size WxHxN representing an N-frame grayscale 
%       video with frames of size WxH
%    scale is a number representing the factor by which to scale the
%       frames. A number greater than one will make the frames larger, a
%       number less than one will make the frames smaller.
%    newVideoData is the video data after scaling by "scale"
%
% See also: loadVideoData, saveVideoData

% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

videoDataSize = size(videoData);
nFrames = videoDataSize(3);
oldFrameSize = videoDataSize(1:2);
newSize = ceil(oldFrameSize*scale);
newVideoData = zeros([newSize, nFrames]);

for k = 1:nFrames
    newVideoData(:, :, k) = imresize(videoData(:, :, k), scale);
end