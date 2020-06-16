classdef AVHolder < handle
    properties (SetAccess = private)
        VideoData = []
        AudioData = []
        Future = []
        Figure = []
        Axes = []
        Image = []
        NumFrames = 0
        k = 1
        stdout
    end
    properties
        Path
    end
    methods (Access = private)
        function receiveData(obj, varargin)
            [~, avData] = fetchNext(obj.Future);
            obj.VideoData = avData.VideoData;
            obj.AudioData = avData.AudioData;
        end
        function createGraphics(obj)
            if ~isempty(obj.Figure)
                delete(obj.Figure)
            end
            obj.Figure = figure();
            obj.Axes = axes('Parent', obj.Figure);
            obj.Image = imshow([], 'Parent', obj.Axes);
        end
    end
    methods
        function obj =          AVHolder(path)
            obj.Path = path;
            obj.stdout = parallel.pool.DataQueue();
            afterEach(obj.stdout, @disp)
        end
        function                load(obj)
%             if ~isempty(obj.Future)
%                 switch obj.Future.State
%                     case 'finished'
%                         % Already finished loading
%                         return
%                     otherwise
%                         % It's working
%                 end
%             end
            obj.Future = parfeval(@loadAVData, 1, obj.Path, obj.stdout);
            afterEach(obj.Future, @obj.receiveData, 0);
        end
        function                unload(obj)
            delete(obj.Figure)
        end
        function videoData =    getVideoData(obj)
            videoData = obj.VideoData;
        end
        function audioData =    getAudioData(obj)
            audioData = obj.AudioData;
        end
        function                showFrame(obj, frameNum)
            if isempty(obj.Figure)
                obj.createGraphics();
            end
            if isempty(obj.VideoData)
                % Video data not loaded yet
                return
            end
            obj.Image.CData = obj.VideoData(
        end
    end
end