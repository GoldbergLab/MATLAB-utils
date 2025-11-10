classdef VideoBrowser < handle
    % VideoBrowser A class representing a simple graphical video browser
    %   This class creates a window where a video frame is displayed.
    %       A separate axes contains a 1D graph representing some value for
    %       each frame. Moving the mouse over this navigational axes causes
    %       the video frame to update to the corresponding frame number.
    properties (Access = protected)
        VideoFrame              matlab.graphics.primitive.Image     % An image object containing the video frame image
        FrameMarker             matlab.graphics.primitive.Line      % A line on the NavigationAxes marking what frame is displayed
        FrameNumberMarker       matlab.graphics.primitive.Text      % Text on the NavigationAxes indicating what frame number is displayed
        AVPlayer                audioplayer                         % An object for playing the audio and video
        PlayIncrement           double = 1                          % Number of frames the play timer will advance by on each call.
        NumColorChannels        double                              % Number of color channels in the video (1 for grayscale, 3 for color)
        NavigationRedrawEnable  logical = false                     % Enable or disable navigation redraw
        StatusBar               matlab.ui.control.UIControl         % Bottom status bar widget
        HelpButton              matlab.ui.control.UIControl         % Help button widget
        IsZooming               logical = false                     % Boolean flag indicating whether the user is currently zooming in/out on the video axes
        ZoomStart               double = []                         % Start coordinates of zoom box
        ZoomBox                 matlab.graphics.primitive.Rectangle % Handle to zoom box rectangle
        IsSelectingFrames       logical = false                     % Boolean flag indicating whether or not user is currently selecting frames in the navigation axes
        IsNavDividerDragging    logical = false                     % Boolean flag indicating whether or not user is currently dragging the navigation divider
        FrameSelectStart        double                              % Start frame of new frame selection
        FrameSelectionHandles   matlab.graphics.primitive.Rectangle % Handles to selection highlight rectangles
%        NavigationMapMode       char = 'frame'                      % Determine how the navigation axis position is mapped to a frame number - either 'frame' or 'time'
        VideoFrameRate          double = 30                         % Frame rate of video (in frames per second)
        AudioSampleRate         double = 44100                      % Sample rate of audio (in samples per second)
        NavigationZoom          double = 1                          % Current navigation axes zoom factor
        ShiftKeyDown            logical = false                     % Boolean flag indicating whether or not the shift key is currently down
        NavigationDivider       matlab.ui.control.UIControl         % A button to allow user to drag navigation axes larger or smaller
        ProfileTimes            uint64 = zeros(1, 10, 'uint64')
        ProfileTimestamps       uint64 = zeros(1, 10, 'uint64')
        ProfileCounts           double = zeros(1, 10)
        Async                   logical = true
        AsyncVideoReader        VideoReaderAsync
    end
    properties
        MainFigure              matlab.ui.Figure                    % The main figure window
        VideoPanel              matlab.ui.container.Panel           % Panel that contains video and nav axes
        VideoAxes               matlab.graphics.axis.Axes           % Axes for displaying the video frame
        NavigationPanel         matlab.ui.container.Panel           % Panel containing one or more navigation axes
        NavigationAxes          matlab.graphics.axis.Axes           % Axes for displaying the 1D metric
    end
    properties
        NavigationScrollMode    char = 'sweep'        % How should navigation axes scroll when zoomed in? One of 'centered' (keep cursor centered), 'partial' (keep cursor within a margin), 'sweep' (jump view when cursor gets near end), 'none' (no scrolling)
        ChannelMode = 'all'                             % For multichannel navigation data, which channels should be displayed when navigation function is 'audio' or 'spectrogram'. One of 'all', 'first', or a scalar/vector of channel indices
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
        function obj = VideoBrowser(VideoData, options)
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
            %   The following are optional name-value pairs:
            %   NavigationData = one of the following, or a cell array
            %           containing multiple of these options. If a cell 
            %           array is passed, multiple navigation axes will be,
            %           stacked each showing the selected navigation 
            %           options in order from top tobottom.
            %       1. A 1 x N array, to be plotted in the NavigationAxes
            %       2. A function handle which takes N x H x W (x 3)
            %           VideoData array as an argument and returns a 1 x N 
            %           array as a result, to be plotted in the 
            %           NavigationAxes
            %       3. A string referring to one of the predefined
            %           video-analysis functions:
            %           - 'sum' - plot sum of pixel values in each frame
            %           - 'diff' - plot change in total pixel values in
            %               each frame
            %           - 'compactness' - plot measure of how compact the
            %               blobs of pixel values are
            %       3. A string referring to one of the predefined
            %           audio-analysis functions:
            %           - 'audio' - plot the raw audio waveforms
            %           - 'spectrogram' - plot a spectrogram of the audio
            %       4. An empty array, or omitted, which results in blank 
            %           NavigationAxes
            %   NavigationColor = an optional color specification for the 
            %       points in the NavigationAxes scatter plot. See the 
            %       color argument for the scatter function for 
            %       documentation. This can also be a cell array if 
            %       multiple navigation axes are specified in the 
            %       NavigationDataOrFcn argument.
            %   NavigationColormap = an optional colormap for the 
            %       navigation axes. This can also be a cell array if 
            %       multiple navigation axes arespecified in the 
            %       NavigationDataOrFcn argument.
            %   NavigationCLim = optional color limits for the navigation 
            %       axes, expressed as a two-element vector [cmin, cmax].
            %       This can also be a cell array if multiple navigation 
            %       axes are specified in the NavigationDataOrFcn argument.
            %   Async = on optional boolean flag indicating whether or not
            %       to load the video asynchronously in the background.
            %   title = a char array to use as the image title
            arguments
                VideoData = []
                options.NavigationData = [];
                options.NavigationColor = 'black';
                options.NavigationColormap = colormap();
                options.NavigationCLim = [13.0000, 24.5000]
                options.NavigationScrollMode {mustBeMember(options.NavigationScrollMode, {'centered', 'partial', 'sweep', 'none'})} = 'sweep' 
                options.Title = '';
                options.Async logical = true;
                options.VideoFrameRate = 30
                options.AudioSampleRate = 44100
            end

            obj.VideoFrameRate = options.VideoFrameRate;
            obj.AudioSampleRate = options.AudioSampleRate;

            obj.Async = options.Async;

            NavigationDataOrFcns = options.NavigationData;
            NavigationColors = options.NavigationColor;
            NavigationColormaps = options.NavigationColormap;
            NavigationCLims = options.NavigationCLim;
            obj.Title = options.Title;
            obj.NavigationScrollMode = options.NavigationScrollMode;

            % We'll need the same # of NavigationDataOrFcn, NavigationColor, NavigationColormap, NavigationCLim
            if ~iscell(NavigationDataOrFcns)
                NavigationDataOrFcns = {NavigationDataOrFcns};
            end
            numNavigationAxes = length(NavigationDataOrFcns);
            NavigationColors = VideoBrowser.matchCellArg(NavigationColors, numNavigationAxes);
            NavigationColormaps = VideoBrowser.matchCellArg(NavigationColormaps, numNavigationAxes);
            NavigationCLims = VideoBrowser.matchCellArg(NavigationCLims, numNavigationAxes);
            obj.NavigationData = cell(1, numNavigationAxes);
            obj.NavigationDataFunction = cell(1, numNavigationAxes);

            % Create all the graphics widgets
            obj.createDisplayArea();

            for axNum = 1:obj.getNumNavigationAxes()
                obj.NavigationAxes(axNum).CLim = NavigationCLims{axNum};
            end

            if iscell(VideoData)
                % User must be passing video data and audio data together
                obj.loadNewVideoData(VideoData{1});
