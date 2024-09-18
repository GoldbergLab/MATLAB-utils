classdef VideoReaderAsync < handle
    properties
        VideoData
        AudioData
        Path {mustBeTextScalar} = ''
        LoadProgress double = 0
        Loaded logical = false
        Width double {mustBeInteger, mustBeGreaterThan(Width, 0)} = []
        Height double {mustBeInteger, mustBeGreaterThan(Height, 0)} = []
        NumChannels double {mustBeInteger, mustBeGreaterThan(NumChannels, 0)} = []
        NumFrames double {mustBeInteger, mustBeGreaterThan(NumFrames, 0)} = []
        Verbosity {mustBeText, mustBeMember(Verbosity, {'silent', 'error', 'warning', 'info'})} = 'warning'
        WorkerFuture parallel.FevalFuture
    end
    properties (Access = private)
        DataBuffer = uint8.empty
    end
    methods
        function obj = VideoReaderAsync(path, options)
            arguments
                path {mustBeText}
                options.LoadNow logical = true;
                options.Async logical = true;
                options.Verbosity char {mustBeText, mustBeMember(options.Verbosity, {'silent', 'error', 'warning', 'info'})} = 'warning'
            end

            obj.Verbosity = options.Verbosity;

            % Check that ffmpeg and ffprobe exist on system path
            [ffmpegStatus, ~] = system('where /q ffmpeg');
            if ffmpegStatus ~= 0
                error('To use VideoReaderAsync, ffmpeg must be installed and available on the system path. See https://ffmpeg.org/download.html.');
            end
            [ffprobeStatus, ~] = system('where /q ffprobe');
            if ffprobeStatus ~= 0
                error('To use VideoReaderAsync, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.');
            end

            obj.Path = path;

            obj.getVideoInfo();

            if options.LoadNow
                obj.beginLoad();
            end
        end
        function log(obj, msg, msgVerbosity)
            arguments
                obj VideoReaderAsync
                msg {mustBeText}
                msgVerbosity {mustBeText, mustBeMember(msgVerbosity, {'silent', 'error', 'warning', 'info'})} = 'info'
            end
            msgVerbosity = getVerbosityNumber(msgVerbosity);
            verbosity = getVerbosityNumber(obj.Verbosity);
            if msgVerbosity <= verbosity
                disp(msg);
            end
        end
        function beginLoad(obj)
            dataQueue = parallel.pool.DataQueue();
            msgQueue = parallel.pool.DataQueue();
            afterEach(dataQueue, @obj.receiveFrames);
            afterEach(msgQueue, @(msg)obj.log(msg))
            obj.log('Beginning load');
            obj.WorkerFuture = parfeval(@loadVideoAsync, 0, obj.Path, dataQueue, msgQueue, obj.NumFrames, obj.Width, obj.Height, obj.NumChannels);
        end
        function receiveFrames(obj, data)
            finalFrameShape = [obj.Width, obj.Height, obj.NumChannels];
            frameShape = [obj.NumChannels, obj.Height, obj.Width];

            frameBytes = prod(frameShape);
            data = cat(1, obj.DataBuffer, data);
            receivedBytes = length(data);
            numFrames = floor(receivedBytes / frameBytes);
            obj.log(sprintf('Received %d frames and %d extra bytes\n', numFrames, length(data) - numFrames * frameBytes))
            if numFrames > 0
                % At least one full frame received, add it on
                framesShape = [frameShape, numFrames];
                if isempty(obj.VideoData)
                    % Initialize obj.VideoData if it's empty
                    obj.VideoData = uint8.empty([finalFrameShape, 0]);
                end
                % Rearrange new frame data to match desired output format
                newFrames = permute(reshape(data(1:numFrames * frameBytes), framesShape), [3, 2, 1, 4]);
                % Concatenate the newly received frames
                obj.VideoData = cat(4, obj.VideoData, newFrames);
            end
            % Add on any extra data after the last frame to the data buffer
            % to be used for the next frame
            obj.DataBuffer = data((numFrames * frameBytes + 1):end);
            if size(obj.VideoData, 4) == obj.NumFrames
                % Done receiving video
                obj.VideoData = squeeze(obj.VideoData);
                obj.Loaded = true;
            end
        end
        function getVideoInfo(obj)
            % Get video size using ffprobe
            [status, cmdout] = system(sprintf('ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -show_entries stream=width,height -of csv=p=0 "%s"  ', obj.Path));
            if status ~= 0
                error(cmdout);
            end
            ffmpegVideoShape = arrayfun(@str2double, strsplit(strtrim(cmdout), ','));
            obj.Height = ffmpegVideoShape(1);
            obj.Width = ffmpegVideoShape(2);
            obj.NumFrames = ffmpegVideoShape(3);
            
            % Attempt to use ffprobe to determine channel count
            try
                % Get pix_fmt from video header
                [status, cmdout] = system(sprintf('ffprobe -v quiet -print_format csv -select_streams v:0 -show_entries stream=pix_fmt "%s"', obj.Path));
                if status ~= 0
                    error(cmdout);
                end
            catch ME
                error('Failed to automatically extract number of channels from video using ffprobe.');
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
            obj.NumChannels = str2double(matches{1}{1});
            
        end
        function loaded = get.Loaded(obj)
            if isempty(obj.WorkerFuture)
                loaded = false;
            elseif strcmp(obj.WorkerFuture.State, 'finished')
                loaded = true;
            else
                loaded = false;
            end
        end
    end
