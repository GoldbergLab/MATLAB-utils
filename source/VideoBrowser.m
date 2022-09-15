classdef VideoBrowser < handle
    % VideoBrowser A class representing a simple graphical video browser
    %   This class creates a window where a video frame is displayed.
    %       A separate axes contains a 1D graph representing some value for
    %       each frame. Moving the mouse over this navigational axes causes
    %       the video frame to update to the corresponding frame number.
    properties (Access = private)
        VideoFrame                                          % An image object containing the video frame image
        FrameMarker         matlab.graphics.primitive.Line  % A line on the NavigationAxes marking what frame is displayed
        FrameNumberMarker   matlab.graphics.primitive.Text  % Text on the NavigationAxes indicating what frame number is displayed
    end
    properties
        MainFigure          matlab.ui.Figure            % The main figure window
        VideoAxes           matlab.graphics.axis.Axes   % Axes for displaying the video frame
        NavigationAxes      matlab.graphics.axis.Axes   % Axes for displaying the 1D metric
    end
    properties (SetObservable)
        VideoData = []                  % The video data itself, a n x h x w double or uint8 array,
        NavigationData = []             % The 1D navigational data, a 1 x n array
        NavigationDataFunction = []     % A function handle that takes video data as an argument, and returns navigation data
        NavigationColor = []            % A color specification for the navigation data. See the color argument in the scatter function.
        CurrentFrameNum = 1             % An integer representing the current frame number
    end
    methods
        function obj = VideoBrowser(VideoData, NavigationDataOrFcn, NavigationColor)
            % Construct a new VideoBrowser object.
            %   VideoData = a N x H x W double or uint8 array, where N =
            %       the number of frames, H and W are the height and width
            %       of each frame
            %   NavigationDataOrFcn = either
            %       A 1 x N array, to be plotted in the NavigationAxes
            %       A function handle which takes N x H x W VideoData array
            %           as an argument and returns a 1 x N array as a
            %           result, to be plotted in the NavigationAxes
            %       An empty array, which results in blank NavigationAxes
            %       Omitted, which results in blank NavigationAxes
            %   NavigationColor = a color specification for the points in
            %       the NavigationAxes scatter plot. See the color argument
            %       for the scatter function for documentation.
            
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
            % Create & prepare the graphics containers (the figure & axes)
            
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
            % Update the displayed video frame based on the current
            %   VideoData and CurrentFrameNumber
            
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
            % Clear the NavigtationAxes
            
            cla(obj.NavigationAxes);
        end
        function drawNavigationData(obj)
            % Draw the NavigationData on the NavigationAxes. If only a
            %   NavigationDataFunction is provide, it will be used here to
            %   generate NavigationData
            
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
            % Extract the current frame's video data
            
            frameData = squeeze(obj.VideoData(obj.CurrentFrameNum, :, :));
        end
        function numFrames = getNumFrames(obj)
            % Determine the number of frames in the current VideoData
            
            numFrames = size(obj.VideoData, 1);
        end
        function updateFrameMarker(obj)
            % Update the FrameMarker and FrameNumberMarker on the
            %   NavigationAxes to reflect the CurrentFrameNumber
            
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
            % Setter for the VideoData property
            
            obj.VideoData = newVideoData;
            obj.updateVideoFrame();
        end
        function set.NavigationDataFunction(obj, newNavigationDataFunction)
            % Setter for the NavigationDataFunction property
            
            obj.NavigationDataFunction = newNavigationDataFunction;
            obj.drawNavigationData();
        end
        function set.NavigationData(obj, newNavigationData)
            % Setter for the NavigationData property
            
            obj.NavigationData = newNavigationData;
            obj.drawNavigationData();
        end
        function set.NavigationColor(obj, newNavigationColor)
            % Setter for the NavigationColor property
            
            obj.NavigationColor = newNavigationColor;
            obj.drawNavigationData();
        end
        function set.CurrentFrameNum(obj, newFrameNum)
            % Setter for the CurrrentFrameNum property
            
            obj.CurrentFrameNum = mod(newFrameNum - 1, obj.getNumFrames()) + 1;
            obj.updateVideoFrame();
            obj.updateFrameMarker();
        end
        function inside = inNavigationAxes(obj, x, y)
            % Determine if the given figure coordinates fall within the
            %   borders of the NavigationAxes or not.
            
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
            % Convert a figure x coordinate to frame number based on the
            %   NavigationAxes position.
            
            frameNum = round((x - obj.NavigationAxes.Position(1)) * diff(obj.NavigationAxes.XLim) / obj.NavigationAxes.Position(3));
        end
        function MouseMotionHandler(obj, src, ~)
            % Handle mouse motion events
            
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inNavigationAxes(x, y)
                frameNum = obj.mapFigureXToFrameNum(x);
                obj.CurrentFrameNum = frameNum;
            end
        end
    end
end