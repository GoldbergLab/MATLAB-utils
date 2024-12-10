function [status, cmdout, command, processingArgs] = mergeAudioVideo(videoPaths, audioPaths, outputPath, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mergeAudioVideo: Merge arbitrary video (by stacking) and audio together
% usage: 
%   [status, cmdout, command, processingArgs] = ...
%       mergeAudioVideo(videoPaths, audioPaths, outputPath, ...
%       Name, Value, ....)
%
% where,
%    videoPaths is a cell array of one or more video paths to merge
%    audioPaths is a cell array of one or more audio paths to merge
%    outputPath is the path where the output file should be saved
%    Name/Value arguments can include:
%       CheckFFMPEG - logical indicating whether or not to check if ffmpeg 
%           exists before running. Default is true.
%       Orientation - either 'horizontal' or 'vertical' indicating whether
%           the videos should be stacked horizontally or vertically. 
%           Default is horizontal.
%       ProcessingArgs - a char array or cell array of char arrays 
%           representing whatever video filters should be applied to the 
%           inputs. If empty, the proper padding and stacking filter 
%           arguments will be calculated automatically. When running as a 
%           batch job on many videos of the same sizes, to save time, 
%           capture the processingArgs output from the first run and pass
%           it in to subsequent calls. Default is empty.
%       VideoEncodingArgs - a char array telling ffmpeg what video codec
%           and codec parameters to use. Default is 
%           ["-c:v", "libx264", "-crf", "25"]
%    status is the status output code of the ffmpeg command
%    cmdout is the captured output of the ffmpeg command
%    command is the ffmpeg command used
%    processingArgs are the processing args used
%
% This function combines an arbitrary number of video and audio files into 
%   a single video. Video is combined by horizontally or vertically 
%   stacking the videos, after padding with black if necessary.
%
% See also: tileVideos
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    videoPaths {mustBeText}
    audioPaths {mustBeText}
    outputPath {mustBeText}
    options.CheckFFMPEG logical = true
    options.Orientation {mustBeMember(options.Orientation, {'horizontal', 'vertical'})} = 'horizontal'
    options.ProcessingArgs {mustBeText} = string.empty()
    options.VideoEncodingArgs {mustBeText} = ["-c:v", "libx264", "-crf", "25"]
end

if isempty(videoPaths)
    error('No videos provided');
end

videoPaths = cellstr(videoPaths);
audioPaths = cellstr(audioPaths);

% Ensure ffmpeg is available on path
if options.CheckFFMPEG
    [ffmpegStatus, ~] = system('where /q ffmpeg');
    if ffmpegStatus ~= 0
        error('To use tileVideos, ffmpeg must be installed and available on the system path. See https://ffmpeg.org/download.html.');
    end
    [ffprobeStatus, ~] = system('where /q ffprobe');
    if ffprobeStatus ~= 0
        error('To use tileVideos, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.');
    end
end

% Construct video input arguments
videoInputs = [];
numVideos = length(videoPaths);
for k = 1:numVideos
    videoInputs = [videoInputs, "-i", """" + videoPaths{k} + """"]; %#ok<*AGROW> 
end

% Construct audio input arguments
audioInputs = [];
numAudio = length(audioPaths);
for k = 1:numAudio
    audioInputs = [audioInputs, "-i", """" + audioPaths{k} + """"];
end

if isempty(options.ProcessingArgs)
    if numVideos > 1
        % Create a vstack or hstack filter with padding to combine 
        % multiple videos
        
        % Get video sizes to determine what padding is necessary
        videoSizes = zeros(1, numVideos);
        videoInfo = [];
        for k = 1:numVideos
            videoInfo = [videoInfo, getVideoInfo(videoPaths{k})];
            switch options.Orientation
                case 'horizontal'
                    % User requests horizontal stacking
                    videoSizes(k) = videoInfo(k).height;
                case 'vertical'
                    % User requests vertical stacking
                    videoSizes(k) = videoInfo(k).width;
            end
        end
        
        % Determine necessary padding for each video
        padArgs = string.empty();
        maxSize = max(videoSizes);
        padAmounts = maxSize - videoSizes;
        switch options.Orientation
            case 'horizontal'
                padDim = 'h';
            case 'vertical'
                padDim = 'w';
        end

        % Generate pad/null filters, and assign each output stream a 
        % variable name
        streamNames = alphabet('letters');
        for k = 1:numVideos
            if padAmounts(k) > 0
                % Set up pad filter for this video
                padArgs(end+1) = sprintf("[%d:v]pad=%s=i%s+%d[%s]", k-1, padDim, padDim, padAmounts(k), streamNames(k));
            else
                % No need to pad this video, just use null filter
                padArgs(end+1) = sprintf("[%d:v]null[%s]", k-1, streamNames(k));
            end
        end
        padFilter = join(padArgs, ",");
    
        % Generate stacking filter
        switch options.Orientation
            case 'horizontal'
                stackType = 'h';
            case 'vertical'
                stackType = 'v';
        end    
        stackInputs = "";
        for k = 1:numVideos
            stackInputs = stackInputs + sprintf("[%s]", streamNames(k));
        end
        stackFilter = stackInputs + sprintf("%sstack=inputs=%d[v]", stackType, numVideos);
    
        % Put full filter string together
        videoFilter = "";
        if ~isempty(padArgs)
            videoFilter = videoFilter + padFilter + ",";
        end
        videoFilter = videoFilter + stackFilter;
        processingArgs = ["-filter_complex", """" + videoFilter + """"];
    end

    % Add map statements to tell ffmpeg which streams to output
    processingArgs = [processingArgs, "-map", "[v]"];
    for k = 1:numAudio
        processingArgs = [processingArgs, "-map", sprintf("%d:a", numVideos+k-1)];
    end
else
    % Use supplied processing arguments
    processingArgs = options.ProcessingArgs;
end

% Construct ffmpeg command
commandParts = ["ffmpeg", "-y", videoInputs, audioInputs, processingArgs, options.VideoEncodingArgs, outputPath];
command = join(commandParts, ' ');

% Run command
[status, cmdout] = system(command);


