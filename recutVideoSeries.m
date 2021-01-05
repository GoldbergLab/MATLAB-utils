function recutVideoSeries(videoPathList, outputFilename, startTime, duration, compression)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% recutVideoSeries: Cut and join multiple videos
% usage:  recutVideoSeries(videoPathList, startTime, duration, outputFilename)
%
% where,
%    videoPathList is a cell array containing paths to the videos to
%       cut/join
%    outputFileName is the file path to save the spliced video
%       to.
%    startTime (optional) is a number in seconds indicating the time to 
%       start in the merged video. Default is 0.
%    duration (optional) is a number in seconds indicating how long the 
%       merged video should be. Default is the merged clip goes all the way
%       to the end.
%    compression (optional) is an integer indicating the video compression
%       level to use for the h.264 codec. 0 = lossless, 52 = max
%       compression.
%
% This function takes an array of video paths, merges them, then cuts them
%   to a specific startTime and duration. This function depends on ffmpeg
%   begin available in the system. It was developed with ffmpeg version
%   git-2020-05-28-c0f01ea on Windows 10, but it will probably work with
%   a variety of older and newer versions. If you type "ffmpeg" into the
%   system command line, and you get an error indicating it isn't
%   available, then either you need to install it
%   (https://ffmpeg.org/download.html) or you need to add it to your system
%   path.
%
% See also: loadVideoData, saveVideoData, AVHolder

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('startTime', 'var')
    startTime = 0;
end
if ~exist('duration', 'var')
    duration = [];
end
if ~exist('compression', 'var')
    compression = 23;
end

inputSpec = join(videoPathList, '|');
inputSpec = inputSpec{1};

if ~isempty(duration)
    command = sprintf("ffmpeg -i ""concat:%s"" -c:v libx264 -preset veryfast -crf %d -shortest -ss %f -t %f %s", inputSpec, compression, startTime, duration, outputFilename);
else
    command = sprintf("ffmpeg -i ""concat:%s"" -c:v libx264 -preset veryfast -crf %d -shortest -ss %f %s", inputSpec, compression, startTime, outputFilename);
end

disp('Cutting videos with command:')
disp(command)
system(command, '-echo');