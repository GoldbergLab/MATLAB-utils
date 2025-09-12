function videoData = fastVideoReader(videoPath, numChannels, frames, cropBox)
arguments
    videoPath (1, :) char     % Path to video file
    numChannels double = []   % Number of color channels to expect
    frames double = []        % List of frames to load
    cropBox double = []       % [x, y, w, h] box to crop video
end
% Check that ffmpeg and ffprobe exist on system path
[ffmpegStatus, ~] = system('where /q ffmpeg');
if ffmpegStatus ~= 0
    error('To use fastVideoReader, ffmpeg must be installed and available on the system path. See https://ffmpeg.org/download.html.');
end
[ffprobeStatus, ~] = system('where /q ffprobe');
if ffprobeStatus ~= 0
    error('To use fastVideoReader, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.');
end

% Get video size using ffprobe
[status, cmdout] = system(sprintf('ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -show_entries stream=width,height -of csv=p=0 "%s"  ', videoPath));
if status ~= 0
    error(cmdout);
end
ffmpegVideoShape = arrayfun(@str2double, strsplit(strtrim(cmdout), ','));
videoWidth = ffmpegVideoShape(1);
videoHeight = ffmpegVideoShape(2);
if isempty(frames)
    numFrames = ffmpegVideoShape(3);
else
    numFrames = length(frames);
end

if isempty(numChannels)
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

if ~isempty(cropBox)
    % User requests video cropping
    % Translate crop box into ffmpeg argument:
    cropArg = sprintf('-vf "crop=%d:%d:%d:%d"', cropBox(3), cropBox(4), cropBox(1), cropBox(2));
    videoWidth = cropBox(4);
    videoHeight = cropBox(3);
else
    cropArg = '';
end

% Determine desired output pixel format, construct corresponding videoSize vector
switch numChannels
    case 1
        fmt = 'gray';
        ffmpegVideoShape = [videoWidth, videoHeight, numFrames];
        permuteOrder = [2, 1, 3];
    case 3
        fmt = 'rgb24';
        ffmpegVideoShape = [3, videoWidth, videoHeight, numFrames];
        permuteOrder = [3, 2, 1, 4];
    case 4
        fmt = 'rgba';
        ffmpegVideoShape = [4, videoWidth, videoHeight, numFrames];
        permuteOrder = [3, 2, 1, 4];
    otherwise
        error('Supported # of channels are 1 (grayscale), 3 (color), or 4 (color + transparency), not %s', numChannels);
end

try
    % Check if user set NO_TCP variable
    no_tcp = evalin('base', 'NO_TCP');
catch
    % User did not set NO_TCP environment variable
    no_tcp = false;
end

try
    % Check if user set NO_MMAP variable
    no_mmap = evalin('base', 'NO_MMAP');
catch
    % User did not set NO_MMAP environment variable
    no_mmap = false;
end

if ~no_mmap
    % Generate random temp filename to temporarily store raw video data
    try
        tempFilePath = tempname(); %sprintf('tmp%s.raw', r);
    catch
        % System-provided temp file couldn't be obtained. Use a local temporary
        % file instead.
        r = strjoin(arrayfun(@dec2hex, randi(16, [1, 10]), 'UniformOutput', false), '');
        tempFilePath = sprintf('tmp%s.raw', r);
    end
    % Establish a temporary file
    fileID = fopen(tempFilePath, 'w');
    fwrite(fileID, 1);
    fclose(fileID);
    try
        mmap = memmapfile(tempFilePath);

        if isempty(frames)
            cmd = sprintf('ffmpeg -i "%s" %s -an -vsync 0 -f rawvideo -pix_fmt %s -v error -y %s', videoPath, cropArg, fmt, tempFilePath);
        else
            frameFilter = makeFrameFilterExpression(frames);
            cmd = sprintf('ffmpeg -i "%s" %s -an -vsync 0 -vf select=''%s'' -f rawvideo -pix_fmt %s -v error -y %s', videoPath, cropArg, frameFilter, fmt, tempFilePath);
        end
        disp(cmd)
        [status,cmdout] = system(cmd);
        if status ~= 0
            error(cmdout);
            return;
        end
        videoData = reshape(typecast(mmap.Data, 'uint8'), ffmpegVideoShape);
        clear mmap;
        videoData = permute(videoData, permuteOrder);
        if exist(tempFilePath, 'var')
            delete(tempFilePath);
        end
    catch ME
        if exist(tempFilePath, 'var')
            delete(tempFilePath);
        end
        rethrow(ME);
    end
