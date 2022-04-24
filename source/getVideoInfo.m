function [frameSize, numFrames, frameRate, numChannels] = getVideoInfo(videoPath)

video = VideoReader(videoPath);
fs = get(video, 'FrameRate');
dateandtime = [];
label = 'Video';
