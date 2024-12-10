function [status, cmdout, command, processingArgs] = mergeAudioVideo(videoPaths, audioPaths, outputPath, options)
arguments
    videoPaths {mustBeText}
    audioPaths {mustBeText}
    outputPath {mustBeText}
    options.CheckFFMPEG logical = true
    options.Orientation {mustBeMember(options.Orientation, {'horizontal', 'vertical'})} = 'horizontal'
    options.ProcessingArgs {mustBeText} = string.empty()
    options.VideoEncodingArgs {mustBeText} = ["-c:v", "libx264", "-crf", "25"]
end

videoPaths = cellstr(videoPaths);
audioPaths = cellstr(audioPaths);

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

videoInputs = [];
numVideos = length(videoPaths);
for k = 1:numVideos
    videoInputs = [videoInputs, "-i", """" + videoPaths{k} + """"]; %#ok<*AGROW> 
end

audioInputs = [];
numAudio = length(audioPaths);
for k = 1:numAudio
    audioInputs = [audioInputs, "-i", """" + audioPaths{k} + """"];
end

if isempty(options.ProcessingArgs)
    videoSizes = zeros(1, numVideos);
    videoInfo = [];
    for k = 1:numVideos
        videoInfo = [videoInfo, getVideoInfo(videoPaths{k})];
        switch options.Orientation
            case 'horizontal'
                videoSizes(k) = videoInfo(k).height;
            case 'vertical'
                videoSizes(k) = videoInfo(k).width;
        end
    end
    
    padArgs = string.empty();
    % Set up pad filter for padding videos if necessary
    maxSize = max(videoSizes);
    padAmounts = maxSize - videoSizes;
    switch options.Orientation
        case 'horizontal'
            padDim = 'h';
        case 'vertical'
            padDim = 'w';
    end
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
    vstackFilter = stackInputs + sprintf("%sstack=inputs=%d[v]", stackType, numVideos);

    videoFilter = "";
    if ~isempty(padArgs)
        videoFilter = videoFilter + padFilter + ",";
    end
    videoFilter = videoFilter + vstackFilter;
    processingArgs = ["-filter_complex", """" + videoFilter + """", options.VideoEncodingArgs, "-map", "[v]"];
    for k = 1:numAudio
        processingArgs = [processingArgs, "-map", sprintf("%d:a", numVideos+k-1)];
    end
else
    processingArgs = options.ProcessingArgs;
end

commandParts = ["ffmpeg", "-y", videoInputs, audioInputs, processingArgs, outputPath];
command = join(commandParts, ' ');
[status, cmdout] = system(command);