%                 obj.VideoData = VideoData{1};
                obj.AudioData = VideoData{2};
            else
                obj.loadNewVideoData(VideoData);
%                 obj.VideoData = VideoData;
            end

            % Temporarily disable drawing navigation to prevent all the
            % setters from triggering a redraw multiple times
            obj.NavigationRedrawEnable = false;
            
            obj.Colormap = NavigationColormaps;
            obj.NavigationColor = NavigationColors;

            % Sort out what the user wants to show in the navigation axes
            for k = 1:length(NavigationDataOrFcns)
                NavigationDataOrFcn = NavigationDataOrFcns{k};
                switch class(NavigationDataOrFcn)
                    case 'function_handle'
                        % User has passed in a function handle to create the
                        % navigation data to plot
                        obj.NavigationData{k} = [];
                        obj.NavigationDataFunction{k} = NavigationDataOrFcn;
                    case 'char'
                        % User has passed in a predefined named function
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
                        obj.NavigationData{k} = [];
                        switch NavigationDataOrFcn
                            case 'sum'
                                obj.NavigationDataFunction{k} = @(videoData)squeeze(sum(videoData, sumDims));
                            case 'diff'
                                obj.NavigationDataFunction{k} = @(videoData)smooth(squeeze(sum(diff(videoData, frameDim), sumDims)), 10);
                            case 'compactness'
                                obj.NavigationDataFunction{k} = @(videoData)squeeze(sum(videoData, sumDims)) ./ squeeze(sum(getMaskSurface(videoData), sumDims));
                            case 'audio'
                                obj.FrameMarkerColor = 'black';
                                obj.NavigationData{k} = obj.AudioData;
                                obj.NavigationDataFunction{k} = NavigationDataOrFcn;
                            case 'spectrogram'
                                obj.FrameMarkerColor = 'white';
                                obj.NavigationDataFunction{k} = NavigationDataOrFcn;
                            otherwise
                                error('Unrecognized named navigation data function: %s.', NavigationDataOrFcn);
                        end
                    case {'double', 'uint8'}
                        % User must be passing in an actual vector of data to
                        % plot on the navigation axes
                        obj.NavigationData{k} = NavigationDataOrFcn;
                        obj.NavigationDataFunction{k} = [];
                    otherwise
                        error('NavigationDataOrFcn argument must be of type function_handle, char, double, or uint8, not %s.', class(NavigationDataOrFcn));
                end
    
                % Initialize frame selection (no frames initially selected)
                obj.FrameSelection = false(1, size(obj.VideoData, ndims(obj.VideoData)));
    
                % Re-enable navigation redraw, now that everything is set up
                obj.NavigationRedrawEnable = true;
    
                % Update navigation axes
                obj.drawNavigationData();
            end
        end
        function showHelp(obj, ~, ~, ~) %#ok<INUSD> 
            % Display the help text in a message box
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
'   right click on nav axes =         open context menu';
'                                        spectrogram mode: edit clim'
'   left click/drag on nav axes =     select region of video';
'   right click/drag on nav axes =    deselect region of video';
'   scroll wheel =                    zoom in/out for nav axes or video';
'                                     frame'
};
            f = figure();
            f.UserData.text = uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.01, 0.01, 0.99, 0.99], 'FontName', 'Monospaced', 'String', helpText, 'HorizontalAlignment','left');
        end
        function playVideo(obj, selectedOnly)
            % Start audio/video playback
            
            if ~exist('selectedOnly', 'var') || isempty(selectedOnly)
                % By default play all frames, not just the selected ones
                selectedOnly = false;
            end
            warning('off', 'MATLAB:TIMER:RATEPRECISION');
            warning('off', 'MATLAB:timer:miliSecPrecNotAllowed');
            if obj.PlaybackSpeed < 0
                % Play backwards
                obj.PlayIncrement = -1;
            else
                % Play forwards
                obj.PlayIncrement = 1;
            end

            % If the AVPlayer object already exists, delete it
            delete(obj.AVPlayer);

            if selectedOnly
                % If we're only playing selected frames, switch to the next
                % selected frame
                obj.CurrentFrameNum = obj.findNextSelectedFrameNum(obj.CurrentFrameNum, obj.PlayIncrement);
            end

            % Determine what audio sample # we're starting on
            currentAudioSample = obj.getCurrentAudioSample();

            % Get the audio data from the current sample onward
            audioData = obj.AudioData(:, currentAudioSample:end)';

            if isempty(audioData)
                % Create blank audio data if there's none
                audioData = zeros(1, round(obj.getNumFrames() * obj.AudioSampleRate / obj.VideoFrameRate));
            end

            % Determine audio playback speed corresponding to the desired video playback speed
            audioPlaybackSpeed = obj.AudioSampleRate * obj.PlaybackSpeed / obj.VideoFrameRate;

            % Construct the new AVPlayer object
            obj.AVPlayer = audioplayer(audioData, audioPlaybackSpeed);
            obj.AVPlayer.TimerFcn = @(~, ~)obj.playFcn(selectedOnly);
            obj.AVPlayer.TimerPeriod = 1 / abs(obj.PlaybackSpeed);
            obj.AVPlayer.UserData.selectedOnly = selectedOnly;
            obj.AVPlayer.UserData.startSample = currentAudioSample;
            obj.AVPlayer.UserData.WarnedAboutSkippingFrames = false;

            % Start playback
            obj.AVPlayer.play();
            warning('on', 'MATLAB:TIMER:RATEPRECISION');
            warning('on', 'MATLAB:timer:miliSecPrecNotAllowed');
        end
        function tic(obj, timerNum)
            obj.ProfileTimestamps(timerNum) = tic();
        end
        function toc(obj, timerNum)
            obj.ProfileTimes(timerNum) = obj.ProfileTimes(timerNum) + (tic() - obj.ProfileTimestamps(timerNum));
            obj.ProfileCounts(timerNum) = obj.ProfileCounts(timerNum) + 1;
        end
        function showTimes(obj)
            fprintf('\n');
            for timerNum = 1:length(obj.ProfileTimes)
                fprintf('Timer #%02d: %f sec, %03d calls, %f sec/call, max freq: %f Hz\n', timerNum, double(obj.ProfileTimes(timerNum))/10000000, obj.ProfileCounts(timerNum), double(obj.ProfileTimes(timerNum)/obj.ProfileCounts(timerNum))/10000000, 1/(double(obj.ProfileTimes(timerNum)/obj.ProfileCounts(timerNum))/10000000));
            end
        end
        function clearTimes(obj)
            for timerNum = 1:length(obj.ProfileTimes)
                obj.ProfileCounts(timerNum) = 0;
                obj.ProfileTimes(timerNum) = 0;
                obj.ProfileTimestamps(timerNum) = 0;
            end
        end
        function playFcn(obj, selectedOnly)
            arguments
                obj VideoBrowser
                selectedOnly logical
            end

            % Display a new frame of the video while in play mode
            audioTime = (obj.AVPlayer.UserData.startSample + obj.AVPlayer.CurrentSample - 1) / obj.AudioSampleRate;

            try
                % Calculate how far we have to skip the video to keep up
                % with the audio. If the video is keeping up, delta will
                % equal 1, if not, delta will be > 1
                lastFrame = obj.CurrentFrameNum;
                nextFrame = round(audioTime * obj.VideoFrameRate);
                delta = nextFrame - lastFrame;

                if ~obj.AVPlayer.UserData.WarnedAboutSkippingFrames && delta > 1
                    % Warn the user that we're skipping frames to keep the
                    % video synced with audio, but only once
                    warning('Warning, video display not keeping up with playback - skipping frames');
                    obj.AVPlayer.UserData.WarnedAboutSkippingFrames = true;
                end

                if selectedOnly
                    % Move to next selected frame
                    obj.incrementSelectedFrame(delta);
                else
                    % Move to next frame
                    obj.incrementFrame(delta);
                end
                
                % Update status bar
                obj.StatusBar.String = sprintf('Playing: Frame = %d / %d, time = %0.3f s', obj.CurrentFrameNum, obj.getNumFrames(), obj.CurrentFrameNum / obj.VideoFrameRate);
