classdef VideoBrowser < handle
    % VideoBrowser A class representing a simple graphical video browser
    %   This class creates a window where a video frame is displayed.
    %       A separate axes contains a 1D graph representing some value for
    %       each frame. Moving the mouse over this navigational axes causes
    %       the video frame to update to the corresponding frame number.
    %
    %   Keyboard controls:
    %     space =                           play/stop video
    %     control-space =                   play video, but only selected
    %                                       frames
    %     right/left arrow =                increment/decrement frame number by 
    %                                       1 frame, or if video is playing, 
    %                                       increase/decrease playback speed
    %     control-right/left arrow =        increment/decrement frame number by 
    %                                       10 frames
    %     shift-right/left arrow =          increment/decrement frame number
    %                                       while also selecting frames
    %     control-g =                       jump to a specific frame number
    %     escape =                          clear current selection
    %     a =                               zoom to fit whole frame
    %
    %   Mouse controls:
    %     mouse over nav axes =             advance video frame to match mouse
    %     right-click on image axes =       start/stop zoom in/out box. Start
    %                                       box with upper left corner to zoom 
    %                                       in. Start with lower right to zoom 
    %                                       out.
    %     double-click on image axes =      restore original zoom
    %     left click/drag on nav axes =     select region of video
    %     right click/drag on nav axes =    deselect region of video
    %
    properties (Access = private)
        VideoFrame              matlab.graphics.primitive.Image % An image object containing the video frame image
        FrameMarker             matlab.graphics.primitive.Line  % A line on the NavigationAxes marking what frame is displayed
        FrameNumberMarker       matlab.graphics.primitive.Text  % Text on the NavigationAxes indicating what frame number is displayed
        PlayJob                 timer                           % A timer for playing the video
        PlayIncrement           double = 1                      % Number of frames the play timer will advance by on each call.
        NumColorChannels        double                          % Number of color channels in the video (1 for grayscale, 3 for color)
        NavigationRedrawEnable  logical = false                 % Enable or disable navigation redraw
        CoordinateDisplay       matlab.ui.control.UIControl
        IsZooming               logical = false
        ZoomStart               double = []
        ZoomBox                 matlab.graphics.primitive.Rectangle
        IsSelectingFrames       logical = false
        FrameSelectStart        double
        FrameSelectionHandles   matlab.graphics.primitive.Rectangle
    end
    properties
        MainFigure          matlab.ui.Figure            % The main figure window
        VideoAxes           matlab.graphics.axis.Axes   % Axes for displaying the video frame
        NavigationAxes      matlab.graphics.axis.Axes   % Axes for displaying the 1D metric
    end
    properties (SetObservable)
        VideoData = []                          % The video data itself, a N x H x W double or uint8 array,
        NavigationData = []                     % The 1D navigational data, a 1 x N array
        NavigationDataFunction = []             % A function handle that takes video data as an argument, and returns navigation data
        NavigationColor = []                    % A color specification for the navigation data. See the color argument in the scatter function.
        CurrentFrameNum = 1                     % An integer representing the current frame number
        PlaybackSpeed = 25                      % Playback speed in fps
        Colormap = colormap()                   % Colormap for NavigationAxes
        Title = ''                              % Title for plot
        FrameSelection          logical         % 1-D mask representing selected frames
        FrameSelectionColor = [1, 0, 0, 0.2]    % Color of selection highlight
        FrameMarkerColor        char = 'black'  % The color of the frame marker and frame number marker
    end
    methods
        function obj = VideoBrowser(VideoData, NavigationDataOrFcn, NavigationColor, NavigationColormap, title)
            % Construct a new VideoBrowser object.
            %   VideoData = a N x H x W double or uint8 array, where N =
            %       the number of frames, H and W are the height and width
            %       of each frame, or a N x H x W x 3 array, for videos
            %       with color, or a char array representing a file path to
            %       a video.
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
            %   title = a char array to use as the image title

            if ~exist('title', 'var') || isempty(title)
                title = '';
            end
            obj.Title = title;

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

            if ischar(VideoData)
                % User has provided a filepath instead of the actual video
                % data - load it.
                VideoData = loadVideoData(VideoData);
                switch ndims(VideoData)
                    case 3
                        VideoData = permute(VideoData, [3, 1, 2]);
                    case 4
                        VideoData = permute(VideoData, [4, 1, 2, 3]);
                end
            end

            if ndims(VideoData) == 4
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
            obj.FrameSelection = false(1, size(obj.VideoData, 1));
            obj.NavigationRedrawEnable = true;
            obj.drawNavigationData();

        end
        function playVideo(obj, selectedOnly)
            % Start playback
            
            if ~exist('selectedOnly', 'var') || isempty(selectedOnly)
                selectedOnly = false;
            end
            warning('off', 'MATLAB:TIMER:RATEPRECISION');
            warning('off', 'MATLAB:timer:miliSecPrecNotAllowed');
            if obj.PlaybackSpeed < 0
                obj.PlayIncrement = -1;
            else
                obj.PlayIncrement  = 1;
            end
            delete(obj.PlayJob);
            obj.PlayJob = timer();
            obj.PlayJob.TimerFcn = @(~, ~)obj.playFcn(selectedOnly);
            obj.PlayJob.Period = 1 / abs(obj.PlaybackSpeed);
            obj.PlayJob.ExecutionMode = 'fixedRate';
            obj.PlayJob.UserData.selectedOnly = selectedOnly;
            obj.PlayJob.start();
            warning('on', 'MATLAB:TIMER:RATEPRECISION');
            warning('on', 'MATLAB:timer:miliSecPrecNotAllowed');
        end
        function playFcn(obj, selectedOnly)
            % Display a new frame of the video while in play mode

            try
                if selectedOnly
                    obj.incrementSelectedFrame(obj.PlayIncrement);
                else
                    obj.incrementFrame(obj.PlayIncrement);
                end
                drawnow;
            catch me
                switch me.identifier
                    case {'images:imshow:invalidAxes', 'MATLAB:VideoBrowser:noSelection'}
                        % Axes are missing, we're probably shutting down.
                        % Stop and delete timer.
                        stop(obj.PlayJob);
                        delete(obj.PlayJob);
                    otherwise
                        throw(me);
                end
            end
        end
        function stopVideo(obj)
            % Stop video playback

            stop(obj.PlayJob);
            delete(obj.PlayJob);
        end
        function playing = isPlaying(obj)
            % Check if video is currently playing

            playing = ~isempty(obj.PlayJob) && isvalid(obj.PlayJob) && strcmp(obj.PlayJob.Running, 'on');
        end
        function incrementFrame(obj, delta)
            % Increment the current frame by delta

            obj.CurrentFrameNum = obj.CurrentFrameNum + delta;
        end
        function incrementSelectedFrame(obj, delta)
            % Increment the current frame by delta, while ensuring the next
            % frame will be Selected

            nextFrameNum = obj.CurrentFrameNum + delta;
            if ~obj.FrameSelection(nextFrameNum)
                nextFrameNum = obj.findNextSelectedFrameNum(nextFrameNum, delta);
            end
            obj.CurrentFrameNum = nextFrameNum;
        end
        function nextFrame = findNextSelectedFrameNum(obj, currentFrame, direction)
            % Find next frame after currentFrame in the direction specified
            %   by the sign of direction that is currently selected

            if direction > 0
                nextFrame = find(obj.FrameSelection(currentFrame:end), 1, "first") + currentFrame - 1;
                if isempty(nextFrame)
                    % Maybe we need to wrap around to the beginning
                    nextFrame = find(obj.FrameSelection, 1, "first");
                end
            else
                nextFrame = find(obj.FrameSelection(1:currentFrame), 1, "last");
                if isempty(nextFrame)
                    % Maybe we need to wrap around to the end
                    nextFrame = find(obj.FrameSelection, 1, "last");
                end
            end
            if isempty(nextFrame)
                % Ok, there is no selection.
                err.message = 'No selection found';
                err.identifier = 'MATLAB:VideoBrowser:noSelection';
                error(err);
            end
        end
        function deleteDisplayArea(obj)
            % Delete all graphics display objects

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
            obj.CoordinateDisplay = uicontrol(obj.MainFigure, 'Style', 'text', 'Units', 'normalized', 'String', '', 'Position', [0.9, 0.155, 0.1, 0.04]);

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
            obj.MainFigure.WindowButtonUpFcn = @obj.MouseUpHandler;
            obj.MainFigure.WindowButtonDownFcn = @obj.MouseDownHandler;
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
                obj.VideoFrame.HitTest = 'off';
                obj.VideoFrame.PickableParts = 'none';
                obj.VideoAxes.Title.String = obj.Title;
                obj.VideoAxes.ButtonDownFcn = @obj.VideoClickHandler;
                obj.VideoAxes.HitTest = 'on';
                obj.VideoAxes.PickableParts = 'all';
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
                    delete(obj.FrameNumberMarker);
                end
            end
            x = obj.CurrentFrameNum;
            if isempty(obj.FrameMarker) || ~isvalid(obj.FrameMarker)
                obj.FrameMarker = line([x, x], obj.NavigationAxes.YLim, 'Parent', obj.NavigationAxes, 'Color', obj.FrameMarkerColor);
            else
                obj.FrameMarker.XData = [x, x];
                obj.FrameMarker.YData = ylim(obj.NavigationAxes);
            end
            if isempty(obj.FrameNumberMarker) || ~isvalid(obj.FrameNumberMarker)
                obj.FrameNumberMarker = text(obj.NavigationAxes, x + 20, mean(obj.NavigationAxes.YLim), num2str(x), 'Color', obj.FrameMarkerColor);
            else
                obj.FrameNumberMarker.Position(1) = x + 20;
                obj.FrameNumberMarker.String = num2str(x);
            end
        end
        function updateSelection(obj)
            % Update the selection display to match the current selection

            for k = 1:length(obj.FrameSelectionHandles)
                delete(obj.FrameSelectionHandles(k));
            end
            obj.FrameSelectionHandles = highlight_plot(obj.NavigationAxes, obj.FrameSelection, obj.FrameSelectionColor);
        end
        function set.FrameSelection(obj, newSelection)
            % Setter for Selection property

            obj.FrameSelection = newSelection;
            obj.updateSelection();
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
        function set.FrameMarkerColor(obj, newColor)
            obj.FrameMarkerColor = newColor;
            obj.updateFrameMarker(true);
        end
        function selectedOnly = IsPlayingSelectedOnly(obj)
            selectedOnly = obj.PlayJob.UserData.selectedOnly;
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
                selectedOnly = obj.IsPlayingSelectedOnly();
                obj.stopVideo();
                obj.playVideo(selectedOnly);
            end
        end
        function set.Colormap(obj, colormap)
            obj.Colormap = colormap;
            obj.drawNavigationData();
        end
        function [inside, x, y] = inVideoAxes(obj, x, y)
            % Determine if the given figure coordinates fall within the
            %   borders of the VideoAxes or not..
            if y < obj.VideoAxes.Position(2)
                inside = false;
            elseif y > obj.VideoAxes.Position(2) + obj.VideoAxes.Position(4)
                inside = false;
            elseif (x < obj.VideoAxes.Position(1))
                inside = false;
            elseif x > obj.VideoAxes.Position(1) + obj.VideoAxes.Position(3)
                inside = false;
            else
                inside = true;
            end
        end
        function [x, y] = getCurrentVideoPoint(obj)
            x = round(obj.VideoAxes.CurrentPoint(1, 1));
            y = round(obj.VideoAxes.CurrentPoint(1, 2));
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
        function ZoomVideoAxes(obj, x1, y1, x2, y2)
            % Change limits on video axes
            dx1 = diff(xlim(obj.VideoAxes));
            dy1 = diff(ylim(obj.VideoAxes));
            if ~exist('x1', 'var') || isempty(x1)
                % Zoom to fit
                dx2 = diff(obj.VideoFrame.XData);
                dy2 = diff(obj.VideoFrame.YData);
                xc = mean(obj.VideoFrame.XData);
                yc = mean(obj.VideoFrame.YData);
            else
                dx2 = x2 - x1;
                dy2 = y2 - y1;
                xc = (x1 + x2) / 2;
                yc = (y1 + y2) / 2;
            end
            if dx2 < 0 || dy2 < 0
                % Zoom box was reversed - interpret this as a zoom out
                dx3 = abs(dx1 * dx1 / dx2);
                dy3 = abs(dy1 * dy1 / dy2);
            else
                % Zoom box not reversed
                dx3 = dx2;
                dy3 = dy2;
            end
            % Construct new limits
            new_xlim = [-dx3/2, dx3/2] + xc;
            new_ylim = [-dy3/2, dy3/2] + yc;
            
            % Ensure we don't pointlessly zoom out farther than the limits
            %   of the video frame
            new_xlim = max(new_xlim, [1, 1]);
            new_xlim = min(new_xlim, [obj.VideoFrame.XData(2), obj.VideoFrame.XData(2)]);
            new_ylim = max(new_ylim, [1, 1]);
            new_ylim = min(new_ylim, [obj.VideoFrame.YData(2), obj.VideoFrame.YData(2)]);

            xlim(obj.VideoAxes, new_xlim);
            ylim(obj.VideoAxes, new_ylim);
        end
        function frameNum = mapFigureXToFrameNum(obj, x)
            % Convert a figure x coordinate to frame number based on the
            %   NavigationAxes position.
            
            frameNum = round((x - obj.NavigationAxes.Position(1)) * diff(obj.NavigationAxes.XLim) / obj.NavigationAxes.Position(3));
        end
        function cancelZoom(obj)
            obj.IsZooming = false;
            obj.ZoomStart = [];
            delete(obj.ZoomBox);
        end
        function NavigationClickHandler(obj, ~, ~)
        end
        function VideoClickHandler(obj, ~, ~)
            [x, y] = obj.getCurrentVideoPoint();
            switch obj.MainFigure.SelectionType
                case {'open'}
                    obj.ZoomVideoAxes();
                    obj.cancelZoom();
                case 'alt'
                    if ~obj.IsZooming
                        % Start zoom
                        obj.ZoomStart = [x, y];
                        obj.ZoomBox = rectangle(obj.VideoAxes, 'Position', [x, x, 0, 0], 'EdgeColor', 'r');
                        obj.ZoomBox.HitTest = 'off';
                        obj.IsZooming = true;
                    else
                        obj.ZoomVideoAxes(obj.ZoomStart(1), obj.ZoomStart(2), x, y);
                        obj.cancelZoom();
                    end
            end
        end
        function MouseMotionHandler(obj, src, ~)
            % Handle mouse motion events
            
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inVideoAxes(x, y)
                [x, y] = obj.getCurrentVideoPoint();
                if x > 0 && y > 0 && x <= obj.VideoFrame.XData(2) && y <= obj.VideoFrame.YData(2)
                    obj.CoordinateDisplay.String = sprintf('%d, %d = %s', x, y, num2str(obj.VideoData(obj.CurrentFrameNum, y, x, :)));
                else
                    obj.CoordinateDisplay.String = '';
                end
                if obj.IsZooming
                    % Update zoom box
                    if any([x, y] - obj.ZoomStart < 0)
                        color = 'b';
                    else
                        color = 'r';
                    end
                    if all([x, y] - obj.ZoomStart ~= 0)
                        obj.ZoomBox.Position = [min([[x, y]; obj.ZoomStart], [], 1), abs([x, y] - obj.ZoomStart)];
                        obj.ZoomBox.EdgeColor = color;
                    end
                end
            else
                if obj.IsZooming
                    obj.cancelZoom();
                end
            end
            if obj.inNavigationAxes(x, y)
                frameNum = obj.mapFigureXToFrameNum(x);
                obj.CurrentFrameNum = frameNum;
                if obj.IsSelectingFrames
                    selectBounds = sort([obj.FrameSelectStart, frameNum]);
                    switch obj.MainFigure.SelectionType
                        case 'normal'
                            obj.FrameSelection(selectBounds(1):selectBounds(2)) = true;
                        case 'alt'
                            obj.FrameSelection(selectBounds(1):selectBounds(2)) = false;
                    end
                end
            end
        end
        function MouseDownHandler(obj, src, ~)
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inNavigationAxes(x, y)
                frameNum = obj.mapFigureXToFrameNum(x);
                obj.FrameSelectStart = frameNum;
                obj.IsSelectingFrames = true;
            end
        end
        function MouseUpHandler(obj, ~, ~)
            if obj.IsSelectingFrames
                obj.IsSelectingFrames = false;
            end
        end
        function ChangeFrameHandler(obj, evt, direction)
            % direction should be 1 or -1
            select = false;
            if obj.isPlaying()
                % Video is playing - 
                warning('off', 'MATLAB:TIMER:RATEPRECISION');
                obj.PlaybackSpeed = obj.PlaybackSpeed + 10 * direction;
                warning('on', 'MATLAB:TIMER:RATEPRECISION');
            else
                delta = 1 * direction;
                if any(strcmp(evt.Modifier, 'control'))
                    % User is holding down control - jump by 10
                    delta = 10 * direction;
                end

                if any(strcmp(evt.Modifier, 'shift'))
                    % User is holding down shift - select while 
                    %   changing frames
                    select = true;
                    selectStart = obj.CurrentFrameNum;
                end
                obj.incrementFrame(delta);

                if select
                    % User is selecting while changing frames
                    selectEnd = obj.CurrentFrameNum;
                    obj.FrameSelection(selectStart:direction:selectEnd) = true;
                end
            end
        end
        function KeyPressHandler(obj, ~, evt)
            switch evt.Key
                case 'escape'
                    obj.FrameSelection = false(1, size(obj.VideoData, 1));
                case 'space'
                    if obj.isPlaying()
                        obj.stopVideo();
                    else
                        % Check if user wants to play only selected frames
                        selectedOnly = any(strcmp(evt.Modifier, 'control')) && any(obj.FrameSelection);
                        % Start playback
                        obj.playVideo(selectedOnly);
                    end
                case 'a'
                    obj.ZoomVideoAxes()
                case 's'
                    if any(strcmp(evt.Modifier, 'control'))
                        % Save selected frames as a new video

                        if any(obj.FrameSelection)
                            % Extract selected frames
                            selection = obj.FrameSelection;
                        else
                            % Nothing selected, just use the whole video
                            selection = true(size(obj.FrameSelection));
                        end

                        % Select frames and permute to match dim convention
                        if ndims(obj.VideoData) == 4
                            videoData = permute(obj.VideoData(selection, :, :, :), [2, 3, 4, 1]);
                        else
                            videoData = permute(obj.VideoData(selection, :, :), [2, 3, 1]);
                        end

                        % Get file path to save to from user
                        [filename, path] = uiputfile('*','Save selected video data');
                        filepath = fullfile(path, filename);
                        if ~isempty(filename)
                            fprintf('Saving %d frames to %s.\n', sum(selection), filepath);
                            saveVideoData(videoData, filepath);
                        end
                    end
                case 'rightarrow'
                    obj.ChangeFrameHandler(evt, 1)
                case 'leftarrow'
                    obj.ChangeFrameHandler(evt, -1)
                case 'g'
                    if any(strcmp(evt.Modifier, 'control'))
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