end

function loadVideoAsync(videoPath, dataQueue, msgQueue, numFrames, width, height, numChannels, options)
    arguments
        videoPath (1, :) char
        dataQueue parallel.pool.DataQueue
        msgQueue parallel.pool.DataQueue
        numFrames double {mustBeInteger, mustBeGreaterThan(numFrames, 0)}
        width double {mustBeInteger, mustBeGreaterThan(width, 0)} = []
        height double {mustBeInteger, mustBeGreaterThan(height, 0)} = []
        numChannels double {mustBeInteger, mustBeGreaterThan(numChannels, 0)} = []
        options.NoTCP (1, 1) logical = false
        options.NoMmap (1, 1) logical = false
    end

    % Determine desired output pixel format, construct corresponding videoSize vector
    switch numChannels
        case 1
            fmt = 'gray';
            ffmpegVideoShape = [height, width, numFrames];
            permuteOrder = [2, 1, 3];
        case 3
            fmt = 'rgb24';
            ffmpegVideoShape = [3, height, width, numFrames];
            permuteOrder = [3, 2, 1, 4];
        case 4
            fmt = 'rgba';
            ffmpegVideoShape = [4, height, width, numFrames];
            permuteOrder = [3, 2, 1, 4];
        otherwise
            msg = sprintf('Supported # of channels are 1 (grayscale), 3 (color), or 4 (color + transparency), not %s', numChannels);
            msgQueue.send(msg)
            error(msg); %#ok<SPERR> 
    end

    ffmpegFrameShape = ffmpegVideoShape(1:end-1);
    videoBytes = prod(ffmpegVideoShape);
    frameBytes = prod(ffmpegFrameShape);


    if ~options.NoMmap
        tempFilePath = generateTempFilePath();
        % Establish a temporary file
        fileID = fopen(tempFilePath, 'w');
        fwrite(fileID, []);
        fclose(fileID);
        try
%             if isempty(numFrames)
            cmd = sprintf('START /B ffmpeg -i "%s" -an -vsync 0 -f rawvideo -pix_fmt %s -v error -y %s', videoPath, fmt, tempFilePath);