%                 drawnow;
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
            % Stop audio/video playback
            stop(obj.AVPlayer);
            delete(obj.AVPlayer);
        end
        function restartVideo(obj)
            % Stop, then restart audio/video playback
            selectedOnly = obj.IsPlayingSelectedOnly();
            obj.stopVideo();
            obj.playVideo(selectedOnly);
        end
        function playing = isPlaying(obj)
            % Check if video is currently playing
            playing = ~isempty(obj.AVPlayer) && isvalid(obj.AVPlayer) && strcmp(obj.AVPlayer.Running, 'on');
        end
        function incrementFrame(obj, delta)
            % Increment the current frame number by delta
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
            if obj.isPlaying() && skipAmount ~= delta
                % If we're skipping to some other frame other than the
                % next one, we need to restart the player so the audio
                % will skip with the video
                obj.restartVideo()
            end
        end
        function audioSample = getCurrentAudioSample(obj)
            % Determine the audio sample that corresponds to the currently
            % displayed video frame
            audioSample = obj.convertFrameNumberToAudioSample(obj.CurrentFrameNum);
        end
        function audioSample = convertFrameNumberToAudioSample(obj, frameNum)
            % Determine the audio sample that corresponds to a frame number
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
            obj.NavigationPanel.Position =   rangeCoerce([margin, statusBarHeight + margin,  1-2*margin, fraction - 1.5 * margin - statusBarHeight], [0, 1]);
            N = obj.getNumNavigationAxes();
            for k = 1:N
                obj.NavigationAxes(k).Position = [0, 1-(k/N), 1, 1/N];
            end
            obj.NavigationDivider.Position = rangeCoerce([margin, fraction-dividerHeight/2,  1-2*margin, dividerHeight], [0, 1]);
            obj.VideoAxes.Position =         rangeCoerce([margin, fraction + 2*margin,       1-2*margin, 1-fraction - 1.5 * margin], [0, 1]);
        end
        function NavigationDividerMouseDown(obj, ~, ~)
            obj.IsNavDividerDragging = true;
        end
        function numNavigationAxes = getNumNavigationAxes(obj)
            numNavigationAxes = length(obj.NavigationData);
        end
        function createDisplayArea(obj)
            % Create & prepare the graphics containers (the figure & axes)
            
            % Delete graphics containers in case they already exist
            obj.deleteDisplayArea();
            
            % Create graphics containers
            obj.MainFigure =        figure('Units', 'normalized', 'BusyAction', 'cancel');
            obj.VideoPanel =        uipanel(obj.MainFigure, 'Units', 'normalized', 'Position', [0, 0, 1, 1]);
            obj.VideoAxes =         axes(obj.VideoPanel, 'Units', 'normalized', 'Visible', false);
            obj.NavigationPanel =   uipanel(obj.VideoPanel, 'Units', 'normalized');
            obj.UpdateNavigationAxes();

            obj.NavigationDivider = uicontrol(obj.VideoPanel, 'ForegroundColor', 'black', 'BackgroundColor', 'black', 'Style','text', 'Units', 'normalized', 'String', '----------------------------', 'Visible','on', 'BackgroundColor', obj.MainFigure.Color, 'ButtonDownFcn', @obj.NavigationDividerMouseDown, 'Enable', 'off');
            obj.StatusBar =  uicontrol(obj.VideoPanel, 'Style', 'text', 'Units', 'normalized', 'String', '', 'HorizontalAlignment', 'left');
            obj.HelpButton = uicontrol(obj.VideoPanel, 'Style', 'pushbutton', 'Units', 'normalized', 'String', '?', 'HorizontalAlignment', 'center', 'Callback', @obj.showHelp);

            % Style graphics containers
            obj.MainFigure.ToolBar = 'none';
            obj.MainFigure.MenuBar = 'none';
            obj.MainFigure.NumberTitle = 'off';
            obj.MainFigure.Name = 'Video Browser';

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
            obj.VideoAxes.Visible = true;

            obj.setNavigationAxesHeightFraction(0.175);
            
            % Configure callbacks
            obj.MainFigure.WindowButtonMotionFcn = @obj.MouseMotionHandler;
            obj.MainFigure.WindowButtonUpFcn = @obj.MouseUpHandler;
            obj.MainFigure.WindowButtonDownFcn = @obj.MouseDownHandler;
            obj.MainFigure.WindowScrollWheelFcn = @obj.ScrollHandler;
            obj.MainFigure.BusyAction = 'cancel';
            obj.MainFigure.KeyPressFcn = @obj.KeyPressHandler;
            obj.MainFigure.KeyReleaseFcn = @obj.KeyReleaseHandler;
            obj.MainFigure.SizeChangedFcn = @obj.ResizeHandler;

            drawnow()
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
        function clearNavigationData(obj, axNum)
            % Clear the NavigtationAxes
            cla(obj.NavigationAxes(axNum));
        end
