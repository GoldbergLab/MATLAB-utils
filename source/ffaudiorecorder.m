classdef ffaudiorecorder < handle & matlab.mixin.SetGet
    properties
        SampleRate
        StartFcn = ''
        StopFcn = ''
        TimerFcn = ''
        TimerPeriod = 0.1
        Tag = ''
        UserData = []
    end
    properties (SetAccess = private)
        NumChannels
        DeviceID
        CurrentSample
        TotalSamples
        BitsPerSample
        Type = 'ffaudiorecorder'
        Running = matlab.lang.OnOffSwitchState('off')
    end
    properties (Access = private)
        AudioData double
        FfmpegProcess
        JavaRuntime
        FfmpegInputStream
        FfmpegOutputStream
        FfmpegErrorStream
        FfmpegRawCarry
        FfmpegReadTimer timer
        TimerStop = false
    end
    methods
        function obj = ffaudiorecorder(Fs, nBits, nChannels, ID)
            arguments
                Fs double = 8000
                nBits {mustBeMember(nBits, [8, 16, 24])} = 16
                nChannels {mustBeMember(nChannels, [1, 2])} = 1
                ID {mustBeInteger} = -1
            end
            checkFFmpeg("CheckFFplay", false, "CheckFFmpeg", true, "CheckFFprobe", false, "IssueError", true);
            obj.SampleRate = Fs;
            obj.BitsPerSample = nBits;
            obj.NumChannels = nChannels;
            obj.DeviceID = ID;
            obj.AudioData = zeros(0, obj.NumChannels);
            obj.JavaRuntime = java.lang.Runtime.getRuntime();
        end
        function isrecording = isrecording(obj)
            isrecording = obj.Running;
        end
        function pause(obj) %#ok<MANU>
        end
        function obj = record(obj, blocking)
            arguments
                obj ffaudiorecorder
                blocking logical = false
            end
            audio_devices = obj.listAudioDevices();
            if isempty(audio_devices)
                error('No audio devices found!')
            elseif length(audio_devices) > 1
                warning('More than one audio device found (using the first one):');
                disp(audio_devices);
            end

            command = sprintf( ...
                [ ...
                'ffmpeg -hide_banner -loglevel warning ' ...
                '-f dshow ' ...
                '-i audio="%s" ' ...
                '-ac %d ' ...
                '-ar %d ' ...
                '-f s16le ' ...
                '-acodec pcm_s16le ' ...
                'pipe:1' ...
                ], ...
                audio_devices{1}, obj.NumChannels, obj.SampleRate);
            obj.FfmpegProcess = obj.JavaRuntime.exec(command);
            obj.FfmpegInputStream = java.io.BufferedInputStream(obj.FfmpegProcess.getInputStream(), 1e6);
            obj.FfmpegOutputStream = obj.FfmpegProcess.getOutputStream();
            obj.Running = true;
            obj.FfmpegReadTimer = timer( ...
                'ExecutionMode','fixedSpacing', ...
                'Period',obj.TimerPeriod, ...
                'TimerFcn',@(~,~)appendFromStream(obj) ...
                );
            start(obj.FfmpegReadTimer);
            if blocking
                obj.FfmpegProcess.waitFor();
            end
        end
        function recordblocking(obj)
            obj.record(true);
        end
        function resume(obj) %#ok<MANU>
            warning('Sorry, ffaudiorecorder does not currently support pausing/resuming audio playback.')
        end
        function stop(obj)
            if ~obj.Running
                return
            end
            obj.FfmpegOutputStream.write(uint8('q'));  % 'q' tells ffmpeg to quit
            obj.FfmpegOutputStream.flush();
            obj.FfmpegOutputStream.close();

            stop(obj.FfmpegReadTimer);
            delete(obj.FfmpegReadTimer);
            obj.Running = false;
       end
        function y = getaudiodata(obj)
            y = obj.AudioData;
        end
        function getplayer(obj) %#ok<MANU>
        end
    end
    methods (Access = private)
        function appendFromStream(obj)
            % Read whatever is available without blocking too long
            buf = zeros(1, 100);
            for k = 1:100
                buf(k) = obj.FfmpegInputStream.read();
            end
            % Convert raw s16le → int16 → double in [-1,1)
            % nRead should be multiple of 2*NumChannels; if not, keep a carryover buffer.
            % by = buf(1:nRead);
            % Append to a carryover to maintain frame alignment
            obj.FfmpegRawCarry = [obj.FfmpegRawCarry, buf];
            bytesPerFrame = 2*obj.NumChannels;
            nFull = floor(numel(obj.FfmpegRawCarry)/bytesPerFrame)*bytesPerFrame;
            fullBytes = obj.FfmpegRawCarry(1:nFull);
            obj.FfmpegRawCarry = obj.FfmpegRawCarry(nFull+1:end);
    
            if ~isempty(fullBytes)
                % s = typecast(uint8(fullBytes), 'int16');   % interleaved
                % s = double(s) / 32768;                     % normalize
                % s = reshape(s, obj.NumChannels, []).';     % [N x C]
                obj.AudioData = [obj.AudioData; fullBytes'];        % grow (consider prealloc/chunking)
            end
        end
    end
    methods (Static)
        function audio_devices = listAudioDevices()
            command = 'ffmpeg -hide_banner -list_devices true -f dshow -i ""';
            [~, cmdout] = system(command);
            device_info = regexp(cmdout, '\[dshow\ @\ [a-zA-Z0-9]+\]\ \"(.*)\"\ \((.*)\)', 'tokens', 'dotexceptnewline');
            audio_devices = {};
            for dev_idx = 1:length(device_info)
                name = device_info{dev_idx}{1};
                type = device_info{dev_idx}{2};
                if strcmp(type, 'audio')
                    audio_devices{end+1} = name; %#ok<AGROW>
                end
            end
        end
    end
end
% 
% function msg = readStream(stream, nBytes)
%     arguments
%         stream
%         nBytes = Inf
%     end
% 
%     msg = [];
%     c = 0;
%     while true
%         byte = stream.read();
%         if byte == -1
%             stream.close();
%             return
%         else
%             msg(end + 1) = byte;
%             c = c + 1;
%             if c > nBytes
%                 break
%             end
%         end
%     end
% end

