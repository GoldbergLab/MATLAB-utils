function tileVideos(root, videoExtensions, audioExtensions, streamIdentifierRegex, sessionIdentifierRegex, fileIndexRegex, outputPattern, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tileVideos: Batch combine multiple video/audio streams across sessions
% usage: tileVideos(root, videoExtensions, audioExtensions, 
%   streamIdentifierRegex, sessionIdentifierRegex, outputPattern, 
%   fileIndexRegex, Name, Value, ...)
%
% where,
%    root is the path to the root folder containing audio and video files 
%       or subfolders containing them
%    videoExtensions is a cell array of one or more expected file 
%       extensions for video files within root
%    audioExtensions is a cell array of one or more expected file
%       extensions for audio files within root
%    streamIdentifierRegex is a regular expression with a single capturing
%       group, in which the capturing group will uniquely select a series 
%       of characters in each audio or video file that will identify which
%       audio/video stream that file belongs to.
%    sessionIdentifierRegex is a regular expression with a single capturing
%       group, in which the capturing group will uniquely select a series 
%       of characters in each audio or video file that will identify which
%       recording session that file belongs to.
%    fileIndexRegex is a regular expression with a single capturing
%       group, in which the capturing group will uniquely select a series 
%       of characters in each audio or video file that will identify which
%       recording file number within the session the file represents.
%    outputPattern is a format string (not regex) comprehensible by
%       sprintf that will construct the desired output filename for a 
%       merged file. The format string should accept two string values 
%       which represent the session id and file id extracted from each 
%       merged file. The order of those two is determined based on the 
%       value of the 'OutputOrder' argument.
%    Name/Value arguments can include:
%       Recursive: true or false (default true) - should tileVideos search 
%           subdirectories of the root folder or not?
%       DryRun: true or false (default true) - actually merge, or just 
%           output a description of what would have been done?
%       Overwrite: true or false (default false) - should files be 
%           overwritten if the output file already exists?
%       OutputOrder: 'SessionIdFirst' or 'FileIdFirst' (default 
%           'SessionIdFirst'). Which order does the outputPattern format 
%           string accept arguments?
%       OutputRoot: Which directory should output files be placed in? 
%           Default is whichever directory the first video stream is found
%           in.
%       DebugOutput: true or false - should ffmpeg output be printed to the
%           the console?
%
% This function is designed to batch process one or more video streams, 
%   zero or more audio streams, across one or more sessions, taking each 
%   set of corresponding audio/video files and merging them by stacking
%   the videos, and combining the audio.
%
% See also: matchFileStreams, mergeAudioVideo, VideoReaderAsync
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    root
    videoExtensions {mustBeText} = {'avi', 'mp4'}
    audioExtensions {mustBeText} = {'wav', 'mp3'}
    streamIdentifierRegex char = '^([0-9a-zA-Z]*_[0-9a-zA-Z]+)'
    sessionIdentifierRegex char = '([0-9]{4}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]+)'
    fileIndexRegex char = '_([0-9]+)$'
    outputPattern {mustBeTextScalar} = 'merged_%s_%s.mp4'
    options.Recursive logical = true
    options.DryRun logical = true
    options.Overwrite logical = false
    options.OutputOrder {mustBeMember(options.OutputOrder, {'SessionIdFirst', 'FileIdFirst'})} = 'SessionIdFirst'
    options.OutputRoot {mustBeText} = ''
    options.DebugOutput logical = false
end

dryRun = options.DryRun;
recursive = options.Recursive;

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

[matchedFiles, unmatchedFiles, sessionIds, fileIds] = matchFileStreams(root, streamIdentifierRegex, sessionIdentifierRegex, fileIndexRegex, 'Recursive', recursive);
numSessions = length(matchedFiles);

if isempty(matchedFiles)
    fprintf('No matched files found, %d unmatched files found\n', length(unmatchedFiles));
    return
end
fprintf('%d sessions found\n', numSessions);

% Determine which streams are video and which are audio
videoStreamIdx = repmat({[]}, 1, numSessions);
audioStreamIdx = repmat({[]}, 1, numSessions);
unknownStreamIdx = repmat({[]}, 1, numSessions);
unknownStreamExts = repmat({{}}, 1, numSessions);
for sessionIdx = 1:numSessions
    for streamIdx = 1:size(matchedFiles{sessionIdx}, 2)
        [~, ~, ext] = fileparts(matchedFiles{sessionIdx}{1, streamIdx});
        if any(strcmpi(ext, videoExtensions))
            videoStreamIdx{sessionIdx}(end+1) = streamIdx;
        elseif any(strcmpi(ext, audioExtensions))
            audioStreamIdx{sessionIdx}(end+1) = streamIdx;
        else
            unknownStreamIdx{sessionIdx}(end+1) = streamIdx;
            unknownStreamExts{sessionIdx}{end+1} = ext;
        end
    end
    fprintf('\tSession %d: Found %d matched files in %d streams.\n', sessionIdx, length(uniqueRecursive(matchedFiles{sessionIdx})), size(matchedFiles{sessionIdx}, 2));
    fprintf(...
        '\t\tFound %d video streams, %d audio streams, and %d unknown streams: %s\n', ...
        length(videoStreamIdx{sessionIdx}), ...
        length(audioStreamIdx{sessionIdx}), ...
        length(unknownStreamExts{sessionIdx}), ...
        join(string(unknownStreamExts{sessionIdx}), ', '));
end
fprintf('%d unmatched files found\n', length(unmatchedFiles));

% Merge files
futures = parallel.Future.empty();
for sessionIdx = 1:numSessions
    processingArgs = '';
    for fileIdx = 1:3 %size(matchedFiles{sessionIdx}, 1)
        videoFiles = matchedFiles{sessionIdx}(fileIdx, videoStreamIdx{sessionIdx});
        audioFiles = matchedFiles{sessionIdx}(fileIdx, audioStreamIdx{sessionIdx});
        switch options.OutputOrder
            case 'SessionIdFirst'
                outputFile = sprintf(outputPattern, sessionIds{sessionIdx}, fileIds{sessionIdx}{fileIdx});
            case 'FileIdFirst'
                outputFile = sprintf(outputPattern, fileIds{sessionIdx}{fileIdx}, sessionIds{sessionIdx});
        end
        if isempty(options.OutputRoot)
            options.OutputRoot = fileparts(videoFiles{1});
        end
        outputFile = fullfile(options.OutputRoot, outputFile);
        if dryRun
            fprintf('Would have merged:\n');
            disp(videoFiles')
            disp(audioFiles')
            fprintf('into %s\n', outputFile)
        else
            fprintf('Initiating merge %d of %d\n', fileIdx, size(matchedFiles{sessionIdx}, 1));
            if fileIdx == 1
                [status, cmdout, command, processingArgs] = mergeAudioVideo(...
                    videoFiles, audioFiles, outputFile, ...
                    'CheckFFMPEG', false, ...
                    'Orientation', 'horizontal', ...
                    'ProcessingArgs', processingArgs);
                if options.DebugOutput
                    disp('status:')
                    disp(status)
                    disp('cmdout:')
                    disp(cmdout)
                    disp('command:')
                    disp(command)
                end
            else
                futures(end+1) = parfeval(@mergeAudioVideo, 4, videoFiles, audioFiles, outputFile, ...
                    'CheckFFMPEG', false, ...
                    'Orientation', 'horizontal', ...
                    'ProcessingArgs', processingArgs, ...
                    'Overwrite', options.Overwrite); %#ok<AGROW> 
            end
        end
    end
end

if options.DebugOutput
    for future = futures
        [status, cmdout, command, ~] = fetchOutputs(future);
        disp('status:')
        disp(status)
        disp('cmdout:')
        disp(cmdout)
        disp('command:')
        disp(command)
    end
end