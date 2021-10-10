classdef VideoLoader < handle
    properties
        Path = ''
        VideoData = []
        LoadComplete = false
        VideoDataQueue = parallel.pool.DataQueue.empty
        Started = false;
        Complete = false;
        VideoSize = []
        VideoType
        NumLoaded = NaN
        Progress = NaN
        LoadFuture
    end
    methods
        function self = VideoLoader(videoPath)
            self.Path = videoPath;
        end
        function load(self)
            disp('Initiating load...')
            if isempty(self.VideoDataQueue)
                self.VideoDataQueue = parallel.pool.DataQueue();
            end
            afterEach(self.VideoDataQueue, @self.store);
            self.LoadFuture = parfeval(@self.backgroundLoad, 0, self.VideoDataQueue);
            disp('...load initiated.')
        end
        function store(self, msg)
            if iscell(msg)
                if strcmp(msg{1}, 'start')
                    self.Started = 1;
                    self.Complete = 0;
                    self.Progress = 0;
                    self.NumLoaded = 0;
                    self.VideoSize = msg{2};
                    self.VideoType = msg{3};
                    self.VideoData = zeros(self.VideoSize, self.VideoType);
                elseif strcmp(msg{1}, 'done')
                    self.Complete = 1;
                end
            else
                if isempty(self.VideoData)
                    self.VideoData = zeros(videoSize, videoType);
                end
                self.NumLoaded = self.NumLoaded + 1;
                fprintf('Loaded frame #%d of %d\n', self.NumLoaded, self.VideoSize(3))
                self.Progress = self.NumLoaded / self.VideoSize(3);
                self.VideoData(:, :, self.NumLoaded) = msg;
            end
        end
        function backgroundLoad(self, queue)
            reader = VideoReader(self.Path);
            try
                videoSize = [reader.Height, reader.Width, reader.NumberOfFrames];
            catch ME
                % NumberOfFrames has been changed to NumFrames in later
                % versions of MATLAB
                try
                    videoSize = [reader.Height, reader.Width, reader.NumFrames];
                catch ME2
                    % Give up on getting # of frames
                    videoSize = [reader.Height, reader.Width, 0];
                end
            end
            % Recreate reader (necessary after getting # of frames);
            reader = VideoReader(self.Path);
            frameCount = 0;
            framesLeft = true;
            while framesLeft
                if reader.hasFrame()
                    try
                        frame = readFrame(reader);
                        if frameCount == 0
                            queue.send({'start', videoSize, class(frame)});
                        end
                        frameCount = frameCount + 1;
                        queue.send(frame);
                    catch ME
                        framesLeft = false;
                        break;
                    end
                else
                    framesLeft = false;
                    break;
                end
            end
            queue.send({'done'});
        end
        function progress = getProgress(self)
        end
        function isComplete = isLoadComplete(self)
        end
        function setProgress(self, p)
            self.Progress = p;
        end
    end
end