%             else
%                 frameFilter = makeFrameFilterExpression(numFrames);
%                 cmd = sprintf('START /B ffmpeg -i "%s" -an -vsync 0 -vf select=''%s'' -f rawvideo -pix_fmt %s -v error -y %s', videoPath, frameFilter, fmt, tempFilePath);
%             end
            [status, cmdout] = system(cmd);

            if status ~= 0
                msgQueue.send(['ffmpeg error: ', cmdout]);
                error(cmdout);
                return;
            end

            % Begin loading the file as it is created
            offset = 0;
            numAttempts = 30;
            attemptWait = 0.05;
            totalDataRead = 0;
            while true
                mmap = memmapfile(tempFilePath, 'Offset', offset, 'Format', 'uint8', 'Writable', false);
                try
                    dataRead = length(mmap.Data);
                    dataQueue.send(mmap.Data);
                catch ME
                    switch ME.identifier
                        case 'MATLAB:memmapfile:fileTooSmall'
                            % Probably because file hasn't been created yet
                            dataRead = 0;
                            msgQueue.send('No file yet')
                        otherwise
                            rethrow(ME);
                    end
                end
                
                totalDataRead = totalDataRead + dataRead;
                offset = offset + dataRead;
                if offset >= videoBytes
                    % Done reading video
                    break;
                end

                if dataRead == 0
                    % No data read - wait a bit and try again
                    numAttempts = numAttempts - 1;
                    pause(attemptWait)
                end

                if numAttempts == 0
                    msg = sprintf('Video read timed out with %d/%d bytes left unread.', videoBytes - totalDataRead, videoBytes);
                    msgQueue.send(msg)
                    warning(msg); %#ok<SPWRN> 
                    break;
                end
                clear mmap;
            end

            if exist(tempFilePath, 'var')
                delete(tempFilePath);
            end
            msgQueue.send('done reading file')
        catch ME
            clear mmap;
            if exist(tempFilePath, 'var')
                delete(tempFilePath);
            end
            rethrow(ME);
        end
    elseif ~options.NoTCP
        % Attempt to stream directly frmo ffmpeg to MATLAB through TCP socket
        % This requires the Instrument Control Toolbox.
    
        msgQueue.send('Reading video over TCP')
        
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
                msg = 'Could not find an open TCP port to stream video data.';
                msgQueue.send(msg);
                error(msg)
            end
    
            framePermuteOrder = permuteOrder(1:end-1);
    
            server.UserData.BytesRead = 0;
            server.UserData.StartTime = datetime();
            
            bufferBytes = frameBytes * 10;  % Set buffer equal to 10 frames worth of data
    
            % Use ffmpeg to decode file to raw bytes and send them over via
            % loopback 
            if isempty(numFrames)
                cmd = sprintf('START /B ffmpeg -i "%s" -an -vsync 0 -f rawvideo -pix_fmt %s -send_buffer_size %d -loglevel quiet -y tcp://%s:%d', videoPath, fmt, bufferBytes, tcpAddress, tcpPort);
            else
                frameFilter = makeFrameFilterExpression(numFrames);
                cmd = sprintf('START /B ffmpeg -i "%s" -an -vsync 0 -vf select=''%s'' -f rawvideo -pix_fmt %s -send_buffer_size %d -loglevel quiet -y tcp://%s:%d', videoPath, frameFilter, fmt, bufferBytes, tcpAddress, tcpPort);
            end
            [status,cmdout] = system(cmd);
            if status ~= 0
                msgQueue.send(['ffmpeg error: ', cmdout]);
                error(cmdout);
                return;
            end
    
            % Read video and pass to queue
            tcpChunkReader(server, numFrames, ffmpegFrameShape, framePermuteOrder, dataQueue);
    
            server.delete()
            clear server;
        catch ME
            server.delete();
            clear server;
            rethrow(ME);
        end
    else
        tempFilePath = generateTempFilePath();
        
        % Use ffmpeg to convert file to raw bytes
        if isempty(numFrames)
            cmd = sprintf('ffmpeg -i "%s" -an -vsync 0 -f rawvideo -pix_fmt %s -v error -y "%s"', videoPath, fmt, tempFilePath);
        else
            frameFilter = makeFrameFilterExpression(numFrames);
            cmd = sprintf('ffmpeg -i "%s" -an -vsync 0 -vf select=''%s'' -f rawvideo -pix_fmt %s -v error -y "%s"', videoPath, frameFilter, fmt, tempFilePath);
        end
        [status,cmdout] = system(cmd);
        if status ~= 0
            msgQueue.send(['ffmpeg error: ', cmdout]);
            error(cmdout);
            return;
        end
        
        try
            % Open and read in raw file
            f = fopen(tempFilePath);
            for frameNum = 1:numFrames
                % Read a frame of video and push to queue
                bytesRead = uint8(fread(f, frameBytes, '*uint8'));
                dataQueue.send(bytesRead);
            end
            % Close file
            fclose(f);
            % Delete temporary raw video file
            delete(tempFilePath);
        catch ME
            % Something went wrong - try to delete temporary video file before
            % exiting.
            delete(tempFilePath);
            msgQueue.send(getReport(ME));
        end
    end
    
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
    
function tcpChunkReader(server, numFrames, rawFrameShape, framePermuteOrder, dataQueue)
    for k = 1:numFrames
        displayProgress('%d of %d frames read\n', k, numFrames, 10);
        dataQueue.send(readFrame(server, rawFrameShape, framePermuteOrder));
    end
end

function frameFilter = makeFrameFilterExpression(frames)
    filterExpressions = arrayfun(@(f)sprintf('eq(n\\,%d)', f), frames, 'UniformOutput', false);
    frameFilter = join(filterExpressions, '+');
    frameFilter = frameFilter{1};
end

function tempFilePath = generateTempFilePath()
    % Generate random temp filename to temporarily store raw video data
    try
        tempFilePath = tempname();
    catch
        % System-provided temp file couldn't be obtained. Use a local temporary
        % file instead.
        r = strjoin(arrayfun(@dec2hex, randi(16, [1, 10]), 'UniformOutput', false), '');
        tempFilePath = sprintf('tmp%s.raw', r);
    end
end

function verbosityNum = getVerbosityNumber(verbosity)
    arguments
        verbosity {mustBeText, mustBeMember(verbosity, {'silent', 'error', 'warning', 'info'})} = 'warning'
    end
    switch verbosity
        case 'silent'
            verbosityNum = 0;
        case 'error'
            verbosityNum = 1;
        case 'warning'
            verbosityNum = 2;
        case 'info'
            verbosityNum = 3;
    end
end
