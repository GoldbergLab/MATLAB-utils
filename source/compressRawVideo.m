function success = compressRawVideo(videoPath, compressedVideoPath, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compressRawVideo: compress a raw video with ffmpeg
% usage: compressRawVideo(videoPath, compressedVideoPath, options)
%
% where,
%    videoPath is the path to the video file
%    compressedVideoPath is the path where the compressed video should be
%       written to
%    success is a logical indicating whether the compression operation
%       seems to have succeeded or not.
%    Name/Value options:
%       CRF is the h264 "constant rate factor". 0 is lossless, 52 is max
%           compression. ~23 is generally a good balance between size and 
%           quality
%       VerifyRaw is a logical indicating whether to first check that the
%           video is currently encoded with the rawvideo codec.
%       CheckFFmpeg is a logical indicating whether to first check that
%           ffmpeg is available on the system.
%
% Take a raw video and use ffmpeg to re-encode it with compression
%
% See also: batchCompressRawVideo, getVideoInfo
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    videoPath {mustBeTextScalar}
    compressedVideoPath {mustBeTextScalar}
    options.CRF {mustBeNumeric} = 0
    options.VerifyRaw logical = true
    options.CheckFFmpeg logical = false
    options.OverWrite logical = false
end

success = False;

% Check if input and output paths are the same
if strcmp(videoPath, compressedVideoPath)
    if ~options.OverWrite
        % User requested no overwrite, skip this one.
        return;
    end
    % Original and compressed paths are the same, gotta do a dance
    nameSwap = true;
    finalCompressedVideoPath = compressedVideoPath;
    [root, name, ext] = fileparts(compressedVideoPath);
    compressedVideoPath = fullfile( ...
        root, ...
        [name, '_TEMP_COMPRESSED_', char(datetime('today')), ext] ...
        );
else
    nameSwap = false;
end

if options.CheckFFmpeg
    % Check if ffmpeg and ffprobe are installed, throw an error otherwise
    checkFFmpeg('CheckFFmpeg', true, 'CheckFFprobe', true, 'CheckFFplay', false, 'IssueError', true);
end

if options.VerifyRaw
    % Check that video is already encoded with the rawvideo codec
    info = getVideoInfo(videoPath, 'SystemCheck', false, 'FfprobeAvailable', true);
    codec = info.raw_info.codec_name;
    if ~strcmp(codec, 'rawvideo')
        error('MATLAB_utils:notRawVideo', 'Video is encoded with %s codec, not rawvideo, aborting: %s', codec, videoPath);
    end
end

if options.OverWrite
    overwrite = 'y';
else
    overwrite = 'n';
end

% Generate ffmpeg command to re-encode the video
ffmpegCommand = sprintf('ffmpeg -%s -i "%s" -c:v libx264 -crf %d "%s"', overwrite, videoPath, options.CRF, compressedVideoPath);

% Convert video
[status, cmdout] = system(ffmpegCommand);

if status ~= 0
    % Error occurred with conversion
    error(cmdout);
end


if nameSwap
    % Overwrite original
    movefile(compressedVideoPath, finalCompressedVideoPath);
end

success = True;