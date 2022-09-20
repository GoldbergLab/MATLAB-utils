classdef VideoBrowser < handle
    % VideoBrowser A class representing a simple graphical video browser
    %   This class creates a window where a video frame is displayed.
    %       A separate axes contains a 1D graph representing some value for
    %       each frame. Moving the mouse over this navigational axes causes
    %       the video frame to update to the corresponding frame number.
    %
    %   Keyboard commands:
    %     space =                    play/stop video
    %     right/left arrow =         increment/decrement frame number by 1
    %       frame, or if video is playing, increase/decrease playback speed
    %     shift-right/left arrow =   increment/decrement frame number by 10
    %       frames
    %     control-right/left arrow = increment/decrement frame number by 
    %       100 frames
    %     control-g =                jump to a specific frame number
    %
    properties (Access = private)
        VideoFrame              matlab.graphics.primitive.Image % An image object containing the video frame image
        FrameMarker             matlab.graphics.primitive.Line  % A line on the NavigationAxes marking what frame is displayed
        FrameNumberMarker       matlab.graphics.primitive.Text  % Text on the NavigationAxes indicating what frame number is displayed
        PlayJob                 timer                           % A timer for playing the video
        PlayIncrement           double = 1                      % Number of frames the play timer will advance by on each call.
        NumColorChannels        double                          % Number of color channels in the video (1 for grayscale, 3 for color)
        NavigationRedrawEnable  logical = false                 % Enable or disable navigation redraw
    end
    properties
        MainFigure          matlab.ui.Figure            % The main figure window
        VideoAxes           matlab.graphics.axis.Axes   % Axes for displaying the video frame
        NavigationAxes      matlab.graphics.axis.Axes   % Axes for displaying the 1D metric
    end
    properties (SetObservable)
        VideoData = []                  % The video data itself, a N x H x W double or uint8 array,
        NavigationData = []             % The 1D navigational data, a 1 x N array
        NavigationDataFunction = []     % A function handle that takes video data as an argument, and returns navigation data
        NavigationColor = []            % A color specification for the navigation data. See the color argument in the scatter function.
        CurrentFrameNum = 1             % An integer representing the current frame number
        PlaybackSpeed = 25              % Playback speed in fps
        Colormap = colormap()           % Colormap for NavigationAxes
    end
    methods
        function obj = VideoBrowser(VideoData, NavigationDataOrFcn, NavigationColor, NavigationColormap)
            % Construct a new VideoBrowser object.
            %   VideoData = a N x H x W double or uint8 array, where N =
            %       the number of frames, H and W are the height and width
            %       of each frame, or a N x H x W x 3 array, for videos
            %       with color.
            %   NavigationDataOrFcn = either
            %       1. A 1 x N array, to be plotted in the NavigationAxes
            %       2. A function handle which takes N x H x W (x 3)
            %           VideoData array as an argument and returns a 1 x N 
            %           array as a result, to be plotted in the 
            %           NavigationAxes
            %       4. A string referring to one of the predefined
            %           functions:
            %           - 'sum' - plot sum of pixel values in each frame
            %           - 'diff' - plot change in total pixel values in
            %               each frame
            %           - 'compactness' - plot measure of how compact the
            %               blobs of pixel values are
            %       3. An empty array, or omitted, which results in blank 
            %           NavigationAxes
            %   NavigationColor = a color specification for the points in
            %       the NavigationAxes scatter plot. See the color argument
            %       for the scatter function for documentation.
            
            obj.createDisplayArea();

            if ~exist('VideoData', 'var') || isempty(VideoData)
                VideoData = [];
            end
            if ~exist('NavigationDataOrFcn', 'var') || isempty(NavigationDataOrFcn)
                NavigationDataOrFcn = [];
            end
            if ~exist('NavigationColor', 'var') || isempty(NavigationColor)
                NavigationColor = 'black';
            end
            if ~exist('NavigationColormap', 'var') || isempty(NavigationColormap)
                NavigationColormap = colormap(obj.NavigationAxes);
            end

            if length(size(VideoData)) == 4
                if size(VideoData, 4) ~= 3
                    error('Incorrect video color dimension size: 4D videos must have the dimension order N x H x W x 3.');
                end
                obj.NumColorChannels = 3;
            else
                obj.NumColorChannels = 1;
            end
            
            obj.VideoData = VideoData;

            % Temporarily disable drawing navigation to prevent all the
            % setters from triggering a redraw multiple times
            obj.NavigationRedrawEnable = false;
            
            obj.Colormap = NavigationColormap;
            obj.NavigationColor = NavigationColor;
            switch class(NavigationDataOrFcn)
                case 'function_handle'
                    obj.NavigationData = [];
                    obj.NavigationDataFunction = NavigationDataOrFcn;
                case 'char'
                    switch obj.NumColorChannels
                        case 3
                            sumDims = [2, 3, 4];
                        case 1
                            sumDims = [2, 3];
                        otherwise
                            error('Wrong number of color channels: %d', obj.NumColorChannels);
                    end
                    switch NavigationDataOrFcn
                        case 'sum'
                            obj.NavigationData = [];
                            obj.NavigationDataFunction = @(videoData)sum(videoData, sumDims);
                        case 'diff'
                            obj.NavigationData = [];
                            obj.NavigationDataFunction = @(videoData)smooth(sum(diff(videoData, 1), sumDims), 10);
                        case 'compactness'
                            obj.NavigationData = [];
                            obj.NavigationDataFunction = @(videoData)sum(videoData, sumDims) ./ sum(getMaskSurface(videoData), sumDims);
                        otherwise
                            error('Unrecognized named navigation data function: %s.', NavigationDataOrFcn);
                    end
                case {'double', 'uint8'}
                    obj.NavigationData = NavigationDataOrFcn;
                    obj.NavigationDataFunction = [];
                otherwise
                    error('NavigationDataOrFcn argument must be of type function_handle, char, double, or uint8, not %s.', class(NavigationDataOrFcn));
            end
            obj.NavigationRedrawEnable = true;
            obj.drawNavigationData();

        end
        function playVideo(obj)
            warning('off', 'MATLAB:TIMER:RATEPRECISION');
            if obj.PlaybackSpeed < 0
                obj.PlayIncrement = -1;
            else
                obj.PlayIncrement  = 1;
            end
            delete(obj.PlayJob);
            obj.PlayJob = timer();
            obj.PlayJob.TimerFcn = @(~, ~)obj.playFcn();
            obj.PlayJob.Period = 1 / abs(obj.PlaybackSpeed);
            obj.PlayJob.ExecutionMode = 'fixedRate';
            obj.PlayJob.start();
            warning('on', 'MATLAB:TIMER:RATEPRECISION');
        end
        function playFcn(obj)
            % Display a new frame of the video while in play mode
            try
                obj.incrementFrame(obj.PlayIncrement);
                drawnow;
            catch me
                if strcmp(me.identifier, 'images:imshow:invalidAxes')
                    % Axes are missing, we're probably shutting down.
                    % Stop and delete timer.
                    stop(obj.PlayJob);
                    delete(obj.PlayJob);
                else
                    throw(me);
                end
            end
        end
        function stopVideo(obj)
            stop(obj.PlayJob);
            delete(obj.PlayJob);
        end
        function playing = isPlaying(obj)
            playing = ~isempty(obj.PlayJob) && isvalid(obj.PlayJob) && strcmp(obj.PlayJob.Running, 'on');
        end
        function incrementFrame(obj, delta)
            obj.CurrentFrameNum = obj.CurrentFrameNum + delta;
        end
        function deleteDisplayArea(obj)
            delete(obj.VideoAxes);
            delete(obj.NavigationAxes);
            delete(obj.MainFigure);
        end
        function regenerateGraphics(obj)
            % Recreate graphics in case it gets closed
            obj.deleteDisplayArea();
            obj.createDisplayArea();
            obj.drawNavigationData();
            obj.updateFrameMarker();
            obj.updateVideoFrame();
        end
        function createDisplayArea(obj)
            % Create & prepare the graphics containers (the figure & axes)
            
            % Delete graphics containers in case they already exist
            obj.deleteDisplayArea();
            
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
            obj.MainFigure.KeyPressFcn = @obj.KeyPressHandler;
            obj.MainFigure.SizeChangedFcn = @obj.ResizeHandler;
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
        function color = getNavigationColorPoint(obj, frameNum)
            if ischar(obj.NavigationColor)
                % Single color string provided
                color = obj.NavigationColor;
            elseif isnumeric(obj.NavigationColor)
                if isrow(obj.NavigationColor) && length(obj.NavigationColor) == 3
                    % Single RGB triplet provided
                    color = obj.NavigationColor;
                elseif size(obj.NavigationColor, 2) == 3 && size(obj.NavigationColor, 1) > 1
                    % 3-column array of RGB triplets provided, one color
                    % per row
                    color = obj.NavigationColor(frameNum, :);
                elseif isvector(obj.NavigationColor)
                    % Color palette index has been provided
                    color = obj.NavigationAxes.Colormap(frameNum, :);
                end
            end
        end
        function drawNavigationData(obj)
            % Draw the NavigationData on the NavigationAxes. If only a
            %   NavigationDataFunction is provide, it will be used here to
            %   generate NavigationData
            
            if ~obj.NavigationRedrawEnable
                return;
            end
            
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
            obj.clearNavigationData();
            p = plot(obj.NavigationAxes, [1, length(navigationData)], obj.NavigationAxes.YLim);
            delete(p);
            obj.NavigationAxes.Colormap = obj.Colormap;
            linec(1:length(navigationData), navigationData, 'Color', obj.NavigationColor, 'Parent', obj.NavigationAxes);
