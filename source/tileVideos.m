function tileVideos(root, videoExtensions, audioExtensions, streamIdentifierRegex, sessionIdentifierRegex, outputPattern, fileIndexRegex, options)
arguments
    root
    videoExtensions {mustBeText} = {'avi', 'mp4'}
    audioExtensions {mustBeText} = {'wav', 'mp3'}
    streamIdentifierRegex char = '^([0-9a-zA-Z]*_[0-9a-zA-Z]+)'
    sessionIdentifierRegex char = '([0-9]{4}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]{2}\-[0-9]+)'
    outputPattern {mustBeTextScalar} = 'merged_%s_%s.mp4'
    fileIndexRegex char = '_([0-9]+)$'
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
                    'ProcessingArgs', processingArgs); %#ok<AGROW> 
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