%         function color = getNavigationColorPoint(obj, frameNum)
%             if ischar(obj.NavigationColor)
%                 % Single color string provided
%                 color = obj.NavigationColor;
%             elseif isnumeric(obj.NavigationColor)
%                 if isrow(obj.NavigationColor) && length(obj.NavigationColor) == 3
%                     % Single RGB triplet provided
%                     color = obj.NavigationColor;
%                 elseif size(obj.NavigationColor, 2) == 3 && size(obj.NavigationColor, 1) > 1
%                     % 3-column array of RGB triplets provided, one color
%                     % per row
%                     color = obj.NavigationColor(frameNum, :);
%                 elseif isvector(obj.NavigationColor)
%                     % Color palette index has been provided
%                     color = obj.NavigationAxes.Colormap(frameNum, :);
%                 end
%             end
%         end
        function updateNavigationXLim(obj)
            % Keep the navigation axes x limits up to date based on the
            % desired behavior
            numSamples = size(obj.NavigationData{1}, 2);
            if numSamples == 0
                % No nav data yet, don't bother
                return;
            end

            % Calculate xlim
            fullTLim = [0, obj.getDuration()];

            % Determine the current axes x value (time) corresponding to 
            % the current frame number
            tCenter = obj.mapFrameNumToAxesX(obj.CurrentFrameNum);

            % Determine current x limits of navigation axes
            currentTLim = xlim(obj.NavigationAxes(1));

            % Determine fraction of the way across the navigation axes the
            % current frame is
            currentXFraction = (tCenter - currentTLim(1)) / diff(currentTLim);

            % Calculate the desired x width of the navigation axes based on
            % the zoom level
            tWidth = diff(fullTLim) * obj.NavigationZoom;
            switch obj.NavigationScrollMode
                case 'centered'
                    % User wants the frame marker to always be in the
                    % center of the axes
                    newTLim = [tCenter - tWidth*0.5, tCenter + tWidth*0.5];
                case 'sweep'
                    % User wants view to jump forward whenever cursor gets
                    % near edge
                    margin = 0.1;
                    if currentXFraction < margin
                        % Need to scroll the axes left
                        currentXFraction = 1-margin;
                    end
                    if currentXFraction > (1-margin)
                        % Need to scroll the axes right
                        currentXFraction = margin;
                    end
                    % Calculate new navigation axes xlim
                    newTLim = [tCenter - tWidth*currentXFraction, tCenter + tWidth*(1-currentXFraction)];
                case 'partial'
                    % User wants the frame marker to move across the
                    % navigation axes, but the axes should start scrolling
                    % when the marker gets near the edge, to prevent the
                    % marker from going offscreen
                    margin = 0.2; % How close to edge cursor is before beginning to scroll axes (expressed as fraction of whole width)
                    if currentXFraction < margin
                        % Need to scroll the axes left
                        currentXFraction = margin;
                    end
                    if currentXFraction > (1-margin)
                        % Need to scroll the axes right
                        currentXFraction = (1-margin);
                    end
                    % Calculate new navigation axes xlim
                    newTLim = [tCenter - tWidth*currentXFraction, tCenter + tWidth*(1-currentXFraction)];
                case 'none'
                    % User wants no scrolling - the frame marker may go off
                    % the visible part of the navigation axes.
                    newTLim = [tCenter - tWidth*currentXFraction, tCenter + tWidth*(1-currentXFraction)];
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
            % Set the new x limits
            xlim(obj.NavigationAxes(1), newTLim);            
        end
        function updateNavigationData(obj, axNum)
            % Update the data plotted on the kth navigation axes
            if istext(obj.NavigationDataFunction{axNum}) && ~isempty(obj.NavigationDataFunction{axNum})
                % Navigation data function is a char array - must be a
                % named function
                switch obj.NavigationDataFunction{axNum}
                    case {'audio', 'spectrogram'}
                        obj.NavigationData{axNum} = obj.AudioData;
                    otherwise
                        error('Unknown named navigation function: %s', obj.NavigationDataFunction{axNum});
                end
            elseif ~isempty(obj.NavigationDataFunction{axNum}) && ~isempty(obj.VideoData)
                % Navigation data function must be an actual function handle -
                % apply it
                obj.NavigationData{axNum} = obj.NavigationDataFunction{axNum}(obj.VideoData);
            end

            if isempty(obj.NavigationData{axNum})
                % Fallback null nav data
                obj.NavigationData{axNum} = zeros(1, obj.getNumFrames());
            end

            if size(obj.NavigationData{axNum}, 1) > size(obj.NavigationData{axNum}, 2)
                % Ensure channel # is first dimension
                obj.NavigationData{axNum} = obj.NavigationData{axNum}';
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
            
            for axNum = 1:obj.getNumNavigationAxes()
                obj.updateNavigationData(axNum);
    
                numSamples = size(obj.NavigationData{axNum}, 2);
                numChannels = size(obj.NavigationData{axNum}, 1);
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
    
                if isempty(obj.NavigationData{axNum})
                    % No navigation data - just clear the axes
                    obj.clearNavigationData(axNum);
                elseif strcmp(obj.NavigationDataFunction{axNum}, 'spectrogram')
                    % User requested spectrogram of audio data
                    % Note that this algorithm precisely follows the method in
                    % electro_gui's default spectrogram plugin
    
                    % Calculate x limits
                    fullTLim = [0, numSamples / obj.AudioSampleRate];
    
                    % Define frequency axis (vertical) limits in Hz
                    flim = [50, 7500];
    
                    % Define separation between spectrograms in the case of
                    % multiple stacked channels, in units of Hz
                    stackSeparation = 100;
    
                    % Calculate vertical distance from the start of one 
                    % spectrogram to the start of the next, in the case of
                    % multiple stacked channels
                    fWidth = diff(flim) + stackSeparation;
    
                    if replot
                        % Replot spectrogram, rather than merely updating axes
                        % settings
    
                        % Clear axes
                        obj.clearNavigationData(axNum);
    
                        % Determine width of axes in pixels
                        originalUnits = obj.NavigationAxes(axNum).Units;
                        obj.NavigationAxes(axNum).Units = 'pixels';
                        pixSize = obj.NavigationAxes(axNum).Position;
                        obj.NavigationAxes(axNum).Units = originalUnits;

                        % Set colormap
    
                        % Time resolution of spectrogram relative to axes width
                        nCourse = 0.005;
                        tSize = pixSize(3) / nCourse;
                        hold(obj.NavigationAxes(axNum), 'on');
                        
                        for channelIdx = 1:length(channelList)
                            % Loop over each channel in audio, creating stacked
                            % spectrograms
    
                            % Determine which channel we're plotting
                            channel = channelList(channelIdx);
    
                            % Get this channel of audio data
                            audio = obj.NavigationData{axNum}(channel, :);
    
                            % Compute spectrogram matrix
                            power = getAudioSpectrogram(audio, obj.AudioSampleRate, flim, tSize);
    
                            % Determine number of frequency and time bins in
                            % spectrogram
                            nFreqBins = size(power, 1);
                            nTimeBins = size(power, 2);
    
                            % Create time and frequency vectors to use for
                            % placing the spectrogram on the axes
                            t = linspace(fullTLim(1), fullTLim(2), nTimeBins);
                            freqShift = fWidth*(channelIdx-1);
                            f = linspace(flim(1)+freqShift,flim(2)+freqShift,nFreqBins);
    
                            % Plot the spectrogram on the axes as an image
                            imagesc(t,f,power, 'Parent', obj.NavigationAxes(axNum), 'HitTest', 'off', 'PickableParts', 'none');
                        end
                    end
    
                    % Set the y limits of the navigation axes based on the
                    % frequency limits of the one or more spectrograms
                    % displayed
                    ylim(obj.NavigationAxes(axNum), [flim(1), flim(2) + fWidth*(numChannelsToDisplay-1)]);
                    
                    % Set direction of y axis 
                    set(obj.NavigationAxes(axNum), 'YDir', 'normal');
    
                    % Set color map of axes
                    c = colormap(obj.NavigationAxes(axNum), 'parula');
    
                    % To improve visual contrast, ensure that the color
                    % representing the lowest power of the spectrogram is pure
                    % black
                    c(1, :) = [0, 0, 0];
                    colormap(obj.NavigationAxes(axNum), c);
                    
                    % Label the axes
                    ylabel(obj.NavigationAxes(axNum), 'Frequency (Hz)');
                    xlabel(obj.NavigationAxes(axNum), 'Time (s)');
                    hold(obj.NavigationAxes(axNum), 'off');
                else
                    % User has a regular vector (or vectors) of data to plot 
                    % on the navigation axes
    
                    % Update navigation axes color map
                    obj.NavigationAxes(axNum).Colormap = obj.Colormap{axNum};
                    
                    % Determine maximum range of navigation data vector
                    dataRange = max(max(obj.NavigationData{axNum}, [], 2) - min(obj.NavigationData{axNum}, [], 2));
    
                    % Determine spacing of channels, in the case of multiple
                    % stacked channels (1.1 factor is to provide a small margin
                    % between stacked plots)
                    dataSpacing = dataRange * 1.1;
    
                    if replot
                        % Replot data, rather than merely updating axes 
                        % settings
    
                        % Save original data limits of axes
                        originalXLim = obj.NavigationAxes(axNum).XLim;
                        originalYLim = obj.NavigationAxes(axNum).YLim;
    
                        % Data needs to actually be redrawn
                        obj.clearNavigationData(axNum);
    
                        % Stupid hack to force MATLAB to draw axes background
                        p = plot(obj.NavigationAxes(axNum), originalXLim, originalYLim);
                        delete(p);
                        
                        % Reset data limits
                        obj.NavigationAxes(axNum).XLim = originalXLim;
                        obj.NavigationAxes(axNum).YLim = originalYLim;
    
                        t = linspace(0, obj.getDuration() + obj.getDuration()/numSamples, numSamples);
    
                        for channelIdx = 1:length(channelList)
                            % Loop over channels of data
                            channel = channelList(channelIdx);
    
                            % Plot the navigation data
                            linec(t, obj.NavigationData{axNum}(channel, :) + dataSpacing*(channelIdx-1), 'Color', obj.NavigationColor{axNum}, 'Parent', obj.NavigationAxes(axNum));
                %             scatter(1:length(navigationData), navigationData, 1, obj.NavigationColor, '.', 'Parent', obj.NavigationAxes);
                        end
                        
                        % Determine minimum y value of first channel of data
                        minY = min(obj.NavigationData{axNum}(1, :));
    
                        % Determine appropriate y limits for navigation axes
                        navigationYLim = [minY, minY + dataRange + dataSpacing*(numChannelsToDisplay-1)];
    
                        if diff(navigationYLim) <= 0
                            % Nav data has no vertical range - use a default
                            % instead
                            navigationYLim = [-1, 1];
                        end
    
                        % Set new y limits for navigation axes
                        ylim(obj.NavigationAxes(axNum), navigationYLim);
                    end
                end
    
                obj.updateNavigationXLim();

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
        function duration = getDuration(obj)
            % Determine duration of video in seconds
            duration = obj.getNumFrames() / obj.VideoFrameRate;
        end
        function updateNavigationAxesContextMenu(obj, axNums)
            arguments
                obj VideoBrowser
                axNums double = 1:obj.getNumNavigationAxes()
            end
            if isempty(obj.MainFigure)
                % Main figure hasn't been created yet, skip this.
                return;
            end
            for axNum = axNums
                context_menu = uicontextmenu(obj.MainFigure);
                menu_item = uimenu(context_menu, "Text", 'Alter color limits');
                menu_item.MenuSelectedFcn = @(~, ~)CLimGUI(obj.NavigationAxes(axNum));
                obj.NavigationAxes(axNum).ContextMenu = context_menu;
            end
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
            numNavigtionAxes = obj.getNumNavigationAxes();
            if length(obj.FrameMarker) ~= numNavigtionAxes
                delete(obj.FrameMarker);
                obj.FrameMarker = matlab.graphics.primitive.Line.empty();
            end
            for axNum = 1:numNavigtionAxes
                if length(obj.FrameMarker) < axNum || isempty(obj.FrameMarker) || isempty(obj.FrameMarker(axNum)) || ~isvalid(obj.FrameMarker(axNum))
                    obj.FrameMarker = [obj.FrameMarker, line([x, x], obj.NavigationAxes(axNum).YLim, 'Parent', obj.NavigationAxes(axNum), 'Color', obj.FrameMarkerColor, 'HitTest', 'off', 'PickableParts', 'none')];
                else
                    obj.FrameMarker(axNum).XData = [x, x];
                    obj.FrameMarker(axNum).YData = ylim(obj.NavigationAxes(axNum));
                end
            end

