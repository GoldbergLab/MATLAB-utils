function videoData = fastVideoReader(videoPath, numChannels)
% Check that ffmpeg and ffprobe exist on system path
[ffmpegStatus, ~] = system('where /q ffmpeg');
if ffmpegStatus ~= 0
    error('To use fastVideoReader, ffmpeg must be installed and available on the system path. See https://ffmpeg.org/download.html.');
end
[ffprobeStatus, ~] = system('where /q ffprobe');
if ffprobeStatus ~= 0
    error('To use fastVideoReader, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.');
end

% Generate random temp filename to temporarily store raw video data
try
    tempFilePath = tempname(); %sprintf('tmp%s.raw', r);
catch ME
    % System-provided temp file couldn't be obtained. Use a local temporary
    % file instead.
    r = strjoin(arrayfun(@dec2hex, randi(16, [1, 10]), 'UniformOutput', false), '');
    tempFilePath = sprintf('tmp%s.raw', r);
end

% Get video size using ffprobe
[status, cmdout] = system(sprintf('ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -show_entries stream=width,height -of csv=p=0 "%s"  ', videoPath));
if status ~= 0
    error(cmdout);
end
videoSize = arrayfun(@str2double, strsplit(strtrim(cmdout), ','));
videoWidth = videoSize(1);
videoHeight = videoSize(2);
numFrames = videoSize(3);

if ~exist('numChannels', 'var') || isempty(numChannels)
    % Attempt to use ffprobe to determine channel count
    try
        % Get pix_fmt from video header
        [status, cmdout] = system(sprintf('ffprobe -v quiet -print_format csv -select_streams v:0 -show_entries stream=pix_fmt "%s"', videoPath));
        if status ~= 0
            error(cmdout);
        end
        output = strsplit(strtrim(cmdout), ',');
        pix_fmt = output{2};
        % Get a table of available pix_fmts that match this video's pix_fmt,
        % along with the # of components it has
        [status, cmdout] = system(sprintf('ffprobe -v quiet -pix_fmts | find "%s"', pix_fmt));
        if status ~= 0
            error(cmdout);
        end
        % Get the # of components for the given pix_fmt
        matches = regexp(cmdout, sprintf('%s\\s+([0-9]+)', pix_fmt), 'tokens');
        numChannels = str2double(matches{1}{1});
    catch ME
        disp(getReport(ME));
        error('Failed to automatically extract number of channels from video using ffprobe.');
    end
end

% Determine desired output pixel format, construct corresponding videoSize vector
switch numChannels
    case 1
        fmt = 'gray';
        videoSize = [videoWidth, videoHeight, numFrames];
        permuteOrder = [2, 1, 3];
    case 3
        fmt = 'rgb24';
        videoSize = [3, videoWidth, videoHeight, numFrames];
        permuteOrder = [3, 2, 1, 4];
    case 4
        fmt = 'rgba';
        videoSize = [4, videoWidth, videoHeight, numFrames];
        permuteOrder = [3, 2, 1, 4];
    otherwise
        error('Supported # of channels are 1 (grayscale), 3 (color), or 4 (color + transparency), not %s', numChannels);
end

% Use ffmpeg to convert file to raw bytes
cmd = sprintf('ffmpeg -i "%s" -an -vsync 0 -f rawvideo -pix_fmt %s -v error -y "%s"', videoPath, fmt, tempFilePath);
[status,cmdout] = system(cmd);
if status ~= 0
    error(cmdout);
    return;
end
% if  ~isempty(cmdout)
%     disp(cmdout)
% end

try
    % Open and read in raw file
    f = fopen(tempFilePath);
    videoData = uint8(fread(f, '*uint8'));
    % Reshape flat array into 4-D video array
    videoData = permute(reshape(videoData, videoSize), permuteOrder);
    % Close file
    fclose(f);
    % Delete temporary raw video file
    delete(tempFilePath);
catch ME
    % Something went wrong - try to delete temporary video file before
    % exiting.
    delete(tempFilePath);
    disp(getReport(ME));
end