function videoData = fastVideoWriter(videoPath, videoData, otherArgs, options)
arguments
    videoPath (1, :) char     % Path to video file
    videoData
end
arguments (Repeating)
    otherArgs
end
arguments
    options.FrameRate = 30
    options.AudioData = []
    options.AudioSampleRate = 44100
end

% Check that ffmpeg exists on system path
checkFFmpeg('CheckFFmpeg', true, 'CheckFFprobe', false, 'CheckFFplay', false, 'IssueError', true);

videoWidth = size(videoData, 2);
videoHeight = size(videoData, 1);
numChannels = size(videoData, 3);
numFrames = size(videoData, 4);
frameRate = num2str(options.FrameRate);

% Ensure it's all strings
if isempty(otherArgs)
    otherArgs = '';
else
    otherArgs = cellfun(@num2str, otherArgs, 'UniformOutput', false);
    otherArgs = join(otherArgs, ' ');
    otherArgs = otherArgs{1};
end

% Determine desired output pixel format, construct corresponding videoSize vector
switch numChannels
    case 1
        fmt = 'gray';
        % ffmpegVideoShape = [videoWidth, videoHeight, numFrames];
        permuteOrder = [2, 1, 3];
    case 3
        fmt = 'rgb24';
        % ffmpegVideoShape = [3, videoWidth, videoHeight, numFrames];
        permuteOrder = [3, 2, 1, 4];
    case 4
        fmt = 'rgba';
        % ffmpegVideoShape = [4, videoWidth, videoHeight, numFrames];
        permuteOrder = [3, 2, 1, 4];
    otherwise
        error('Supported # of channels are 1 (grayscale), 3 (color), or 4 (color + transparency), not %s', numChannels);
end

% Generate random temp filename to temporarily store raw video data
try
    tempVideoFilePath = [tempname(), '.rawvideo']; %sprintf('tmp%s.raw', r);
catch
    % System-provided temp file couldn't be obtained. Use a local temporary
    % file instead.
    r = strjoin(arrayfun(@dec2hex, randi(16, [1, 10]), 'UniformOutput', false), '');
    tempVideoFilePath = sprintf('tmp%s.rawvideo', r);
end

if ~isempty(options.AudioData)
    % Generate random temp filename to temporarily store raw audio data
    try
        tempAudioFilePath = [tempname(), '.wav']; %sprintf('tmp%s.raw', r);
    catch
        % System-provided temp file couldn't be obtained. Use a local temporary
        % file instead.
        r = strjoin(arrayfun(@dec2hex, randi(16, [1, 10]), 'UniformOutput', false), '');
        tempAudioFilePath = sprintf('tmp%s.wav', r);
    end
    audioInputArgs = sprintf('-i %s', tempAudioFilePath);
else
    audioInputArgs = '';
end

try
    % Write raw video to disk
    fileID = fopen(tempVideoFilePath, 'w');
    fwrite(fileID, permute(videoData, permuteOrder), "uint8");
    fclose(fileID);

    if ~isempty(options.AudioData)
        % Write raw audio to disk
        audiowrite(tempAudioFilePath, options.AudioData, options.AudioSampleRate);
    end

    cmd = sprintf('ffmpeg -an -f rawvideo -pix_fmt %s -s %dx%d -r %s -i "%s" %s -fps_mode passthrough -y %s "%s"', fmt, videoWidth, videoHeight, frameRate, tempVideoFilePath, audioInputArgs, otherArgs, videoPath);

    disp(cmd)
    [status,cmdout] = system(cmd);
    if status ~= 0
        error(cmdout);
        return;
    end
    if exist(tempVideoFilePath, 'file')
        delete(tempVideoFilePath);
    end
    if exist(tempAudioFilePath, 'file')
        delete(tempAudioFilePath);
    end
catch ME
    if exist(tempVideoFilePath, 'file')
        delete(tempVideoFilePath);
    end
    if exist(tempAudioFilePath, 'file')
        delete(tempAudioFilePath);
    end
    rethrow(ME);
end