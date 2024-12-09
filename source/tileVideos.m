function tileVideos(root, videoExtensions, audioExtensions, streamIdentifierRegex, sessionIdentifierRegex, fileIndexRegex, options)
arguments
    root
    videoExtensions {mustBeText} = {'avi', 'mp4'}
    audioExtensions {mustBeText} = {'wav', 'mp3'}
    streamIdentifierRegex char = '^([0-9a-zA-Z]*_[0-9a-zA-Z]+)'
    sessionIdentifierRegex char = '([0-9]{4}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]+)'
    fileIndexRegex char = '_([0-9]+)$'
    options.Recursive logical = true
end

if ischar(videoExtensions)
    videoExtensions = {videoExtensions};
end
if ~iscell(audioExtensions)
    audioExtensions = {audioExtensions};
end

% Regularize extensions so they are all without spaces and with periods
videoExtensions = cellfun(@(ext)['.', strrep(strip(ext), '.', '')], videoExtensions, 'UniformOutput', false);
audioExtensions = cellfun(@(ext)['.', strrep(strip(ext), '.', '')], audioExtensions, 'UniformOutput', false);

% Check that ffmpeg and ffprobe exist on system path
[ffmpegStatus, ~] = system('where /q ffmpeg');
if ffmpegStatus ~= 0
    error('To use tileVideos, ffmpeg must be installed and available on the system path. See https://ffmpeg.org/download.html.');
end
[ffprobeStatus, ~] = system('where /q ffprobe');
if ffprobeStatus ~= 0
    error('To use tileVideos, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.');
end

passedOptions = namedargs2cell(options);
[matchedFiles, unmatchedFiles] = matchFileStreams(root, streamIdentifierRegex, sessionIdentifierRegex, fileIndexRegex, passedOptions{:});

if isempty(matchedFiles)
    fprintf('No matched files found, %d unmatched files found\n', length(unmatchedFiles));
    return
else
    fprintf('%d sessions found:\n', length(matchedFiles));
    for sessionIdx = 1:length(matchedFiles)
        fprintf('Session %d: Found %d matched files in %d streams, and %d unmatched files.\n', sessionIdx, length(unique(matchedFiles)), size(matchedFiles, 2), length(unmatchedFiles));
    end
end

% Determine which streams are video and which are audio
videoStreamIdx = [];
audioStreamIdx = [];
unknownStreamIdx = [];
unknownStreamExts = {};
for streamIdx = 1:size(matchedFiles, 2)
    [~, ~, ext] = fileparts(matchedFiles(1, streamIdx));
    if any(strcmpi(ext, videoExtensions))
        videoStreamIdx(end+1) = streamIdx;
    elseif any(strcmpi(ext, audioExtensions))
        audioStreamIdx(end+1) = streamIdx;
    else
        unknownStreamIdx(end+1) = streamIdx;
        unknownStreamExts{end+1} = ext;
    end
end

fprintf('Found %d video streams, %d audio streams, and %d unknown streams: %s\n', length(videoStreamIdx), length(audioStreamIdx), length(unknownStreamExts), join(string(unknownStreamExts), ', '));