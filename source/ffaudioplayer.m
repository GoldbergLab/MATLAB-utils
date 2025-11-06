classdef ffaudioplayer < handle & matlab.mixin.SetGet
    properties
        SampleRate
        StartFcn = ''
        StopFcn = ''
        TimerFcn = ''
        TimerPeriod = 0.05
        Tag = ''
        UserData = []
    end
    properties (SetAccess = immutable)
        NumChannels
        DeviceID
        CurrentSample
        TotalSamples
        BitsPerSample
        Running = matlab.lang.OnOffSwitchState('off')
        Type = 'ffaudioplayer'
    end
    properties (Access = private)
        AudioData double
        IsPlaying = false
        FfplayProcess
        JavaRuntime
    end
    methods
        function obj = ffaudioplayer(Y, Fs, nBits)
            arguments
                Y double
                Fs double = 44100
                nBits {mustBeMember(nBits, [8, 16, 24])} = 16
            end
            checkFFmpeg("CheckFFplay", true, "CheckFFmpeg", false, "CheckFFprobe", false, "IssueError", true);
            obj.AudioData = Y;
            obj.SampleRate = Fs;
            obj.BitsPerSample = nBits;
        end
        function isplaying = isplaying(obj)
            isplaying = obj.IsPlaying;
        end
        function pause(obj)
        end
        function obj = play(obj, blocking)
            arguments
                obj ffaudioplayer
                blocking logical = false
            end
            filepath = [tempname(), '.wav'];
            audiowrite(filepath, obj.AudioData, obj.SampleRate);
            command = sprintf('ffplay -nodisp -autoexit -i "%s"', filepath);
            obj.JavaRuntime = java.lang.Runtime.getRuntime();
            obj.FfplayProcess = obj.JavaRuntime.exec(command);
            if blocking
                obj.FfplayProcess.waitFor();
                status = obj.FfplayProcess.exitValue();
                delete(filepath);
                if status ~= 0
                    error('ffplay error');
                end
            end
        end
        function playblocking(obj)
            obj.play(true);
        end
        function resume(obj)
            warning('Sorry, ffaudioplayer does not currently support pausing/resuming audio playback.')
        end
        function stop(obj)
            obj.FfplayProcess.destroy()
        end
    end
end