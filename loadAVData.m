function avData = loadAVData(videoFilename, stdoutQueue)
if exist('stdoutQueue', 'var')
    pardisp = @(varargin)stdoutQueue.send(varargin{:});
else
    pardisp = @(varargin)disp(varargin{:});
end
%This currently works with grayscale avi and tif files
pardisp('Loading video')
video = VideoReader(videoFilename);
pardisp(video.VideoFormat);
videoData = read(video);

videoDataSize = size(videoData);
pardisp('video data size:')
pardisp(videoDataSize)

if length(videoDataSize) == 3
    % This must be a HxWxN single-channel video. Let's make it HxWx1xN for
    % code compatibility with HxWx3xN 3-channel videos.
    newSize = [videoDataSize(1:2), 1, videoDataSize(3)];
    videoData = reshape(videoData, newSize);
end

% if length(videoDataSize) == 4 && videoDataSize(3) == 1
%     % For some reason we have a singleton dimension - let's get rid of it
%     videoData = squeeze(videoData);
% end

pardisp('Loading audio')
audioData = audioread(videoFilename);

avData.Path = videoFilename;
avData.VideoData = videoData;
avData.AudioData = audioData;
%videoFReader = vision.VideoFileReader(videoFilename, 'AudioOutputPort', true);
%audioData = [];
%audioChunkSizes = [];
%while ~isDone(videoFReader)
%    [~, audioChunk] = videoFReader();
%    audioChunkSizes = [audioChunkSizes, length(audioChunk)];
%    audioData = [audioData, audioChunk];
%end
pardisp('Done')