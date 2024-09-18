function videoInfo = getVideoInfo(videoPath, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getVideoInfo: get information about a video from file metadata
% usage:  videoInfo = getVideoInfo(videoPath)
%
% where,
%    videoPath is the path to a video file
%    The following Name/Value arguments:
%       SystemCheck: check that ffprobe is available on the system first.
%           Default is true
%       FfprobeAvailable: If SystemCheck is false, use this value to
%           determine whether or not to use ffprobe
%    videoInfo is a struct containing information about the video with the
%       following fields:
%           numFrames (number of frames in the video)
%           width (width of the video frame in pixels)
%           height (height of the video frame in pixels)
%           frameRate (frame rate of the video in fps)
%           numChannels (number of color channels, or NaN if it can't be
%               determined)
%           raw_info (a struct containing the raw video properties as
%               returned by ffprobe)
%
% This function uses ffprobe to parse the video metadata and returns a
%   struct containing information about the video. It provides a few simple
%   parsed video properties, as well as the raw properties returned by
%   ffprobe.
%
% Note that this system requires that ffprobe be installed on this system.
%   ffprobe is free open source software that can be found here:
%   https://ffmpeg.org/download.html.
%
% See also: loadVideoData
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    videoPath {mustBeText}
    options.SystemCheck logical = true
    options.FfprobeAvailable logical = true
end

% Initialize video info structure
videoInfo = struct();

[path, name, ext] = fileparts(videoPath);

videoInfo.name = [name, ext];
videoInfo.path = path;

if options.SystemCheck
    % Check if ffprobe is available on this system. Warn user if not.
    [ffprobeStatus, ~] = system('where /q ffprobe');
    
    if ffprobeStatus ~= 0
        ffprobeExists = false;
        warning('No ffprobe found - for full getVideoInfo functionality, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html. Basic functionality will be provided through the MATLAB function ''VideoReader''.');
    else
        ffprobeExists = true;
    end
else
    ffprobeExists = options.FfprobeAvailable;
end

if ffprobeExists
    % Get all video properties using ffprobe
    command = sprintf('ffprobe -v error -select_streams v:0 -show_entries stream -of default=nokey=0:noprint_wrappers=1 "%s"', videoPath);
    [status, stdout] = system(command);
    
    % Check if ffprobe threw an error
    if status ~= 0
        error('ffprobe error: %s', status);
    end
    
    % Parse properties
    properties = cellfun(@(x)split(x, '='), split(strip(stdout), newline()), 'UniformOutput', false);
    
    % Organize raw video info into structure
    for k = 1:length(properties)
        propertyName = properties{k}{1};
        propertyValue = properties{k}{2};
        if any(propertyName==':')
            subNames = split(propertyName, ':');
            videoInfo.raw_info.(subNames{1}).(subNames{2}) = propertyValue;
        else
            videoInfo.raw_info.(propertyName) = propertyValue;
        end
    end
    
    % Interpret raw video info and save simple video info to structure
    videoInfo.numFrames = str2double(videoInfo.raw_info.nb_frames);
    videoInfo.width = str2double(videoInfo.raw_info.width);
    videoInfo.height = str2double(videoInfo.raw_info.height);
    videoInfo.frameRate = eval(videoInfo.raw_info.r_frame_rate);
    
    % Try to determine the # of channels in the video
    try
        % Get a table of available pix_fmts that match this video's pix_fmt,
        % along with the # of components it has
        [status, cmdout] = system(sprintf('ffprobe -v quiet -pix_fmts | find "%s"', videoInfo.raw_info.pix_fmt));
        if status ~= 0
            error(cmdout);
        end
        % Get the # of components for the given pix_fmt
        matches = regexp(cmdout, sprintf('%s\\s+([0-9]+)', videoInfo.raw_info.pix_fmt), 'tokens');
        videoInfo.numChannels = str2double(matches{1}{1});
    catch ME
        warning('Failed to automatically extract number of channels from video using ffprobe.');
        warning(getReport(ME));
        videoInfo.numChannels = NaN;
    end
    
    % Switch order so raw_info comes last
    videoInfo = orderfields(videoInfo, [1, 2, 4:length(fieldnames(videoInfo)), 3]);
else
    % No ffprobe - use MATLAB VideoReader instead
    vr = VideoReader(videoPath);
    videoInfo.name = vr.Name;
    videoInfo.path = vr.Path;
    videoInfo.numFrames = vr.NumFrames;
    videoInfo.width = vr.Width;
    videoInfo.height = vr.Height;
    videoInfo.frameRate = vr.FrameRate;
    if strfind(vr.VideoFormat, 'RGB')
        videoInfo.numChannels = 3;
    else
        videoInfo.numChannels = 1;
    end
    videoInfo.raw_info = struct();
end