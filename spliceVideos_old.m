function [splicedVideo, splicedAudio] = spliceVideos(videoPathList, frameRangeList, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% spliceVideo: Cut and join multiple videos
% usage:  splicedVideo = spliceVideo(videoPathList, frameRangeList[, videoHolderList[, outputFilename]])
%
% where,
%    videoPathList is a cell array containing paths to the videos to load
%    frameRangeList is a cell array containing the start/end frame ranges 
%       to cut from each video. If the frame range has...
%           0 elements: the whole video is used. 
%           1 element:  the video is cut from that frame to the end of the 
%                       video
%           2 elements: the video is cut from the first element to the
%                       second element.
%    videoHolderList (optional) is an array of AVHolder objects, for the
%       purpose of passing in previously loaded videos to avoid loading them
%       twice. If only some of the videos are loaded, an empty placeholder
%       array should be passed in for them.
%    outputFileName (optional) is the file path to save the spliced video
%       to. If it is omitted or empty, the video is not saved.
%    splicedVideo is the video data of the resulting spliced video
%
% This function takes an array of video paths to load and an array of frame
%   ranges to cut the videos with, and produces a single spliced output
%   video.
%
% See also: loadVideoData, saveVideoData, AVHolder

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~isempty(varargin)
    videoHolderList = varargin{1};
else
    videoHolderList = cell(size(videoPathList));
    videoHolderList(:) = {AVHolder.empty()};
end
if length(varargin) > 1
    outputFilename = varargin{2};
else
    outputFilename = [];
end
if any(cellfun(@length, frameRangeList)>2)
    error('All elements of frameRangeList must be arrays of length 0, 1, or 2');
end

L1 = length(videoPathList);
L2 = length(frameRangeList);
L3 = length(videoHolderList);

if L1 ~= L2 || L1 ~= L3
    error('videoPathList (length = %d) must have the same length as frameRangeList (length = %d) and preLoadedVideoData (length = %d)', L1, L2, L3);
end

numVideos = L1;

% Begin loading of all videos in parallel
for k = 1:numVideos
    videoPath = videoPathList{k};
    if isempty(videoHolderList{k})
        videoHolderList{k} = AVHolder(videoPath);
    end
    if ~videoHolderList{k}.Loaded
        videoHolderList{k}.load();
    end
end

% Wait for all videos to load
for k = 1:numVideos
    waitfor(videoHolderList{k}, 'Loaded', true)
end

splicedVideo = [];
splicedAudio = [];
for k = 1:numVideos
    disp(['Cutting video #', num2str(k)])
    frameRange = frameRangeList{k};
    switch length(frameRange)
        case 0
            frameRange = [1, videoHolderList{k}.VideoInfo.N];
        case 1
            frameRange = [frameRange, videoHolderList{k}.VideoInfo.N];
    end
    audioRange(1) = round((frameRange(1)-1) * videoHolderList{k}.AudioInfo.N / videoHolderList{k}.VideoInfo.N)+1;
    audioRange(2) = round(frameRange(2) * videoHolderList{k}.AudioInfo.N / videoHolderList{k}.VideoInfo.N);
    videoData = videoHolderList{k}.VideoData(:, :, :, frameRange(1):frameRange(2));
    audioData = videoHolderList{k}.AudioData(audioRange(1):audioRange(2), :);
    splicedVideo = cat(4, splicedVideo, videoData);
    splicedAudio = cat(1, splicedAudio, audioData);
end

if ~isempty(outputFilename)
    saveVideoData(splicedVideo, outputFilename);
% vfr = vision.VideoFileWriter('test.avi', 'AudioInputPort', true, 'FrameRate', 15);
% for k = 1:100
% vfr(vd(:, :, :, k), ad((k-1)*2940+1:(k-1)*2940+2940, :))
% end
end