%             % Update frame number label
%             scale = obj.getFrameToAxesUnitScale();
%             switch obj.NavigationMapMode
%                 case 'time'
%                     frameNumberString = sprintf('%0.2f', x);
%                 case 'frame'
%                     frameNumberString = sprintf('%d', x);
%             end
%             if isempty(obj.FrameNumberMarker) || ~isvalid(obj.FrameNumberMarker)
%                 obj.FrameNumberMarker = text(obj.NavigationAxes, x + 20/scale, mean(obj.NavigationAxes.YLim), frameNumberString, 'Color', obj.FrameMarkerColor, 'HitTest', 'off', 'PickableParts', 'none');
%             else
%                 obj.FrameNumberMarker.Position(1) = x + 20 / (scale / obj.NavigationZoom);
%                 obj.FrameNumberMarker.String = frameNumberString;
%             end
        end
        function updateFrameSelection(obj, axNums)
            % Update the selection display to match the current selection

            % Clear old selection highlight
            delete(obj.FrameSelectionHandles);
            obj.FrameSelectionHandles(:) = [];

            % Create new selection highlight
            highlight_x = linspace(0, obj.getDuration(), obj.getNumFrames()+1);
            for axNum = axNums
                frameSelectionHandles = highlight_plot(obj.NavigationAxes(axNum), highlight_x, obj.FrameSelection, obj.FrameSelectionColor);
                obj.FrameSelectionHandles = [obj.FrameSelectionHandles, frameSelectionHandles];
            end
        end
        function set.VideoFrameRate(obj, frameRate)
            obj.VideoFrameRate = frameRate;
        end
        function set.FrameSelection(obj, newSelection)
            % Setter for Selection property

            obj.FrameSelection = newSelection;
            obj.updateFrameSelection(1:obj.getNumNavigationAxes());
        end
        function updateNumColorChannels(obj)
            % Get updated # of color channels based on video data shape
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
            % Process whatever user has passed in for video data

            if istext(newVideoData)
                % User has provided a filepath instead of the actual video
                % data - load it.
                obj.VideoPath = newVideoData;
                if obj.Async
                    obj.AsyncVideoReader = VideoReaderAsync(obj.VideoPath, 'StoreData', false, 'FramesReceivedCallback', @obj.updateAsyncVideoData);
                    obj.VideoFrameRate = obj.AsyncVideoReader.FrameRate;
                    % Initialize video data
                    finalVideoShape = [...
                        obj.AsyncVideoReader.Width, ...
                        obj.AsyncVideoReader.Height, ...
                        obj.AsyncVideoReader.NumChannels, ...
                        obj.AsyncVideoReader.NumFrames];
                    newVideoData = zeros(finalVideoShape, 'uint8');
                    obj.updateNumColorChannels();
                else
                    makeGrayscale = false;
                    newVideoData = loadVideoData(obj.VideoPath, makeGrayscale);
                    videoInfo = getVideoInfo(obj.VideoPath);
                    obj.VideoFrameRate = videoInfo.frameRate;
                end
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
        function updateAsyncVideoData(obj, ~, evt)
            obj.VideoData(:, :, :, evt.FrameStart:evt.FrameEnd) = evt.Frames;
        end
        function loadNewVideoData(obj, newVideoData)
            obj.VideoData = obj.prepareNewVideoData(newVideoData);
            obj.updateNumColorChannels();
            obj.setCurrentFrameNum(1);
            obj.drawNavigationData();
        end