elseif ~no_tcp
    % Attempt to stream directly frmo ffmpeg to MATLAB through TCP socket
    % This requires the Instrument Control Toolbox.

    disp('Reading video over TCP (set ''NO_TCP=true'' to disable)')
    
    try
        % Open tcp server to receive data
        tcpAddress = 'localhost';
        foundOpenPort = false;
        for attempt = 0:100
            % Loop over possible port numbers looking for an available port
            try
                tcpPort = 30000 + attempt;
                % Attempt to open server
                server = tcpserver(tcpAddress, tcpPort, 'Timeout', 20, 'ConnectionChangedFcn', @connectionFcn); %#ok<TSLHT> 
                foundOpenPort = true;
                break;
            catch ME
                if strcmp(ME.identifier, 'instrument:interface:tcpserver:cannotConnect')
                    % Port was not open - continue and try the next port
                    continue;
                else
                    rethrow(ME);
                end
            end
        end
        if ~foundOpenPort
            error('Could not find an open TCP port to stream video data.')
        end

        ffmpegFrameShape = ffmpegVideoShape(1:end-1);
        framePermuteOrder = permuteOrder(1:end-1);

        videoBytes = prod(ffmpegVideoShape);
        notifyBytes = 10000000;
        server.UserData.BytesRead = 0;
        server.UserData.StartTime = datetime();
        byteUpdate = getByteUpdate(notifyBytes, videoBytes);
%        server.configureCallback("byte", notifyBytes, byteUpdate);
        
        bufferBytes = prod(ffmpegFrameShape) * 10;  % Set buffer equal to 10 frames worth of data

        % Use ffmpeg to decode file to raw bytes and send them over via
        % loopback 
        if isempty(frames)
            cmd = sprintf('START /B ffmpeg -i "%s" -an -vsync 0 -f rawvideo -pix_fmt %s -send_buffer_size %d -loglevel quiet -y tcp://%s:%d', videoPath, fmt, bufferBytes, tcpAddress, tcpPort);
        else
            frameFilter = makeFrameFilterExpression(frames);
            cmd = sprintf('START /B ffmpeg -i "%s" -an -vsync 0 -vf select=''%s'' -f rawvideo -pix_fmt %s -send_buffer_size %d -loglevel quiet -y tcp://%s:%d', videoPath, frameFilter, fmt, bufferBytes, tcpAddress, tcpPort);
        end
        disp(cmd)
        [status,cmdout] = system(cmd);
        if status ~= 0
            error(cmdout);
            return;
        end

        % Read 
        videoData = tcpChunkReader(server, numFrames, ffmpegFrameShape, framePermuteOrder);

        server.delete()
        clear server;
    catch ME
        server.delete();
        clear server;
        rethrow(ME);
    end
else
    % Generate random temp filename to temporarily store raw video data
    try
        tempFilePath = tempname(); %sprintf('tmp%s.raw', r);
    catch
        % System-provided temp file couldn't be obtained. Use a local temporary
        % file instead.
        r = strjoin(arrayfun(@dec2hex, randi(16, [1, 10]), 'UniformOutput', false), '');
        tempFilePath = sprintf('tmp%s.raw', r);
    end
    
    % Use ffmpeg to convert file to raw bytes

    if isempty(frames)
        cmd = sprintf('ffmpeg -i "%s" %s -an -vsync 0 -f rawvideo -pix_fmt %s -v error -y "%s"', videoPath, cropArg, fmt, tempFilePath);
    else
        frameFilter = makeFrameFilterExpression(frames);
        cmd = sprintf('ffmpeg -i "%s" %s -an -vsync 0 -vf select=''%s'' -f rawvideo -pix_fmt %s -v error -y "%s"', videoPath, cropArg, frameFilter, fmt, tempFilePath);
    end
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
        videoData = uint8(fread(f, prod(ffmpegVideoShape), '*uint8'));
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

    % Reshape flat array into 4-D video array
    videoData = permute(reshape(videoData, ffmpegVideoShape), permuteOrder);
