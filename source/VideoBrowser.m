classdef VideoBrowser < handle
    properties (Access = private)
        VideoFrame
        FrameMarker         matlab.graphics.primitive.Line
        FrameNumberMarker   matlab.graphics.primitive.Text
    end
    properties
        MainFigure          matlab.ui.Figure
        VideoAxes           matlab.graphics.axis.Axes
        NavigationAxes      matlab.graphics.axis.Axes
    end
    properties (SetObservable)
        VideoData = []
        NavigationData = []
        NavigationDataFunction = []
        NavigationColor = []
        CurrentFrameNum = 1
    end
    methods
        function obj = VideoBrowser(VideoData, NavigationDataOrFcn, NavigationColor)
            if ~exist('VideoData', 'var') || isempty(VideoData)
                VideoData = [];
            end
            if ~exist('NavigationDataOrFcn', 'var') || isempty(NavigationDataOrFcn)
                NavigationDataOrFcn = [];
            end
            if ~exist('NavigationColor', 'var') || isempty(NavigationColor)
                NavigationColor = 'black';
            end

            obj.createDisplayArea();

            obj.VideoData = VideoData;

            obj.NavigationColor = NavigationColor;
            switch class(NavigationDataOrFcn)
                case 'function_handle'
                    obj.NavigationData = [];
                    obj.NavigationDataFunction = NavigationDataOrFcn;
                case 'char'
                    switch NavigationDataOrFcn
                        case 'sum'
                            obj.NavigationData = [];
                            obj.NavigationDataFunction = @(videoData)sum(videoData, [2, 3]);
                        otherwise
                            error('Unrecognized named navigation data function: %s.', NavigationDataOrFcn);
                    end
                case {'double', 'uint8'}
                    obj.NavigationData = NavigationDataOrFcn;
                    obj.NavigationDataFunction = [];
                otherwise
                    error('NavigationDataOrFcn argument must be of type function_handle, char, double, or uint8, not %s.', class(NavigationDataOrFcn));
            end
            
        end
        function createDisplayArea(obj)
            % Create graphics containers
            obj.MainFigure =     figure('Units', 'normalized');
            obj.VideoAxes =      axes(obj.MainFigure, 'Units', 'normalized', 'Position', [0.05, 0.2, 0.9, 0.75]);
            obj.NavigationAxes = axes(obj.MainFigure, 'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.1]);

            % Style graphics containers
            obj.MainFigure.ToolBar = 'none';
            obj.MainFigure.MenuBar = 'none';
            obj.MainFigure.NumberTitle = 'off';
            obj.MainFigure.Name = 'Video Browser';
            obj.NavigationAxes.Toolbar.Visible = 'off';
            obj.NavigationAxes.YTickMode = 'manual';
            obj.NavigationAxes.YTickLabelMode = 'manual';
            obj.NavigationAxes.YTickLabel = [];
            obj.NavigationAxes.YTick = [];
            axis(obj.NavigationAxes, 'off');

            % Configure callbacks
            obj.MainFigure.WindowButtonMotionFcn = @obj.MouseMotionHandler;
            obj.MainFigure.BusyAction = 'cancel';
        end
        function updateVideoFrame(obj)
            frameData = obj.getCurrentVideoFrameData();
            if isempty(obj.VideoFrame) || ~isvalid(obj.VideoFrame)
                % First time, create image
                obj.VideoFrame = imshow(frameData, 'Parent', obj.VideoAxes);
            else
                % Not first time, change image data
                obj.VideoFrame.CData = frameData;
            end
        end
        function clearNavigationData(obj)
            cla(obj.NavigationAxes);
        end
        function drawNavigationData(obj)
            if isempty(obj.NavigationData)
                if isempty(obj.NavigationDataFunction)
                    % No navigation data or a function to create it.
                    if isempty(obj.VideoData)
                        % No navigation data, function, or video!
                        return
                    end
                    navigationData = zeros(1, obj.getNumFrames());
                else
                    if isempty(obj.VideoData)
                        return;
                    end
                    navigationData = obj.NavigationDataFunction(obj.VideoData);
                end
            else
                navigationData = obj.NavigationData;
            end
            
            scatter(1:length(navigationData), navigationData, 1, obj.NavigationColor, '.', 'Parent', obj.NavigationAxes);
            obj.NavigationAxes.XLim = [1, length(navigationData)];
        end
        function frameData = getCurrentVideoFrameData(obj)
            frameData = squeeze(obj.VideoData(obj.CurrentFrameNum, :, :));
        end
        function numFrames = getNumFrames(obj)
            numFrames = size(obj.VideoData, 1);
        end
        function updateFrameMarker(obj)
            x = obj.CurrentFrameNum;
            if isempty(obj.FrameMarker) || ~isvalid(obj.FrameMarker)
                obj.FrameMarker = line([x, x], obj.NavigationAxes.YLim, 'Parent', obj.NavigationAxes);
            else
                obj.FrameMarker.XData = [x, x];
            end
            if isempty(obj.FrameNumberMarker) || ~isvalid(obj.FrameNumberMarker)
                obj.FrameNumberMarker = text(obj.NavigationAxes, x, mean(obj.NavigationAxes.YLim), num2str(x));
            else
                obj.FrameNumberMarker.Position(1) = x;
                obj.FrameNumberMarker.String = num2str(x);
            end
        end
        function set.VideoData(obj, newVideoData)
            obj.VideoData = newVideoData;
            obj.updateVideoFrame();
        end
        function set.NavigationDataFunction(obj, newNavigationDataFunction)
            obj.NavigationDataFunction = newNavigationDataFunction;
            obj.drawNavigationData();
        end
        function set.NavigationData(obj, newNavigationData)
            obj.NavigationData = newNavigationData;
            obj.drawNavigationData();
        end
        function set.NavigationColor(obj, newNavigationColor)
            obj.NavigationColor = newNavigationColor;
            obj.drawNavigationData();
        end
        function set.CurrentFrameNum(obj, newFrameNum)
            obj.CurrentFrameNum = mod(newFrameNum - 1, obj.getNumFrames()) + 1;
            obj.updateVideoFrame();
            obj.updateFrameMarker();
        end
        function inside = inNavigationAxes(obj, x, y)
            if y < obj.NavigationAxes.Position(2)
                inside = false;
            elseif y > obj.NavigationAxes.Position(2) + obj.NavigationAxes.Position(4)
                inside = false;
            elseif (x < obj.NavigationAxes.Position(1))
                inside = false;
            elseif x > obj.NavigationAxes.Position(1) + obj.NavigationAxes.Position(3)
                inside = false;
            else
                inside = true;
            end
        end
        function frameNum = mapFigureXToFrameNum(obj, x)
            frameNum = round((x - obj.NavigationAxes.Position(1)) * diff(obj.NavigationAxes.XLim) / obj.NavigationAxes.Position(3));
        end
        function MouseMotionHandler(obj, src, ~)
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inNavigationAxes(x, y)
                frameNum = obj.mapFigureXToFrameNum(x);
                obj.CurrentFrameNum = frameNum;
            end
        end
    end
end