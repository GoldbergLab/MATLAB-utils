function [ffmpegExists, ffprobeExists, ffplayExists] = checkFFmpeg(options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% checkFFmpeg: check if ffmpeg and related software is installed
% usage: [ffmpegExists, ffprobeExists, ffplayExists] = checkFFmpeg(
%       checkFFmpeg, checkFFprobe, checkFFplay, issueWarning, issueError)
%
% where,
%    Name/Value arguments:
%    CheckFFmpeg is a logical indicating whether or not to check if 
%       ffmpeg is installed and available on the system
%    CheckFFprobe is a logical indicating whether or not to check if 
%       ffprobe is installed and available on the system
%    CheckFFplay is a logical indicating whether or not to check if 
%       ffplay is installed and available on the system
%    IssueWarning is a logical indicating whether or not to issue a warning
%       if the software is not installed. Ignored if issueError is true
%    IssueError is a logical indicating whether or not to throw an error
%       if the software is not installed.
%    ffmpegExists is a logical indicating whether ffmpeg was found.
%    ffprobeExists is a logical indicating whether ffprobe was found.
%    ffplayExists is a logical indicating whether ffplay was found.
%
% Check if ffmpeg, ffprobe, and ffplay are installed and available on the
%    system
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    options.CheckFFmpeg logical = true
    options.CheckFFprobe logical = true
    options.CheckFFplay logical = true
    options.IssueWarning logical = false
    options.IssueError logical = false
end

if options.CheckFFmpeg
    % Check if ffmpeg is available on this system. Warn user if not.
    [ffmpegStatus, ~] = system('where /q ffmpeg');
    ffmpegExists = ffmpegStatus == 0;
    if ~ffmpegExists
        msg = 'No ffmpeg found, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.';
        if options.IssueError
            error(msg)
        elseif options.IssueWarning
            warning(msg)
        end
    end
else
    ffmpegExists = false;
end

if options.CheckFFprobe
    % Check if ffprobe is available on this system. Warn user if not.
    [ffprobeStatus, ~] = system('where /q ffprobe');
    ffprobeExists = ffprobeStatus == 0;
    if ~ffprobeExists
        msg = 'No ffprobe found, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.';
        if options.IssueError
            error(msg)
        elseif options.IssueWarning
            warning(msg)
        end
    end
else
    ffprobeExists = false;
end

if options.CheckFFplay
    % Check if ffplay is available on this system. Warn user if not.
    [ffplayStatus, ~] = system('where /q ffplay');
    ffplayExists = ffplayStatus == 0;
    if ~ffplayExists
        msg = 'No ffplay found, ffplay must be installed and available on the system path. See https://ffmpeg.org/download.html.';
        if options.IssueError
            error(msg)
        elseif options.IssueWarning
            warning(msg)
        end
    end
else
    ffplayExists = false;
end