end

end

function byteUpdate = getByteUpdate(notifyBytes, videoBytes)
    function byteUpdateFcn(server, ~)
        server.UserData.BytesRead = server.UserData.BytesRead + notifyBytes;
        fprintf('Bytes read: %d / %d     Elapsed time: %s\n', server.UserData.BytesRead, videoBytes, datetime() - server.UserData.StartTime);
    end
    byteUpdate = @byteUpdateFcn;            
end

function connectionFcn(server, ~)
    if server.Connected
%        disp('Connected to ffmpeg');
    end
end

function frameData = readFrame(server, rawFrameShape, framePermuteOrder)
    % This involves a ridiculous hack necessitated by the fact that 
    % tcpserverrefuses to return the read data in any form other than an 8 
    % byte double, which means for large videos you're gonna run out of RAM
    % before you finish loading the data, since each pixel value is
    % stored with 7 unnecessary bytes tacked on. So, we read all the
    % bytes in as doubles, but sometimes the # of bytes will not be a
    % multiple of 8, so there will be some left over, which we have to
    % gather up, before typecasting the whole mess back into uint8 and
    % piecing it back into a single array.    
    
    doubleBytes = 8;
    frameBytes = prod(rawFrameShape);
    chunkBytes = round(frameBytes / doubleBytes) * doubleBytes;
    remainderBytes = frameBytes - chunkBytes;

    frameData = zeros(rawFrameShape, 'uint8');
    frameData(1:chunkBytes) = typecast(server.read(chunkBytes / doubleBytes, 'double'), 'uint8');
    if remainderBytes > 0
        frameData(chunkBytes+1:end) = typecast(server.read(ceil(remainderBytes / doubleBytes), 'double'), 'uint8');
    end
    frameData = permute(frameData, framePermuteOrder);
end

function videoData = tcpChunkReader(server, numFrames, rawFrameShape, framePermuteOrder)
    numFrameBytes = prod(rawFrameShape);

    videoData = zeros([rawFrameShape(framePermuteOrder), numFrames], 'uint8');
    for k = 1:numFrames
        displayProgress('%d of %d frames read\n', k, numFrames, 10);
        videoData(numFrameBytes*(k-1)+1:numFrameBytes*k) = readFrame(server, rawFrameShape, framePermuteOrder);
    end
    
% 
%     doubleBytes = 8;
% 
%     frameBytes = prod(rawFrameShape);
% 
%     % Make chunk size a multiple of 8 so we can read an even # of doubles
%     frameBytes = round(frameBytes / doubleBytes) * doubleBytes;
%     numChunks = floor(totalSize / frameBytes);
%     % Get size of remainder chunk of doubles
%     remainderChunkSize = totalSize - floor(totalSize/frameBytes)*frameBytes;
%     remainderChunkSize = round(remainderChunkSize / doubleBytes) * doubleBytes;
%     % Get # of left over bytes after all doubles have been read
%     remainderBytes = totalSize - frameBytes * numChunks - remainderChunkSize;
% 
%     videoData = zeros(totalSize, 1, 'uint8');
% 
%     disp('Beginning read');
%     for k = 1:numChunks
%         displayProgress('%d of %d chunks read\n', k, numChunks, 10);
%         videoData(frameBytes*(k-1)+1:frameBytes*k) = typecast(server.read(frameBytes / doubleBytes, 'double'), 'uint8');
%     end
%     if remainderChunkSize > 0
% %        disp('Reading remainder double chunk');
%         videoData(frameBytes*numChunks + 1:frameBytes*numChunks + remainderChunkSize) = typecast(server.read(remainderChunkSize / doubleBytes, 'double'), 'uint8');
%     end
%     if remainderBytes > 0
% %        disp('Reading remainder uint8 chunk');
%         videoData(frameBytes*numChunks + remainderChunkSize + 1:end) = typecast(server.read(remainderBytes, 'uint8'), 'uint8');
%     end
%     disp('Done reading');
end

function frameFilter = makeFrameFilterExpression(frames)
    filterExpressions = arrayfun(@(f)sprintf('eq(n\\,%d)', f), frames, 'UniformOutput', false);
    frameFilter = join(filterExpressions, '+');
    frameFilter = frameFilter{1};
end
