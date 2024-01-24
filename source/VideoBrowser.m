classdef VideoBrowser < handle
    % VideoBrowser A class representing a simple graphical video browser
    %   This class creates a window where a video frame is displayed.
    %       A separate axes contains a 1D graph representing some value for
    %       each frame. Moving the mouse over this navigational axes causes
    %       the video frame to update to the corresponding frame number.
    properties (Access = private)
        VideoFrame              matlab.graphics.primitive.Image     % An image object containing the video frame image
        FrameMarker             matlab.graphics.primitive.Line      % A line on the NavigationAxes marking what frame is displayed
        FrameNumberMarker       matlab.graphics.primitive.Text      % Text on the NavigationAxes indicating what frame number is displayed
        AVPlayer                audioplayer                         % An object for playing the audio and video
        PlayIncrement           double = 1                          % Number of frames the play timer will advance by on each call.
        NumColorChannels        double                              % Number of color channels in the video (1 for grayscale, 3 for color)
        NavigationRedrawEnable  logical = false                     % Enable or disable navigation redraw
        StatusBar               matlab.ui.control.UIControl
        HelpButton              matlab.ui.control.UIControl
        IsZooming               logical = false
        ZoomStart               double = []
        ZoomBox                 matlab.graphics.primitive.Rectangle
        IsSelectingFrames       logical = false
        IsNavDividerDragging    logical = false
        FrameSelectStart        double
        FrameSelectionHandles   matlab.graphics.primitive.Rectangle
        NavigationMapMode       char = 'frame'                      % Determine how the navigation axis position is mapped to a frame number - either 'frame' or 'time'
        VideoFrameRate          double = 30
        AudioSampleRate         double = 44100
        NavigationZoom          double = 1
        ShiftKeyDown            logical = false
        NavigationDivider       matlab.ui.control.UIControl         % A button to allow user to drag navigation axes larger or smaller
    end
    properties
        MainFigure          matlab.ui.Figure            % The main figure window
        VideoPanel          matlab.ui.container.Panel   % Panel that contains video and nav axes
        VideoAxes           matlab.graphics.axis.Axes   % Axes for displaying the video frame
        NavigationAxes      matlab.graphics.axis.Axes   % Axes for displaying the 1D metric
    end
    properties
        NavigationScrollMode    char = 'partial'     % How should navigation axes scroll when zoomed in? One of 'centered' (keep cursor centered), 'partial' (keep cursor within a margin), 'none' (no scrolling)
        ChannelMode = 'all'         % For multichannel navigation data, which channels should be displayed when navigation function is 'audio' or 'spectrogram'. One of 'all', 'first', or a scalar/vector of channel indices
    end
    properties (SetObservable)
        VideoData = []                          % The video data itself, a N x H x W double or uint8 array,
        VideoPath = ''                          % Path to video, if provided
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
        AudioData = []                          % Audio data, a NxC array, where N is # of samples, C is # of channels
    end
    methods
        function obj = VideoBrowser(VideoData, NavigationDataOrFcn, NavigationColor, NavigationColormap, title)
            % Construct a new VideoBrowser object.
            %   VideoData = 
            %       a char array representing a file path to a video
            %       a H x W x N double or uint8 array, where N = the number
            %           of frames, H and W are the height and width of each
            %           frame
            %       a H x W x 3 x N array, for videos with color
            %       a 1x2 cell array containing video data formatted as 
            %           one of the above in the first cell, and audio data 
            %           in the second cell, as a C x N 2D array, where C is
            %           the number of audio channels, and N is the number 
            %           of audio samples.
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

            if iscell(VideoData)
                % User must be passing video data and audio data
                obj.VideoData = VideoData{1};
                obj.AudioData = VideoData{2};
            else
                obj.VideoData = VideoData;
            end

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
                            frameDim = 4;
                            sumDims = [1, 2, 3];
                        case 1
                            frameDim = 3;
                            sumDims = [1, 2];
                        otherwise
                            error('Invalid number of color channels: %d', obj.NumColorChannels);
                    end
                    obj.NavigationMapMode = 'frame';
                    obj.NavigationData = [];
                    switch NavigationDataOrFcn
                        case 'sum'
                            obj.NavigationDataFunction = @(videoData)squeeze(sum(videoData, sumDims));
                        case 'diff'
                            obj.NavigationDataFunction = @(videoData)smooth(squeeze(sum(diff(videoData, frameDim), sumDims)), 10);
                        case 'compactness'
                            obj.NavigationDataFunction = @(videoData)squeeze(sum(videoData, sumDims)) ./ squeeze(sum(getMaskSurface(videoData), sumDims));
                        case 'audio'
                            obj.NavigationMapMode = 'time';
                            obj.FrameMarkerColor = 'black';
                            obj.NavigationData = obj.AudioData;
                            obj.NavigationDataFunction = NavigationDataOrFcn;
                        case 'spectrogram'
                            obj.NavigationMapMode = 'time';
                            obj.FrameMarkerColor = 'white';
                            obj.NavigationDataFunction = NavigationDataOrFcn;
                        otherwise
                            error('Unrecognized named navigation data function: %s.', NavigationDataOrFcn);
                    end
                case {'double', 'uint8'}
                    obj.NavigationData = NavigationDataOrFcn;
                    obj.NavigationDataFunction = [];
                otherwise
                    error('NavigationDataOrFcn argument must be of type function_handle, char, double, or uint8, not %s.', class(NavigationDataOrFcn));
            end
            obj.FrameSelection = false(1, size(obj.VideoData, ndims(obj.VideoData)));
            obj.NavigationRedrawEnable = true;
            obj.drawNavigationData();
        end
        function showHelp(obj, ~, ~, ~) %#ok<INUSD> 
            helpText = {
'***************************** Video Browser ******************************';
'                                controls';
'';
'Keyboard controls:';
'   space =                           play/stop video';
'   control-space =                   play video, but only selected';
'                                     frames';
'   right/left arrow =                increment/decrement frame number by ';
'                                     1 frame, or if video is playing, ';
'                                     increase/decrease playback speed';
'   control-right/left arrow =        increment/decrement frame number by';
'                                     1 fps/10 frames, or if video is';
'                                     playing, increase/decrease playback';
'                                     speed by 10 fps';
'   shift-right/left arrow =          increment/decrement frame number';
'                                     while also selecting frames';
'   control-g =                       jump to a specific frame number';
'   escape =                          clear current selection';
'   a =                               reset zoom to fit whole video frame';
'';
'Mouse controls:';
'   mouse over nav axes =             advance video frame to match mouse';
'   right-click on image axes =       start/stop zoom in/out box. Start';
'                                     box with upper left corner to zoom ';
'                                     in. Start with lower right to zoom ';
'                                     out.';
'   double-click on image axes =      restore original zoom';
'   left click/drag on nav axes =     select region of video';
'   right click/drag on nav axes =    deselect region of video';
'   scroll wheel =                    zoom in/out for nav axes or video';
'                                     frame'
};
            f = figure();
            f.UserData.text = uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.01, 0.01, 0.99, 0.99], 'FontName', 'Monospaced', 'String', helpText, 'HorizontalAlignment','left');
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
                obj.PlayIncrement = 1;
            end
            delete(obj.AVPlayer);
            if selectedOnly
                obj.CurrentFrameNum = obj.findNextSelectedFrameNum(obj.CurrentFrameNum, obj.PlayIncrement);
            end
            currentAudioSample = obj.getCurrentAudioSample();
            audioData = obj.AudioData(:, currentAudioSample:end)';
            if isempty(audioData)
                % Create blank audio data if there's none
                audioData = zeros(1, round(obj.getNumFrames() * obj.AudioSampleRate / obj.VideoFrameRate));
            end
            audioPlaybackSpeed = obj.AudioSampleRate * obj.PlaybackSpeed / obj.VideoFrameRate;
            obj.AVPlayer = audioplayer(audioData, audioPlaybackSpeed);
            obj.AVPlayer.TimerFcn = @(~, ~)obj.playFcn(selectedOnly);
            obj.AVPlayer.TimerPeriod = 1 / abs(obj.PlaybackSpeed);
            obj.AVPlayer.UserData.selectedOnly = selectedOnly;
            obj.AVPlayer.play();
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
                obj.StatusBar.String = sprintf('Playing: Frame = %d / %d, time = %0.3f s', obj.CurrentFrameNum, obj.getNumFrames(), obj.CurrentFrameNum / obj.VideoFrameRate);
                drawnow;
            catch me
                switch me.identifier
                    case {'images:imshow:invalidAxes', 'MATLAB:VideoBrowser:noSelection'}
                        % Axes are missing, we're probably shutting down.
                        % Stop and delete timer.
                        stop(obj.AVPlayer);
                        delete(obj.AVPlayer);
                    otherwise
                        throw(me);
                end
            end
        end
        function stopVideo(obj)
            % Stop video playback
            stop(obj.AVPlayer);
            delete(obj.AVPlayer);
        end
        function restartVideo(obj)
            selectedOnly = obj.IsPlayingSelectedOnly();
            obj.stopVideo();
            obj.playVideo(selectedOnly);
        end
        function playing = isPlaying(obj)
            % Check if video is currently playing

            playing = ~isempty(obj.AVPlayer) && isvalid(obj.AVPlayer) && strcmp(obj.AVPlayer.Running, 'on');
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
            skipAmount = nextFrameNum - obj.CurrentFrameNum;
            obj.CurrentFrameNum = nextFrameNum;
            if obj.isPlaying() && skipAmount ~= 1
                % If we're skipping to some other frame other than the
                % next one, we need to restart the player so the audio
                % will skip with the video
                obj.restartVideo()
            end
        end
        function audioSample = getCurrentAudioSample(obj)
            audioSample = obj.convertFrameNumberToAudioSample(obj.CurrentFrameNum);
        end
        function audioSample = convertFrameNumberToAudioSample(obj, frameNum)
            audioSample = round((frameNum - 1) * obj.AudioSampleRate / obj.VideoFrameRate) + 1;
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
            delete(obj.NavigationDivider);
        end
        function regenerateGraphics(obj)
            % Recreate graphics in case it gets closed

            obj.deleteDisplayArea();
            obj.createDisplayArea();
            obj.drawNavigationData();
            obj.updateFrameMarker();
            obj.updateVideoFrame();
        end
        function setNavigationAxesHeightFraction(obj, fraction)
            % Adjust the height of the navigation axes based on the
            % fraction of the height of the figure it should occupy
            margin = 0.025;

            % Get fixed height for divider and status bar
            originalUnits = obj.MainFigure.Units;
            obj.MainFigure.Units = 'pixels';
            dividerHeight = 10 / obj.MainFigure.Position(4);
            obj.MainFigure.Units = originalUnits;

            % Set up status bar and help button so they are both 1
            % character high, and the help button fits to the right of the
            % status bar and is 1 character wide
            obj.HelpButton.Position = [1, 0, 0.1, 0.1];
            obj.StatusBar.Position =  [0, 0, 0.9, 0.1];
            obj.StatusBar.Units = 'characters';
            obj.HelpButton.Units = 'characters';
            obj.StatusBar.Position(4) = 1;
            obj.HelpButton.Position(4) = 1;
            helpButtonCharWidth = 2;
            obj.HelpButton.Position(1) = obj.HelpButton.Position(1) - helpButtonCharWidth;
            obj.HelpButton.Position(3) = helpButtonCharWidth;
            obj.StatusBar.Position(3) = obj.StatusBar.Position(3) - 1;
            obj.StatusBar.Units = 'normalized';
            obj.HelpButton.Units = 'normalized';
            statusBarHeight = obj.StatusBar.Position(4);

            % Set up navigation axes, divider, and video axes so they share
            % the vertical space based on the value of `fraction`
            obj.NavigationAxes.Position =       [margin, statusBarHeight + margin,  1-2*margin, fraction - 1.5 * margin - statusBarHeight];
            obj.NavigationDivider.Position =    [margin, fraction-dividerHeight/2,  1-2*margin, dividerHeight];
            obj.VideoAxes.Position =            [margin, fraction + 2*margin,       1-2*margin, 1-fraction - 1.5 * margin];
        end
        function NavigationDividerMouseDown(obj, ~, ~)
            obj.IsNavDividerDragging = true;
        end
        function createDisplayArea(obj)
            % Create & prepare the graphics containers (the figure & axes)
            
            % Delete graphics containers in case they already exist
            obj.deleteDisplayArea();
            
            % Create graphics containers
            obj.MainFigure =        figure('Units', 'normalized');
            obj.VideoPanel =        uipanel(obj.MainFigure, 'Units', 'normalized', 'Position', [0, 0, 1, 1]);
            obj.VideoAxes =         axes(obj.VideoPanel, 'Units', 'normalized');
            obj.NavigationAxes =    axes(obj.VideoPanel, 'Units', 'normalized');
            obj.NavigationDivider = uicontrol(obj.VideoPanel, 'Style','text', 'Units', 'normalized', 'String', '----------------------------', 'Visible','on', 'BackgroundColor', obj.MainFigure.Color, 'ButtonDownFcn', @obj.NavigationDividerMouseDown, 'Enable', 'off');
            obj.StatusBar =  uicontrol(obj.VideoPanel, 'Style', 'text', 'Units', 'normalized', 'String', '', 'HorizontalAlignment', 'left');
            obj.HelpButton = uicontrol(obj.VideoPanel, 'Style', 'pushbutton', 'Units', 'normalized', 'String', '?', 'HorizontalAlignment', 'center', 'Callback', @obj.showHelp);
            obj.setNavigationAxesHeightFraction(0.175);

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

            obj.VideoAxes.Toolbar.Visible = 'off';
            obj.VideoAxes.YTickMode = 'manual';
            obj.VideoAxes.YTickLabelMode = 'manual';
            obj.VideoAxes.YTickLabel = [];
            obj.VideoAxes.YTick = [];
            obj.VideoAxes.XTickMode = 'manual';
            obj.VideoAxes.XTickLabelMode = 'manual';
            obj.VideoAxes.XTickLabel = [];
            obj.VideoAxes.XTick = [];
            axis(obj.VideoAxes, 'off');

            % Configure callbacks
            obj.MainFigure.WindowButtonMotionFcn = @obj.MouseMotionHandler;
            obj.MainFigure.WindowButtonUpFcn = @obj.MouseUpHandler;
            obj.MainFigure.WindowButtonDownFcn = @obj.MouseDownHandler;
            obj.MainFigure.WindowScrollWheelFcn = @obj.ScrollHandler;
            obj.MainFigure.BusyAction = 'cancel';
            obj.MainFigure.KeyPressFcn = @obj.KeyPressHandler;
            obj.MainFigure.KeyReleaseFcn = @obj.KeyReleaseHandler;
            obj.MainFigure.SizeChangedFcn = @obj.ResizeHandler;
        end
        function updateVideoFrame(obj)
            % Update the displayed video frame based on the current
            %   VideoData and CurrentFrameNumber
            
            frameData = obj.getCurrentVideoFrameData();

            if isempty(frameData)
                % No frame data, skip update.
                return
            end

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
        function updateNavigationXLim(obj)
            numSamples = size(obj.NavigationData, 2);
            if numSamples == 0
                % No nav data yet, don't bother
                return;
            end

            % Calculate xlim
            switch obj.NavigationMapMode
                case 'frame'
                    fullTLim = [0, numSamples];
                case 'time'
                    fullTLim = [0, numSamples / obj.AudioSampleRate];
            end
            xCenter = obj.mapFrameNumToAxesX(obj.CurrentFrameNum);
            currentTLim = xlim(obj.NavigationAxes);
            currentXFraction = (xCenter - currentTLim(1)) / diff(currentTLim);
            tWidth = diff(fullTLim) * obj.NavigationZoom;
            switch obj.NavigationScrollMode
                case 'centered'
                    newTLim = [xCenter - tWidth*0.5, xCenter + tWidth*0.5];
                case 'partial'
                    margin = 0.2; % How close to edge cursor is before beginning to scroll axes (expressed as fraction of whole width)
                    if currentXFraction < margin
                        currentXFraction = margin;
                    end
                    if currentXFraction > (1-margin)
                        currentXFraction = (1-margin);
                    end
                    newTLim = [xCenter - tWidth*currentXFraction, xCenter + tWidth*(1-currentXFraction)];
                case 'none'
                    newTLim = [xCenter - tWidth*currentXFraction, xCenter + tWidth*(1-currentXFraction)];
                otherwise
                    error('Unknown navigation scroll mode: %s', obj.NavigationScrollMode);
            end
            if min(newTLim) < 0
                % Prevent start of data from displaying anywhere except
                % left edge of axes
                newTLim = newTLim - min(newTLim);
            end
            if max(newTLim) > max(fullTLim)
                % Prevent end of data from displaying anywhere except
                % right edge of axes
                newTLim = newTLim - (max(newTLim) - max(fullTLim));
            end
            xlim(obj.NavigationAxes, newTLim);            
        end
        function updateNavigationData(obj)
            if ischar(obj.NavigationDataFunction) && ~isempty(obj.NavigationDataFunction)
                % Navigation data function is a char array - must be a
                % named function
                switch obj.NavigationDataFunction
                    case {'audio', 'spectrogram'}
                        obj.NavigationData = obj.AudioData;
                    otherwise
                        error('Unknown named navigation function: %s', obj.NavigationDataFunction);
                end
            elseif ~isempty(obj.NavigationDataFunction) && ~isempty(obj.VideoData)
                % Navigation data function must be an actual function handle -
                % apply it
                obj.NavigationData = obj.NavigationDataFunction(obj.VideoData);
            end

            if isempty(obj.NavigationData)
                % Fallback null nav data
                obj.NavigationData = zeros(1, obj.getNumFrames());
            end

            if size(obj.NavigationData, 1) > size(obj.NavigationData, 2)
                % Ensure channel # is first dimension
                obj.NavigationData = obj.NavigationData';
            end
        end
        function drawNavigationData(obj, replot)
            % Draw the NavigationData on the NavigationAxes. If only a
            %   NavigationDataFunction is provide, it will be used here to
            %   generate NavigationData
            if ~exist('replot', 'var') || isempty(replot)
                replot = true;
            end
            
            if ~obj.NavigationRedrawEnable
                return;
            end
            
            obj.updateNavigationData();

            obj.updateNavigationXLim();

            numSamples = size(obj.NavigationData, 2);
            numChannels = size(obj.NavigationData, 1);
            % Determine which channels to display
            if strcmp(obj.ChannelMode, 'all')
                % Display all channels
                channelList = 1:numChannels;
            elseif strcmp(obj.ChannelMode, 'first')
                % Display only first channel
                channelList = 1;
            elseif isnumeric(obj.ChannelMode)
                % Display channels specified by obj.ChannelMode,
                % interpreted as a vector of channel indices
                channelList = obj.ChannelMode;
            else
                error('Channel mode not recognized: %s', obj.ChannelMode);
            end
            
            numChannelsToDisplay = length(channelList);

            if isempty(obj.NavigationData)
                obj.clearNavigationData();
            elseif strcmp(obj.NavigationDataFunction, 'spectrogram')
                % User requested spectrogram of audio data
                fullTLim = [0, numSamples / obj.AudioSampleRate];
                flim = [50, 7500];
                clim = [13.0000, 24.5000];
                stackSeparation = 100;
                fWidth = diff(flim) + stackSeparation;
                if replot
                    obj.clearNavigationData();

                    % Determine width of axes in pixels
                    originalUnits = get(obj.NavigationAxes,'units');
                    set(obj.NavigationAxes,'Units','pixels');
                    pixSize = get(obj.NavigationAxes,'Position');
                    set(obj.NavigationAxes,'Units',originalUnits);

                    nCourse = 0.005;
                    tSize = pixSize(3) / nCourse;
                    hold(obj.NavigationAxes, 'on');
                    
                    for channelIdx = 1:length(channelList)
                        % Loop over each channel in audio, creating stacked
                        % spectrograms
                        channel = channelList(channelIdx);
                        audio = obj.NavigationData(channel, :);
                        power = getAudioSpectrogram(audio, obj.AudioSampleRate, flim, tSize);
                        nFreqBins = size(power, 1);
                        nTimeBins = size(power, 2);
                        t = linspace(fullTLim(1), fullTLim(2), nTimeBins);
                        freqShift = fWidth*(channelIdx-1);
                        f = linspace(flim(1)+freqShift,flim(2)+freqShift,nFreqBins);
        
                        imagesc(t,f,power, 'Parent', obj.NavigationAxes);
                    end
                end

                ylim(obj.NavigationAxes, [flim(1), flim(2) + fWidth*(numChannelsToDisplay-1)]);
                
                set(obj.NavigationAxes, 'YDir', 'normal');
                c = colormap(obj.NavigationAxes, 'parula');
                c(1, :) = [0, 0, 0];
                colormap(obj.NavigationAxes, c);
                set(obj.NavigationAxes, 'CLim', clim);
                
                ylabel(obj.NavigationAxes, 'Frequency (Hz)');
                xlabel(obj.NavigationAxes, 'Time (s)');
                hold(obj.NavigationAxes, 'off');
            else
                numFrames = obj.getNumFrames();

                obj.NavigationAxes.Colormap = obj.Colormap;
                dataRange = max(max(obj.NavigationData, [], 2) - min(obj.NavigationData, [], 2));
                dataSpacing = dataRange * 1.1;
                if replot
                    originalXLim = obj.NavigationAxes.XLim;
                    originalYLim = obj.NavigationAxes.YLim;

                    % Data needs to actually be redrawn
                    obj.clearNavigationData();

                    % Stupid hack to force MATLAB to draw axes background
                    p = plot(obj.NavigationAxes, originalXLim, originalYLim);
                    delete(p);
                    
                    obj.NavigationAxes.XLim = originalXLim;
                    obj.NavigationAxes.YLim = originalYLim;

                    if strcmp(obj.NavigationDataFunction, 'audio')
                        % If we're plotting the audio, scale based on audio
                        % sample rate
                        t = (1:numSamples) / obj.AudioSampleRate;
                    else
                        % Assume there is one sample per frame
                        t = (1:numSamples)*(numFrames/numSamples);
                    end

                    for channelIdx = 1:length(channelList)
                        channel = channelList(channelIdx);
                        linec(t, obj.NavigationData(channel, :) + dataSpacing*(channelIdx-1), 'Color', obj.NavigationColor, 'Parent', obj.NavigationAxes);
            %             scatter(1:length(navigationData), navigationData, 1, obj.NavigationColor, '.', 'Parent', obj.NavigationAxes);
                    end
                    minY = min(obj.NavigationData(1, :));
                    navigationYLim = [minY, minY + dataRange + dataSpacing*(numChannelsToDisplay-1)];
                    if diff(navigationYLim) <= 0
                        % Nav data has no vertical range - use a default
                        % instead
                        navigationYLim = [-1, 1];
                    end
                    ylim(obj.NavigationAxes, navigationYLim);
                end
            end
        end
        function frameData = getCurrentVideoFrameData(obj)
            % Extract the current frame's video data
            if isempty(obj.VideoData)
                frameData = [];
                return;
            end

            switch obj.NumColorChannels
                case 3
                    frameData = obj.VideoData(:, :, :, obj.CurrentFrameNum);
                case 1
                    frameData = obj.VideoData(:, :, obj.CurrentFrameNum);
                otherwise
                    error('Wrong number of color channels: %d', obj.NumColorChannels);
            end
        end
        function numFrames = getNumFrames(obj)
            % Determine the number of frames in the current VideoData
            
            numFrames = size(obj.VideoData, ndims(obj.VideoData));
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

            % Update frame marker (vertical line on navigation axes
            %   indicating what frame the video is on
            x = obj.mapFrameNumToAxesX(obj.CurrentFrameNum);
            if isempty(obj.FrameMarker) || ~isvalid(obj.FrameMarker)
                obj.FrameMarker = line([x, x], obj.NavigationAxes.YLim, 'Parent', obj.NavigationAxes, 'Color', obj.FrameMarkerColor);
            else
                obj.FrameMarker.XData = [x, x];
                obj.FrameMarker.YData = ylim(obj.NavigationAxes);
            end

            % Update frame number label
            scale = obj.getFrameToAxesUnitScale();
            switch obj.NavigationMapMode
                case 'time'
                    frameNumberString = sprintf('%0.2f', x);
                case 'frame'
                    frameNumberString = sprintf('%d', x);
            end
            if isempty(obj.FrameNumberMarker) || ~isvalid(obj.FrameNumberMarker)
                obj.FrameNumberMarker = text(obj.NavigationAxes, x + 20/scale, mean(obj.NavigationAxes.YLim), frameNumberString, 'Color', obj.FrameMarkerColor);
            else
                obj.FrameNumberMarker.Position(1) = x + 20 / (scale / obj.NavigationZoom);
                obj.FrameNumberMarker.String = frameNumberString;
            end
        end
        function updateFrameSelection(obj)
            % Update the selection display to match the current selection

            for k = 1:length(obj.FrameSelectionHandles)
                delete(obj.FrameSelectionHandles(k));
            end

            switch obj.NavigationMapMode
                case 'frame'
                    scale = 1;
                case 'time'
                    scale = obj.AudioSampleRate;
            end
            highlight_x = linspace(0, size(obj.NavigationData, 2) / scale, obj.getNumFrames());
            obj.FrameSelectionHandles = highlight_plot(obj.NavigationAxes, highlight_x, obj.FrameSelection, obj.FrameSelectionColor);
        end
        function set.VideoFrameRate(obj, frameRate)
            obj.VideoFrameRate = frameRate;
        end
        function set.FrameSelection(obj, newSelection)
            % Setter for Selection property

            obj.FrameSelection = newSelection;
            obj.updateFrameSelection();
        end
        function updateNumColorChannels(obj)
            if ndims(obj.VideoData) == 4
                if size(obj.VideoData, 3) ~= 3
                    error('Incorrect video color dimension size: 4D videos must have the dimension order N x H x W x 3.');
                end
                obj.NumColorChannels = 3;
            else
                obj.NumColorChannels = 1;
            end
        end
        function newVideoData = prepareNewVideoData(obj, newVideoData)
            if ischar(newVideoData)
                % User has provided a filepath instead of the actual video
                % data - load it.
                obj.VideoPath = newVideoData;
                makeGrayscale = false;
                newVideoData = loadVideoData(obj.VideoPath, makeGrayscale);
                videoInfo = getVideoInfo(obj.VideoPath);
                obj.VideoFrameRate = videoInfo.frameRate;
                obj.PlaybackSpeed = obj.VideoFrameRate;
                try
                    [obj.AudioData, obj.AudioSampleRate] = audioread(obj.VideoPath);
                    obj.AudioData = obj.AudioData';
                catch ME
                    switch ME.identifier
                        case 'MATLAB:audiovideo:audioread:NoAudio'
                            % No audio in video - create blank audio
                            obj.AudioSampleRate = 44100;
                            obj.AudioData = zeros(1, round(obj.getNumFrames() * obj.AudioSampleRate / obj.VideoFrameRate));
                        otherwise
                            rethrow(ME);
                    end
                end
            else
                obj.VideoPath = '';
            end
        end
        function set.VideoData(obj, newVideoData)
            % Setter for the VideoData property

            newVideoData = obj.prepareNewVideoData(newVideoData);
            obj.VideoData = newVideoData;
            obj.updateNumColorChannels();
            obj.setCurrentFrameNum(1);
            obj.drawNavigationData();
        end
        function set.NavigationDataFunction(obj, newNavigationDataFunction)
            % Setter for the NavigationDataFunction property
            
            obj.NavigationDataFunction = newNavigationDataFunction;
            obj.drawNavigationData();
        end
        function set.NavigationData(obj, newNavigationData)
            % Setter for the NavigationData property
            
            obj.NavigationData = newNavigationData;
%             obj.drawNavigationData();
        end
        function set.NavigationColor(obj, newNavigationColor)
            % Setter for the NavigationColor property
            
            obj.NavigationColor = newNavigationColor;
            obj.drawNavigationData();
        end
        function setCurrentFrameNum(obj, newFrameNum)
            obj.CurrentFrameNum = newFrameNum;
        end
        function set.CurrentFrameNum(obj, newFrameNum)
            % Setter for the CurrrentFrameNum property
            
            obj.CurrentFrameNum = mod(newFrameNum - 1, obj.getNumFrames()) + 1;
            obj.updateVideoFrame();
            obj.updateFrameMarker();
            obj.updateNavigationXLim();
        end
        function set.FrameMarkerColor(obj, newColor)
            obj.FrameMarkerColor = newColor;
            obj.updateFrameMarker(true);
        end
        function selectedOnly = IsPlayingSelectedOnly(obj)
            selectedOnly = obj.AVPlayer.UserData.selectedOnly;
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
                obj.restartVideo();
            end
        end
        function set.Colormap(obj, colormap)
            obj.Colormap = colormap;
            obj.drawNavigationData();
        end
        function set.ChannelMode(obj, newChannelMode)
            % Check that channel mode is valid
            if ischar(newChannelMode)
                if any(strcmp(newChannelMode, {'all', 'first'}))
                    % It's 'all' or 'first'
                else
                    error('Invalid channel mode: %s', newChannelMode)
                end
            else
                if isnumeric(newChannelMode) && all(newChannelMode > 0) && all(newChannelMode == round(newChannelMode))
                    % It's an array of integer channel numbers to display
                else
                    error('Invalid channel mode: %s', newChannelMode)
                end
            end
            obj.ChannelMode = newChannelMode;
            obj.clearNavigationData();
            obj.drawNavigationData();
        end
        function [inside, x, y] = inNavigationDivider(obj, x, y)
            % Determine if the given figure coordinates fall within the
            %   borders of the NavigationDivider or not..
            if y < obj.NavigationDivider.Position(2)
                inside = false;
            elseif y > obj.NavigationDivider.Position(2) + obj.NavigationDivider.Position(4)
                inside = false;
            elseif (x < obj.NavigationDivider.Position(1))
                inside = false;
            elseif x > obj.NavigationDivider.Position(1) + obj.NavigationDivider.Position(3)
                inside = false;
            else
                inside = true;
            end
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
        function clearSelection(obj)
            obj.FrameSelection = false(1, size(obj.VideoData, ndims(obj.VideoData)));
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
        function scale = getFrameToAxesUnitScale(obj)
            switch obj.NavigationMapMode
                case 'frame'
                    scale = 1;
                case 'time'
                    scale = obj.VideoFrameRate;
                otherwise
                    error('Unknwon navigation map mode: %s', obj.NavigationMapMode);
            end
        end
        function frameNum = mapFigureXToFrameNum(obj, x)
            % Convert a figure x coordinate to frame number based on the
            %   NavigationAxes position.
            scale = obj.getFrameToAxesUnitScale();
            frameNum = round(scale * ((x - obj.NavigationAxes.Position(1)) * diff(obj.NavigationAxes.XLim) / obj.NavigationAxes.Position(3) + obj.NavigationAxes.XLim(1)));
        end
        function x = mapFrameNumToFigureX(obj, frameNum)
            % Convert a frame number to a figure x coordinate based on the
            %   NavigationAxes position.
            scale = obj.getFrameToAxesUnitScale();
            x = (frameNum/scale) * (obj.NavigationAxes.Position(3) / diff(obj.NavigationAxes.XLim)) - obj.NavigationAxes.XLim(1) + obj.NavigationAxes.Position(1);
        end
        function x = mapFrameNumToAxesX(obj, frameNum)
            % Convert a frame number to a axes x coordinate
            switch obj.NavigationMapMode
                case 'frame'
                    scale = 1;
                case 'time'
                    scale = obj.VideoFrameRate;
            end

            x = (frameNum/scale);
        end
        function cancelZoom(obj)
            obj.IsZooming = false;
            obj.ZoomStart = [];
            delete(obj.ZoomBox);
        end
        function NavigationClickHandler(~, ~, ~)
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
        function [x, y] = GetCurrentVideoPanelPoint(obj)
            % Get current X and Y relative to the lower left corner of the
            % VideoPanel container
            panelX0 = obj.VideoPanel.Position(1);
            panelW = obj.VideoPanel.Position(3);
            panelY0 = obj.VideoPanel.Position(2);
            panelH = obj.VideoPanel.Position(4);

            x = (obj.MainFigure.CurrentPoint(1, 1) - panelX0) / panelW;
            y = (obj.MainFigure.CurrentPoint(1, 2) - panelY0) / panelH;
        end
        function ZoomIntoPoint(obj, x, y, zoomFactor)
            dx = diff(obj.VideoAxes.XLim) * zoomFactor;
            dy = diff(obj.VideoAxes.YLim) * zoomFactor;
            obj.ZoomVideoAxes(x - dx/2, y - dy/2, x + dx/2, y + dy/2);
        end
        function ScrollHandler(obj, ~, evt)
            [xFig, yFig] = obj.GetCurrentVideoPanelPoint();
            
            [inVideoAxes, inNavigationAxes, ~] = obj.whereIsMouse(xFig, yFig);

            if inVideoAxes
                scrollCount = evt.VerticalScrollCount;
                zoomFactor = 2^(scrollCount/3);
                [x, y] = obj.getCurrentVideoPoint();
                obj.ZoomIntoPoint(x, y, zoomFactor);
            end
            if inNavigationAxes
                scrollCount = evt.VerticalScrollCount;
                if obj.ShiftKeyDown
                    % User has shift pressed - shift axes instead of
                    % zooming
                    currentTLim = xlim(obj.NavigationAxes);
                    shiftFraction = 0.1;
                    shiftAmount = diff(currentTLim) * shiftFraction * scrollCount;
                    newTLim = currentTLim + shiftAmount;
                    xlim(obj.NavigationAxes, newTLim);
                    
                    % Update video frame too
                    frameNum = obj.mapFigureXToFrameNum(xFig);
                    if ~obj.isPlaying()
                        % Do not change frame during mouseover if video is
                        % playing
                        obj.CurrentFrameNum = frameNum;
                    end
                else
                    % Zoom in or out
                    zoomFactor = 2^scrollCount;
                    obj.NavigationZoom = obj.NavigationZoom * zoomFactor;
                    if obj.NavigationZoom > 1
                        % No point in allowing user to zoom further out the
                        % showing whole plot
                        obj.NavigationZoom = 1;
                    end
                    obj.drawNavigationData(false);
                end
            end
        end
        function [inVideoAxes, inNavigationAxes, inNavigationDivider] = whereIsMouse(obj, x, y)
            if obj.inVideoAxes(x, y)
                inVideoAxes = true;
                inNavigationAxes = false;
                inNavigationDivider = false;
            elseif obj.inNavigationAxes(x, y)
                inVideoAxes = false;
                inNavigationAxes = true;
                inNavigationDivider = false;
            elseif obj.inNavigationDivider(x, y)
                inVideoAxes = false;
                inNavigationAxes = false;
                inNavigationDivider = true;
            else
                inVideoAxes = false;
                inNavigationAxes = false;
                inNavigationDivider = false;
            end
        end
        function MouseMotionHandler(obj, ~, ~)
            % Handle mouse motion events
            [xFig, yFig] = obj.GetCurrentVideoPanelPoint();

            [inVideoAxes, inNavigationAxes, inNavigationDivider] = obj.whereIsMouse(xFig, yFig);

            if inVideoAxes
                [x, y] = obj.getCurrentVideoPoint();
                if x > 0 && y > 0 && ~isempty(obj.VideoFrame) && x <= obj.VideoFrame.XData(2) && y <= obj.VideoFrame.YData(2)
                    switch obj.NumColorChannels
                        case 1
                            val = num2str(obj.VideoData(y, x, obj.CurrentFrameNum));
                        case 3
                            val = num2str(obj.VideoData(y, x, :, obj.CurrentFrameNum));
                        otherwise
                            error('Invalid number of color channels');
                    end
                    obj.StatusBar.String = sprintf('Video pixel: %d, %d = (%s)', x, y, val);
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
            if inNavigationAxes
                frameNum = obj.mapFigureXToFrameNum(xFig);
                if ~obj.isPlaying()
                    % Do not change frame during mouseover if video is
                    % playing
                    obj.CurrentFrameNum = frameNum;
                end
                if obj.IsSelectingFrames && obj.FrameSelectStart > 0 && frameNum > 0
                    selectBounds = sort([obj.FrameSelectStart, frameNum]);
                    switch obj.MainFigure.SelectionType
                        case 'normal'
                            obj.FrameSelection(selectBounds(1):selectBounds(2)) = true;
                        case 'alt'
                            obj.FrameSelection(selectBounds(1):selectBounds(2)) = false;
                    end
                end
                obj.StatusBar.String = sprintf('Frame = %d / %d, time = %0.3f s', frameNum, obj.getNumFrames(), frameNum / obj.VideoFrameRate);
            end
            if inNavigationDivider
            end
            if ~inVideoAxes && ~inNavigationAxes && ~inNavigationDivider
                if isempty(obj.VideoPath)
                    obj.StatusBar.String = 'Video from array';
                else
                    obj.StatusBar.String = abbreviateText(obj.VideoPath, 100, 0.25);
                end
            end
            if obj.IsNavDividerDragging
                obj.setNavigationAxesHeightFraction(yFig);
            end
        end
        function MouseDownHandler(obj, ~, ~)
            % Handle user mouse click
            [xFig, yFig] = obj.GetCurrentVideoPanelPoint();

            [~, inNavigationAxes, inNavigationDivider] = obj.whereIsMouse(xFig, yFig);

            if inNavigationAxes
                % Mouse click is in navigation axes
                frameNum = obj.mapFigureXToFrameNum(xFig);
                obj.FrameSelectStart = frameNum;
                obj.IsSelectingFrames = true;

                % Set current frame to the click location
                obj.CurrentFrameNum = frameNum;
                if obj.isPlaying()
                    obj.restartVideo();
                end
            end
            if inNavigationDivider
            end
        end
        function MouseUpHandler(obj, ~, ~)
            obj.IsSelectingFrames = false;
            obj.IsNavDividerDragging = false;
        end
        function ChangeSpeedHandler(obj, evt, direction)
            % Video is playing - instead of changing frame, change
            % playback speed
            if any(strcmp(evt.Modifier, 'control'))
                % User is holding down control - change by 10 fps
                delta = 10 * direction;
            else
                % Change speed by 1 fps
                delta = 1 * direction;
            end
            warning('off', 'MATLAB:TIMER:RATEPRECISION');
            obj.PlaybackSpeed = obj.PlaybackSpeed + delta;
            warning('on', 'MATLAB:TIMER:RATEPRECISION');
        end
        function ChangeFrameHandler(obj, evt, direction)
            % direction should be 1 or -1
            select = false;
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
        function KeyReleaseHandler(obj, ~, evt)
            switch evt.Key
                case 'shift'
                    obj.ShiftKeyDown = false;
            end
        end
        function KeyPressHandler(obj, ~, evt)
            switch evt.Key
                case 'escape'
                    obj.clearSelection();
                case 'space'
                    if obj.isPlaying()
                        obj.stopVideo();
                    else
                        % Check if user wants to play only selected frames
                        selectedOnly = any(strcmp(evt.Modifier, 'control')) && any(obj.FrameSelection);
                        % Start playback
                        obj.playVideo(selectedOnly);
                    end
                case 'shift'
                    obj.ShiftKeyDown = true;
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
                            videoData = obj.VideoData(:, :, :, selection);
                        else
                            videoData = obj.VideoData(:, :, selection);
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
                    if obj.isPlaying()
                        obj.ChangeSpeedHandler(evt, 1);
                    else
                        obj.ChangeFrameHandler(evt, 1);
                    end
                case 'leftarrow'
                    if obj.isPlaying()
                        obj.ChangeSpeedHandler(evt, -1);
                    else
                        obj.ChangeFrameHandler(evt, -1);
                    end
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
            if isvalid(obj.AVPlayer)
                stop(obj.AVPlayer);
            end
            delete(obj.AVPlayer);
            obj.deleteDisplayArea();
        end
    end
end