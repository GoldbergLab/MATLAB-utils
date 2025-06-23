function [isRaw, codec] = isRawVideo(videoPath, options)
arguments
    videoPath {mustBeTextScalar}
    options.SystemCheck logical = true
    options.IssueWarning logical = true
    options.IssueError logical = false
end

if options.SystemCheck
    % Check if ffprobe is available on this system. Warn user if not.
    checkFFmpeg('CheckFFprobe', true, 'CheckFFmpeg', false, 'CheckFFplay', false, 'IssueWarning', options.IssueWarning, 'IssueError', options.IssueError);
end

info = getVideoInfo(videoPath, 'SystemCheck', false);
codec = info.raw_info.codec_name;
isRaw = strcmp(codec, 'rawvideo');