%         function set.VideoData(obj, newVideoData)
%             % Setter for the VideoData property
% 
%             if obj.Async %#ok<MCSUP> 
%                 obj.VideoData = newVideoData;
%             else
%                 obj.VideoData = obj.prepareNewVideoData(newVideoData);
%                 obj.updateNumColorChannels();
%                 obj.setCurrentFrameNum(1);
%             end
%             obj.drawNavigationData();
%         end
%         function videoData = get.VideoData(obj)
%             if obj.Async
%                 % We loaded the video data asynchronously
%                 videoData = obj.AsyncVideoReader.VideoData;
%             else
%                 videoData = obj.VideoData;
%             end
%         end
        function set.NavigationDataFunction(obj, newNavigationDataFunction)
            % Setter for the NavigationDataFunction property
            
            obj.NavigationDataFunction = newNavigationDataFunction;
            obj.drawNavigationData();
            obj.updateNavigationAxesContextMenu(1:obj.getNumNavigationAxes());
        end
        function UpdateNavigationAxes(obj)
            % Make sure # of axes corresponds to number of navigation data
            % series

            delete(obj.NavigationAxes);
            numAxes = obj.getNumNavigationAxes();
            obj.NavigationAxes = matlab.graphics.axis.Axes.empty(0, numAxes);
            for axNum = 1:numAxes
                obj.NavigationAxes(axNum) =    axes(obj.NavigationPanel, 'Units', 'normalized', 'HitTest', 'on', 'PickableParts', 'all');
            end
            if ~isempty(obj.NavigationAxes)
                % Link x-axis of navigation axes
                linkaxes(obj.NavigationAxes, 'x');
                for axNum = 1:numAxes
                    obj.NavigationAxes(axNum).Toolbar.Visible = 'off';
                    obj.NavigationAxes(axNum).YTickMode = 'manual';
                    obj.NavigationAxes(axNum).YTickLabelMode = 'manual';
                    obj.NavigationAxes(axNum).YTickLabel = [];
                    obj.NavigationAxes(axNum).YTick = [];
                    axis(obj.NavigationAxes(axNum), 'off');
                end
            end

            obj.updateNavigationAxesContextMenu();
        end
        function set.NavigationData(obj, newNavigationData)
            % Setter for the NavigationData property

            if ~iscell(newNavigationData)
                newNavigationData = {newNavigationData};
            end
            obj.NavigationData = newNavigationData;