%             scatter(1:length(navigationData), navigationData, 1, obj.NavigationColor, '.', 'Parent', obj.NavigationAxes);
            obj.NavigationAxes.XLim = [1, length(navigationData)];
        end
        function frameData = getCurrentVideoFrameData(obj)
            % Extract the current frame's video data
            switch obj.NumColorChannels
                case 3
                    frameData = squeeze(obj.VideoData(obj.CurrentFrameNum, :, :, :));
                case 1
                    frameData = squeeze(obj.VideoData(obj.CurrentFrameNum, :, :));
                otherwise
                    error('Wrong number of color channels: %d', obj.NumColorChannels);
            end
        end
        function numFrames = getNumFrames(obj)
            % Determine the number of frames in the current VideoData
            
            numFrames = size(obj.VideoData, 1);
        end
        function updateFrameMarker(obj, varargin)
            % Update the FrameMarker and FrameNumberMarker on the
            %   NavigationAxes to reflect the CurrentFrameNumber
            if nargin == 2
                redraw = varargin{1};
                if redraw
                    delete(obj.FrameMarker);
                end
            end
            x = obj.CurrentFrameNum;
            if isempty(obj.FrameMarker) || ~isvalid(obj.FrameMarker)
                obj.FrameMarker = line([x, x], obj.NavigationAxes.YLim, 'Parent', obj.NavigationAxes, 'Color', 'black');
            else
                obj.FrameMarker.XData = [x, x];
            end
            if isempty(obj.FrameNumberMarker) || ~isvalid(obj.FrameNumberMarker)
                obj.FrameNumberMarker = text(obj.NavigationAxes, x + 20, mean(obj.NavigationAxes.YLim), num2str(x));
            else
                obj.FrameNumberMarker.Position(1) = x + 20;
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
        function set.PlaybackSpeed(obj, fps)
            if abs(fps) > 1000
                fps = 1000 * sign(fps);
            end
            if abs(fps) <= 1
                fps = 1 * sign(fps);
            end
            obj.PlaybackSpeed = fps;
            % If timer is already running, restart it
            if obj.isPlaying()
                obj.stopVideo();
                obj.playVideo();
            end
        end
        function set.Colormap(obj, colormap)
            obj.Colormap = colormap;
            obj.drawNavigationData();
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
        function KeyPressHandler(obj, src, event)
            switch event.Key
                case 'space'
                    if obj.isPlaying()
                        obj.stopVideo();
                    else
                        obj.playVideo();
                    end
                case 'rightarrow'
                    if obj.isPlaying()
                        obj.PlaybackSpeed = obj.PlaybackSpeed + 10;
                    else
                        if any(strcmp(event.Modifier, 'shift'))
                            delta = 10;
                        elseif any(strcmp(event.Modifier, 'control'))
                            delta = 100;
                        else
                            delta = 1;
                        end
                        obj.incrementFrame(delta);
                    end
                case 'leftarrow'
                    if obj.isPlaying()
                        obj.PlaybackSpeed = obj.PlaybackSpeed - 10;
                    else
                        if any(strcmp(event.Modifier, 'shift'))
                            delta = 10;
                        elseif any(strcmp(event.Modifier, 'control'))
                            delta = 100;
                        else
                            delta = 1;
                        end
                        obj.incrementFrame(-delta);
                    end
                case 'g'
                    if any(strcmp(event.Modifier, 'control'))
                        % control-g pressed
                        frame = inputdlg('Enter frame number:', 'Goto frame number');
                        if ~isempty(frame)
                            obj.CurrentFrameNum = str2double(frame);
                        end
                    end
            end
        end
        function ResizeHandler(obj, ~, ~)
            obj.updateVideoFrame();
            obj.updateFrameMarker(true);
        end
        function delete(obj)
            if isvalid(obj.PlayJob)
                stop(obj.PlayJob);
            end
            delete(obj.PlayJob);
            obj.deleteDisplayArea();
        end
    end
end