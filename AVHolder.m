classdef AVHolder < handle
    % A class for loading, holding, and displaying audio/video
    %   AVHolder is a class mean to simplify the process of loading,
    %   accessing, and playing audio/video data. It supports both blocking
    %   and non-blocking loading of audio/video from disk.
    properties (Access = private)
        Future              parallel.FevalFuture
        Figure              matlab.ui.Figure
        Axes                matlab.graphics.axis.Axes
        Image               matlab.graphics.primitive.Image
        NumFrames = 0
        LastSoundFrame = 0
        stdout              parallel.pool.DataQueue
        Timer               timer
        FrameRate = 0.1
        FramesPerAudioChunk = 10   % Number of video frames per audio chunk
        NullVideoInfo = struct('W', NaN, 'H', NaN, 'C', NaN, 'N', NaN, 'Size', [], 'FrameRate', NaN)
        NullAudioInfo = struct('N', NaN, 'C', NaN, 'Size', [], 'SampleRate', NaN)
    end
    properties (SetAccess = private)
        Path                char        % Absolute path to the video file
        VideoInfo           struct      % Struct containing information about the loaded video
        AudioInfo           struct      % Struct containing information about the loaded audio
    end
    properties (SetObservable = true, SetAccess = private)
        Loaded                  logical % Logical value indicating if the audio/video has been loaded or not.
        CurrentFrame = 1
        ImageDisplaySize        double  % Size (WxH) of image axes in pixels. If left empty, will default to full resolution.
    end
    properties
        VideoData = []                              % The loaded video data array, shape HxWxCxN (H=height of frame, W=width of frame, C=# color channels, N=# frames)
        AudioData = []                              % The loaded audio data, shape NxC (N=# of samples, C=# of audio channels)
        TimerFcn                function_handle
        Loop                    logical             % A logical value indicating whether playback should loop back to the beginning when it reaches the end (default true)
    end
    methods (Access = private)
        function receiveData(obj, avData)
            obj.VideoData = avData.VideoData;
            obj.AudioData = avData.AudioData;
            [obj.VideoInfo.H, obj.VideoInfo.W, obj.VideoInfo.C, obj.VideoInfo.N] = size(obj.VideoData);
            obj.VideoInfo.Size = [obj.VideoInfo.H, obj.VideoInfo.W, obj.VideoInfo.C, obj.VideoInfo.N];
            obj.VideoInfo.FrameRate = avData.FrameRate;
            [obj.AudioInfo.N, obj.AudioInfo.C] = size(obj.AudioData);
            obj.AudioInfo.Size = [obj.VideoInfo.N, obj.VideoInfo.C];
            obj.AudioInfo.SampleRate = avData.SampleRate;
            obj.Loaded = true;
        end
        function createGraphics(obj, varargin)
            if ~isempty(varargin)
                deleteOld = varargin{1};
            else
                deleteOld = true;
            end
            if ~isempty(obj.Figure)
                if ~deleteOld
                    return
                end
                delete(obj.Figure)
            end
            obj.Figure = figure();
            obj.Figure.CloseRequestFcn = @obj.FigureCloseFcn;
            obj.Axes = axes('Parent', obj.Figure);
            obj.Image = imshow([], 'Parent', obj.Axes);
            addlistener(obj.Figure, 'ObjectBeingDestroyed', @(src, evt)obj.stop());
        end
        function stepAudioAndVideo(obj)
            obj.continueAudio();
            obj.deltaFrame();
            obj.TimerFcn();
        end
        function initializeAudio(obj)
        end
        function continueAudio(obj)
            % If it's time to play the next chunk of audio, do so
            framesSinceLastChunk = mod(obj.CurrentFrame - obj.LastSoundFrame - 1, obj.VideoInfo.N) + 1;
            if framesSinceLastChunk >= obj.FramesPerAudioChunk
                % Time to play next audio chunk
                audioSampleRate = obj.AudioInfo.SampleRate / (obj.Timer.Period * obj.VideoInfo.FrameRate);  % Calculate audio rate adjusted for desired playback framerate
                t = (obj.FramesPerAudioChunk - framesSinceLastChunk + obj.FramesPerAudioChunk) * obj.Timer.Period;
                numSamples = floor(t * obj.AudioInfo.SampleRate);
                startSample = floor(obj.AudioInfo.N * obj.CurrentFrame / obj.VideoInfo.N);
                endSample = startSample + numSamples;
                if endSample <= obj.AudioInfo.N
                    sound(obj.AudioData(startSample:endSample, :), audioSampleRate);
                else
                    sound([obj.AudioData(startSample:end, :); obj.AudioData(1:(mod(endSample-1, obj.AudioInfo.N)+1), :)], audioSampleRate);
                end
                obj.LastSoundFrame = obj.CurrentFrame;
            end
        end
        function FigureCloseFcn(obj, src, evt)
            stop(obj.Timer);
            delete(obj.Timer);
            drawnow();
            delete(obj.Figure);
        end
    end
    methods
        function obj =          AVHolder(path, varargin)
            obj.Loaded = false;
            obj.Loop = true;
            obj.TimerFcn = @NOP;
            obj.VideoInfo = obj.NullVideoInfo;
            obj.AudioInfo = obj.NullAudioInfo;
            obj.Path = getAbsolutePath(path);
            obj.stdout = parallel.pool.DataQueue();
            afterEach(obj.stdout, @disp)
        end
        function frameSize =    getFrameSize(obj)
            frameSize = [obj.VideoInfo.H, obj.VideoInfo.W];
        end
        function numFrames =    getNumFrames(obj)
            numFrames = obj.VideoInfo.N;
        end
        function numChannels =  getNumChannels(obj)
            numChannels = obj.VideoInfo.C;
        end
        function videoSize =    getVideoSize(obj)
            videoSize = [obj.VideoInfo.H, obj.VideoInfo.W, obj.VideoInfo.C, obj.VideoInfo.N];
        end
        function                load(obj, varargin)
            if ~isempty(varargin)
                parallelized = varargin{1};
            else
                parallelized = true;
            end
            if parallelized
                obj.Future = parfeval(@loadAVData, 1, obj.Path, obj.stdout);
                afterAll(obj.Future, @obj.receiveData, 0);
            else
                disp('non-parallel')
                obj.receiveData(loadAVData(obj.Path, obj.stdout));
            end
        end
        function                unload(obj)
            delete(obj.Future)
            delete(obj.Timer);
            delete(obj.Figure)
            obj.VideoData = [];
            obj.AudioData = [];
            obj.VideoInfo = obj.NullVideoInfo;
            obj.AudioInfo = obj.NullAudioInfo;
            obj.Future = obj.Future.empty();
            obj.Figure = obj.Figure.empty();
            obj.Axes = obj.Axes.empty();
            obj.Image = obj.Image.empty();
            obj.NumFrames = 0;
            obj.CurrentFrame = 1;
            obj.Timer = obj.Timer.empty();
        end
        function videoData =    getVideoData(obj)
            videoData = obj.VideoData;
        end
        function audioData =    getAudioData(obj)
            audioData = obj.AudioData;
        end
        function                setImageDisplaySize(obj, size)
            obj.ImageDisplaySize = size;
            if 
        end
        function                deltaFrame(obj, varargin)
            if ~isempty(varargin)
                delta = varargin{1};
            else
                delta = 1;
            end
            obj.CurrentFrame = mod(obj.CurrentFrame + delta - 1, obj.VideoInfo.N) + 1;
            obj.updateFrame();
        end
        function                changeFrame(obj, frameNum)
            obj.CurrentFrame = mod(frameNum - 1, obj.VideoInfo.N) + 1;
            obj.updateFrame();
        end
        function                rewind(obj)
            obj.changeFrame(1);
        end
        function                updateFrame(obj)
            
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                obj.createGraphics();
            end
            if isempty(obj.VideoData)
                % Video data not loaded yet
                return
            end
            obj.Image.CData = obj.VideoData(:, :, :, obj.CurrentFrame);
            drawnow();
        end
        function                play(obj, varargin)
            if ~obj.Loaded
                error('Error - AV data is not loaded yet. Please call ''AVHolder.load'' and wait until load is complete.');
            end
            if length(varargin) >= 1
                frameRate = varargin{1};
            else
                frameRate = obj.VideoInfo.FrameRate;
            end
            if length(varargin) >= 2
                numFrames = varargin{2};
            else
                if obj.Loop
                    numFrames = Inf;
                else
                    numFrames = obj.VideoInfo.N - obj.CurrentFrame;
                    if numFrames == 0
                        numFrames = obj.VideoInfo.N;
                    end
                end
            end
            period = 1/frameRate;
            obj.createGraphics(false);
            stop(obj.Timer);
            delete(obj.Timer);
            obj.Timer = timer();
            obj.Timer.TimerFcn = @(src, evt)obj.stepAudioAndVideo();
            obj.Timer.ExecutionMode = 'fixedRate';
            obj.Timer.Period = round(period, 3);
            obj.Timer.UserData.obj = obj;
            obj.Timer.StartFcn = @(src, evt)obj.initializeAudio;
            obj.Timer.TasksToExecute = numFrames;
            start(obj.Timer)
        end
        function                stop(obj)
            if isvalid(obj.Timer)
                stop(obj.Timer);
            end
        end
        function                delete(obj)
            if isvalid(obj.Timer)
                stop(obj.Timer);
            end
            obj.unload();
            delete(obj);
        end
    end
end