%           obj.drawNavigationData();
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
            drawnow;
        end
        function set.FrameMarkerColor(obj, newColor)
            % Setter for the FrameMarkerColor property

            obj.FrameMarkerColor = newColor;
            obj.updateFrameMarker(true);
        end
        function selectedOnly = IsPlayingSelectedOnly(obj)
            % Setter for IsPlayingSelectedOnly property
            selectedOnly = obj.AVPlayer.UserData.selectedOnly;
        end
        function set.PlaybackSpeed(obj, fps)
            % Setter for PlaybackSpeed property
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
            % Setter for Colormap property
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
            obj.clearNavigationData(1:obj.getNumNavigationAxes());
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
            %   borders of the VideoAxes or not
            if y < obj.VideoAxes.Position(2)
                inside = false;
            elseif y > obj.VideoAxes.Position(2) + obj.VideoAxes.Position(4)
                inside = false;
            elseif x < obj.VideoAxes.Position(1)
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
            %   borders of one or more of the NavigationAxes. If so, the
            %   index of the NavigationAxes it falls inside will be
            %   returned, otherwise false.
            positions = zeros(obj.getNumNavigationAxes(), 4);
            for k = 1:length(obj.getNumNavigationAxes())
                positions(k, :) = getWidgetFigurePosition(obj.NavigationAxes(k), obj.MainFigure.Units);
            end

            tooLow = y < positions(:, 2);
            if all(tooLow)
                inside = false;
                return;
            end

            tooHigh = y > (positions(:, 2) + positions(:, 4));
            if all(tooHigh)
                inside = false;
                return;
            end

            tooLeft = x < positions(:, 1);
            if all(tooLeft)
                inside = false;
                return;
            end

            tooRight = x > positions(:, 1) + positions(:, 3);
            if all(tooRight)
                inside = false;
                return;
            end

            inside = find(~(tooLow | tooHigh | tooLeft | tooRight), 1);
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
            frameNum = 1 + round(obj.VideoFrameRate * ((x - obj.NavigationPanel.Position(1)) * diff(obj.NavigationAxes(1).XLim) / obj.NavigationPanel.Position(3) + obj.NavigationAxes(1).XLim(1)));
        end
        function x = mapFrameNumToFigureX(obj, frameNum)
            % Convert a frame number to a figure x coordinate based on the
            %   NavigationAxes position.
            x = ((frameNum-1)/obj.VideoFrameRate) * (obj.NavigationAxes(1).Position(3) / diff(obj.NavigationAxes(1).XLim)) - obj.NavigationAxes(1).XLim(1) + obj.NavigationAxes(1).Position(1);
        end
        function x = mapFrameNumToAxesX(obj, frameNum)
            % Convert a frame number to a axes x coordinate
            x = obj.getDuration()*((frameNum-1)/obj.getNumFrames());
        end
        function cancelZoom(obj)
            % Cancel a video axes zoom in progress
            obj.IsZooming = false;
            obj.ZoomStart = [];
            delete(obj.ZoomBox);
        end
        function NavigationClickHandler(~, ~, ~)
            % Handle a click on the navigation axes
        end
        function VideoClickHandler(obj, ~, ~)
            % Handle a click on the video axes
            [x, y] = obj.getCurrentVideoPoint();
            switch obj.MainFigure.SelectionType
                case {'open'}
                    % Double click
                    obj.ZoomVideoAxes();
                    obj.cancelZoom();
                case 'alt'
                    % Right click
                    if ~obj.IsZooming
                        % Start zoom
                        obj.ZoomStart = [x, y];
                        obj.ZoomBox = rectangle(obj.VideoAxes, 'Position', [x, x, 0, 0], 'EdgeColor', 'r');
                        obj.ZoomBox.HitTest = 'off';
                        obj.IsZooming = true;
                    else
                        % End zoom
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
                    currentTLim = xlim(obj.NavigationAxes(1));
                    shiftFraction = 0.1;
                    shiftAmount = diff(currentTLim) * shiftFraction * scrollCount;
                    newTLim = currentTLim + shiftAmount;
                    xlim(obj.NavigationAxes(1), newTLim);
                    
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
            obj.updateFrameMarker();
        end
        function delete(obj)
            if isvalid(obj.AVPlayer)
                stop(obj.AVPlayer);
            end
            delete(obj.AVPlayer);
            obj.deleteDisplayArea();
        end
    end
    methods (Static)
        function arg = matchCellArg(arg, numCells)
            % If arg is not a cell array, wrap it in a cell array.
            % If the size of arg as a cell array is not the same as
            % numCells, make it so.
            if ~iscell(arg)
                % Wrap in cell
                arg = {arg};
            end
            if length(arg) < numCells
                % Extend to match numCells
                arg = [arg, repmat(arg(end), 1, numCells-length(arg))];
            end
        end
    end
end