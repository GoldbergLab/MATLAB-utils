function [isRaw, codec] = isRawVideo(videoPath, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% isRawVideo: Use ffprobe to check if video is encoded with rawvideo codec
% usage: [isRaw, codec] = isRawVideo(videoPath, Name, Value, ...)
%
% where,
%    videoPath is the path to the video
%    isRaw is a logical indicating if the video is indeed rawvideo
%    codec is a char array representing the codec the video was encoded 
%       with
%    Name/Value pairs can be:
%       SystemCheck: Start by checking if ffprobe is available? Default is 
%           true
%       IssueWarning: Issue warning if ffprobe is not found on the path?
%       IssueError: Issue error if ffprobe is not found on the path?
%
% Check if the video is encoded with the "rawvideo" codec. Note that this
%   function depends on ffprobe being installed and available on the system
%   path.
%
% See also: compressRawVideo, batchCompressRawVideo, getVideoInfo
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

% Get video info using ffprobe
info = getVideoInfo(videoPath, 'SystemCheck', false);
% Get the name of the video codec
codec = info.raw_info.codec_name;
% Check if codec is "rawvideo".
isRaw = strcmp(codec, 'rawvideo');