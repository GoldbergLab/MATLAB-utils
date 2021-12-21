classdef VideoPlotter < handle
    % VideoPlotter A class for quickly and flexibly adding various types of
    %   overlays on a video.
    properties
        video = []
        maskedVideo = []
        overlayMasks = {}
        overlayAlphas = {}
        areMasksStatic = []
        overlayOrigins = {}
        plotXs = {}
        plotYs = {}
        plotProperties = {}
        plotHistoryModes = {}
        plotStartFrames = []
        staticPlotXs = {}
        staticPlotYs = {}
        staticPlotProperties = {}
        staticPlotStartFrames = []
        staticPlotEndFrames = []
        numFrames = []
        videoWidth = []
        videoHeight = []
        figureCanvas = matlab.ui.Figure.empty()
        canvas = matlab.graphics.axis.Axes.empty()
        overlayTexts = {}
        overlayTextXs = {}
        overlayTextYs = {}
        overlayTextStartFrames = []
        overlayTextProperties = {}
    end
    methods
        function obj = VideoPlotter(videoData)
            % Create a VideoPlotter object
            %   videoData - either a char array representing a path to a
            %       video file, or a HxWxN or HxWxCxN array of video data
            obj.video = obj.sanitizeVideo(videoData);
            obj.numFrames = size(obj.video, 4);
            obj.videoWidth = size(obj.video, 2);
            obj.videoHeight = size(obj.video, 1);
            fprintf('Loaded %dx%d video with %d frames.\n', obj.videoWidth, obj.videoHeight, obj.numFrames);
        end
        function videoData = sanitizeVideo(obj, videoData)
            switch class(videoData)
                case 'char'
                    % Must be a filename - load it, then sanitize it
                    videoData = obj.sanitizeVideo(loadVideoData(videoData));
                case 'double'
                    videoDataFlat = videoData(:);
                    if max(videoDataFlat) > 1 || min(videoDataFlat) < 0
                        error('If videoData is a double array, it must only have values between 0 and 1.');
                    else
                        videoData = squeeze(uint8(videoData * 255));
                    end
                case 'uint8'
                    videoData = squeeze(videoData);
                otherwise
                    error('Video must either be a double array with values between 0 and 1, or a uint8 array.');
            end
            switch length(size(videoData))
                case 4
                    % Video is RGB
                case 3
                    % Video is greyscale, convert to RGB
                    videoData = cat(4, videoData, videoData, videoData);
                    videoData = permute(videoData, [1, 2, 4, 3]);
                otherwise
                    error('Video must be a 3D (HxWxN) or 4D (HxWxCxN) array.');
            end
        end
        function removeOverlay(obj, idx)
            if idx > length(obj.overlayMasks)
                error('There are only %d overlays - cannot remove #%d', length(obj.overlayMasks), idx);
            end
            obj.overlayMasks(idx) = [];
            obj.overlayAlphas(idx) = [];
            obj.areMasksStatic(idx) = [];
            obj.overlayOrigins(idx) = [];
            % Need to update masked video, so for now, delete it:
            obj.maskedVideo = [];
        end
        function addOverlay(obj, mask, rgb, alpha, origin)
            if ~islogical(mask)
                error('Mask overlay must be a logical array');
            end
            if ~exist('origin', 'var')
                origin = [1, 1];
            end
            if ~isnumeric(origin) || length(origin) ~= 2
                error('If origin is supplied, it must be a 1x2 numeric vector representing the coordinates of the upper left hand corner of the mask overlay in the base video coordinates.');
            end
            switch length(size(mask))
                case 2
                    % 2D array, must be a static mask
                    obj.areMasksStatic(end+1) = true;
                case 3
                    % 3D array, must be a mask stack
                    obj.areMasksStatic(end+1) = false;
                otherwise
                    error('Mask stack must be a 3D array of the form HxWxN');
            end
            if ~obj.areMasksStatic(end) && size(mask, 3) ~= obj.numFrames
                fprintf('Warning, mask stack size does not match the number of frames in video.\n');
            end
            if ~isnumeric(rgb) || length(rgb) ~= 3 || sqrt(dot(rgb, rgb)) > 1
                error('RGB color for mask overlay must be a 1x3 vector of double values between 0 and 1 representing red, green, and blue values for overlay mask.');
            end
            if ~isnumeric(alpha) || alpha < 0 || alpha > 1
                error('Alpha value must be a double between 0 and 1')
            end
            % Create transparency mask
            alpha3 = alpha * mask;
            % Premultiply alpha and color
            if obj.areMasksStatic(end)
                mask3 = uint8(cat(3, mask*(alpha*255*rgb(1)), ...
                                    mask*(alpha*255*rgb(2)), ...
                                    mask*(alpha*255*rgb(3))));
            else
                mask3 = uint8(cat(4, mask*(alpha*255*rgb(1)), ...
                                    mask*(alpha*255*rgb(2)), ...
                                    mask*(alpha*255*rgb(3))));
                mask3 = permute(mask3, [1, 2, 4, 3]);
            end
            obj.overlayMasks = [obj.overlayMasks, mask3];
            obj.overlayAlphas = [obj.overlayAlphas, alpha3];
            obj.overlayOrigins = [obj.overlayOrigins, origin];
            % Need to update masked video, so for now, delete it:
            obj.maskedVideo = [];
        end
        function generateMaskedVideo(obj)
            obj.maskedVideo = obj.video;
            for k = 1:length(obj.overlayMasks)
                % Requested mask origin and width
                x = obj.overlayOrigins{k}(1);
                y = obj.overlayOrigins{k}(2);
                w = size(obj.overlayMasks{k}, 2);
                h = size(obj.overlayMasks{k}, 1);
                % Trim mask so it fits into the frame
                x0 = max(1, 1 - x + 1);
                y0 = max(1, 1 - y + 1);
                x1 = min(w, obj.videoWidth  - x + 1);
                y1 = min(h, obj.videoHeight - y + 1);
                overlayMask = obj.overlayMasks{k}(y0:y1, x0:x1, :, :);
                overlayAlpha = obj.overlayAlphas{k}(y0:y1, x0:x1, :);
                % Get trimmed video to match mask
                X0 = max(1, x);
                Y0 = max(1, y);
                X1 = min(obj.videoWidth,  x+w-1);
                Y1 = min(obj.videoHeight, y+h-1);
                subFrame = double(obj.maskedVideo(Y0:Y1, X0:X1, :, :));
                % Compute composite image of frame = mask
                inverseAlphas = (1-overlayAlpha);
                alphaSize = size(inverseAlphas);
                inverseAlphas = reshape(inverseAlphas, [alphaSize(1:2), 1, alphaSize(3)]);
                subFrameAlpha = cat(3, uint8(inverseAlphas.*subFrame(:, :, 1, :)), ...
                                       uint8(inverseAlphas.*subFrame(:, :, 2, :)), ...
                                       uint8(inverseAlphas.*subFrame(:, :, 3, :)));
                obj.maskedVideo(Y0:Y1, X0:X1, :, :) = overlayMask + subFrameAlpha;
            end
        end
        function addPlot(obj, Xs, Ys, startFrame, historyMode, varargin)
            % Xs = a vector of x-values, one per video frame (except
            %   for static plots, which may have any number of values)
            % Ys = a vector of y-values, one per video frame (except
            %   for static plots, which may have any number of values)
            % startFrame = the frame of the video in which to start plotting
            % historyMode = how previous values should be dealt with,
            % expressed as a double from 0 to 1.
            %   0: no previous values will be plotted
            %   0-1: fraction of total frames before which values will disappear
            %   1: all previous values will be plotted
            %   NaN: static plot - all values plotted on every frame
            % varargin = zero or more arguments of the form that the
            %   standard 'plot' function would accept.
            if length(Xs) ~= length(Ys)
                error('Number of x and y values must be equal.');
            end
            if ~isnumeric(historyMode) || historyMode < 0 || historyMode > 1
                error('History mode must be a double between 0 and 1, inclusive');
            end
            if startFrame > obj.numFrames
                warning('Static plot start frame is after the end of the video - nothing will display.');
            end
            obj.plotXs = [obj.plotXs, Xs];
            obj.plotYs = [obj.plotYs, Ys];
            obj.plotProperties = [obj.plotProperties, {varargin}];
            obj.plotHistoryModes = [obj.plotHistoryModes, historyMode];
            obj.plotStartFrames = [obj.plotStartFrames, startFrame];
        end
        function removePlot(obj, idx)
            if idx > length(obj.plotXs)
                error('Plot index %d is out of range - there are %d plots.', idx, length(obj.plotXs));
            end
            obj.plotXs(idx) = [];
            obj.plotYs(idx) = [];
            obj.plotProperties(idx) = [];
            obj.plotHistoryModes(idx) = [];
            obj.plotStartFrames(idx) = [];
        end
        function addStaticPlot(obj, Xs, Ys, startFrame, endFrame, varargin)
            % Xs = a vector of x-values to plot
            % Ys = a vector of y-values to plot
            % startFrame = the first frame of the video in which to start
            %   plotting
            % endFrame = the last frame of the video in which to plot. If
            %   this is nan or an empty matrix, the plot will last until
            %   the end of the video.
            % varargin = zero or more arguments of the form that the
            %   standard 'plot' function would accept.
            if length(Xs) ~= length(Ys)
                error('Number of x and y values must be equal.');
            end
            if startFrame > obj.numFrames
                warning('Static plot start frame is after the end of the video - nothing will display.');
            end
            if endFrame < 1
                warning('Static plot end frame is before the beginning of the video - nothing will display.');
            end
            if isempty(endFrame)
                endFrame = nan;
            end
            obj.staticPlotXs = [obj.staticPlotXs, Xs];
            obj.staticPlotYs = [obj.staticPlotYs, Ys];
            obj.staticPlotProperties = [obj.staticPlotProperties, {varargin}];
            obj.staticPlotStartFrames = [obj.staticPlotStartFrames, startFrame];
            obj.staticPlotEndFrames = [obj.staticPlotEndFrames, endFrame];
        end
        function removeStaticPlot(obj, idx)
            if idx > length(obj.staticPlotXs)
                error('static plot index %d is out of range - there are %d static plots.', idx, length(obj.staticPlotXs));
            end
            obj.staticPlotXs(idx) = [];
            obj.staticPlotYs(idx) = [];
            obj.staticPlotStartFrames(idx) = [];
            obj.staticPlotEndFrames(idx) = [];
            obj.staticPlotProperties(idx) = [];
        end
        function addText(obj, txts, xCoords, yCoords, startFrame, varargin)
            % VideoPlotter.addText(txts, xCoords, yCoords)
            %   txts: A cell array of char arrays to overlay on the video,
            %       one per video frame
            %           or
            %       A char array to print on the video, the same text for
            %       each frame
            %   xCoords: An array of x coordinates, one per video frame,
            %       indicating where to place the text in each frame along
            %       the x-axis
            %           or
            %       A single x coordinate, indicating where to put the text
            %       in every frame.
            %   yCoords: See xCoords
            % VideoPlotter.addText(_______, Name, Value)
            %   Add object properties as name-value pairs, indicating how 
            %       to format the text, using the same properties as in the
            %       MATLAB text function.
            switch class(txts)
                case 'char'
                    % User has passed in a single char array - let's duplicate
                    % it for each frame
                    txts = repmat({txts}, 1, obj.numFrames - startFrame + 1);
                case 'cell'
                    % User has passed in a cell array, hopefully with one
                    % string per frame
                    if ~all(cellfun(@ischar, txts))
                        error('If txts argument is a cell array, it must be a cell array of char arrays.');
                    end
                otherwise
                    error('txts argument must be either a char array, or a cell array of char arrays, one per video frame.');
            end
            if ~isnumeric(startFrame) || length(startFrame) ~= 1
                error('startFrame should be a scalar integer.');
            end
            switch length(xCoords)
                case 1
                    % User has passed in a single x coordinate - repeat it
                    % for each frame
                    xCoords = repmat(xCoords, 1, obj.numFrames - startFrame + 1);
                case obj.numFrames - startFrame + 1
                    % User has passed in one x coordinate for each frame
                otherwise
                    error('xCoords argument must either be a scalar, or a 1D vector of x coordinates, one per video frame.');
            end
            switch length(yCoords)
                case 1
                    % User has passed in a single y coordinate - repeat it
                    % for each frame
                    yCoords = repmat(yCoords, 1, obj.numFrames - startFrame + 1);
                case obj.numFrames - startFrame + 1
                    % User has passed in one y coordinate for each frame
                otherwise
                    error('yCoords argument must either be a scalar, or a 1D vector of x coordinates, one per video frame.');
            end
            obj.overlayTexts = [obj.overlayTexts, {txts}];
            obj.overlayTextXs = [obj.overlayTextXs, xCoords];
            obj.overlayTextYs = [obj.overlayTextYs, yCoords];
            obj.overlayTextStartFrames = [obj.overlayTextStartFrames, startFrame];
            obj.overlayTextProperties = [obj.overlayTextProperties, {varargin}];
        end
        function removeText(obj, idx)
            if idx > length(obj.overlayTexts)
                error('Text overlay index %d is out of range - there are %d text overlays.', idx, length(obj.plotXs));
            end
            obj.overlayTexts(idx) = [];
            obj.overlayTextXs(idx) = [];
            obj.overlayTextYs(idx) = [];
            obj.overlayTextStartFrames(idx) = [];
            obj.overlayTextProperties(idx) = [];
        end
        function frame = getMaskedFrame(obj, frameNum)
            if isempty(obj.maskedVideo)
                obj.generateMaskedVideo();
            end
            % Get a single color frame of the video as a 3D array
            frame = obj.maskedVideo(:, :, :, frameNum);
        end
        function frame = getVideoFrame(obj, frameNum)
            % Get a single color frame of the video as a 3D array
            frame = obj.video(:, :, :, frameNum);
        end
        function deleteCanvas(obj)
            if isvalid(obj.figureCanvas)
                if isvalid(obj.canvas)
                    close(obj.canvas);
                end
                close(obj.figureCanvas);
            end
        end
        function ensureCanvas(obj)
            if isempty(obj.figureCanvas) || ~isvalid(obj.figureCanvas)
                obj.figureCanvas = figure('Visible', false);
            end
            if isempty(obj.canvas) || ~isvalid(obj.canvas)
                obj.canvas = axes(obj.figureCanvas);
            end
        end
        function prepareCanvas(obj)
            hold(obj.canvas, 'on');
            obj.figureCanvas.Units = 'pixels';
            obj.canvas.Units = 'pixels';
            obj.figureCanvas.Position = [1, 1, obj.videoWidth*2, obj.videoHeight*2];
            obj.canvas.Position = [1, 1, obj.videoWidth, obj.videoHeight];
            obj.canvas.XLim = [1, obj.videoWidth];
            obj.canvas.YLim = [1, obj.videoHeight];
            obj.canvas.XTick = [];
            obj.canvas.YTick = [];
            obj.canvas.YDir = 'reverse';
        end
        function freezeCanvas(obj)
            if isprop(obj.canvas, 'PositionConstraint')
                obj.canvas.PositionConstraint = 'innerposition';
            elseif isprop(obj.canvas, 'ActivePositionProperty')
                obj.canvas.ActivePositionProperty = 'position';
            else
                error('Could not freeze canvas - perhaps MATLAB version is too old?');
            end
        end
        function unfreezeCanvas(obj)
            if isprop(obj.canvas, 'PositionConstraint')
                obj.canvas.PositionConstraint = 'outerposition';
            elseif isprop(obj.canvas, 'ActivePositionProperty')
                obj.canvas.ActivePositionProperty = 'outerposition';
            else
                error('Could not freeze canvas - perhaps MATLAB version is too old?');
            end
        end
        function frame = getFrame(obj, frameNum)
            obj.ensureCanvas();
            obj.prepareCanvas();
            obj.clearCanvas();
            hold(obj.canvas, 'on');
            obj.showFrame(obj.getMaskedFrame(frameNum));
            for k = 1:length(obj.staticPlotXs)
                % Apply each static plot to the canvas
                obj.applyStaticPlot(frameNum, obj.staticPlotXs{k}, obj.staticPlotYs{k}, obj.staticPlotStartFrames(k), obj.staticPlotEndFrames(k), obj.staticPlotProperties{k});
            end
            for k = 1:length(obj.plotXs)
                % Apply each dynamic plot to the canvas
                obj.applyPlot(frameNum, obj.plotXs{k}, obj.plotYs{k}, obj.plotStartFrames(k), obj.plotHistoryModes{k}, obj.plotProperties{k});
            end
            for k = 1:length(obj.overlayTexts)
                % Apply each text overlay to the canvas
                obj.applyText(frameNum, obj.overlayTexts{k}, ...
                    obj.overlayTextXs{k}, ...
                    obj.overlayTextYs{k}, ...
                    obj.overlayTextStartFrames(k), ...
                    obj.overlayTextProperties{k});
            end
            frame = getframe(obj.canvas);
            frame = uint8(frame.cdata);
        end
        function video = getVideoPlot(obj, startFrame, endFrame)
            if ~exist('startFrame', 'var') || isempty(startFrame)
                startFrame = 1;
            end
            if ~exist('endFrame', 'var') || isempty(endFrame)
                endFrame = obj.numFrames;
            end
            numFramesRequested = endFrame - startFrame + 1;
            video = uint8.empty();
            for frameNum = startFrame:endFrame
                frameIdx = frameNum - startFrame + 1;
                displayProgress('Creating frame %d of %d...\n', frameNum-startFrame+1, endFrame-startFrame+1, 10);
                if isempty(video)
                    frame = obj.getFrame(frameNum);
                    video = zeros([size(frame), numFramesRequested], 'uint8');
                end
                video(:, :, :, frameIdx) = obj.getFrame(frameNum);
            end
        end
        function clearCanvas(obj)
            if ~isempty(obj.canvas)
                cla(obj.canvas);
            end
        end
        function showFrame(obj, frame)
            image(frame, 'Parent', obj.canvas);
%             p = obj.canvas.InnerPosition;
%             obj.canvas.InnerPosition = [p(1), p(2), p(1) + obj.videoWidth, p(2) + obj.videoHeight];
        end
        function applyPlot(obj, frameNum, Xs, Ys, startFrame, historyMode, plotProperties)
            if frameNum < startFrame
                return;
            end
            idx = frameNum - startFrame + 1;
            if idx > length(Xs)
                return;
            end
            obj.ensureCanvas();
            first = max(1, round(idx - historyMode * length(Xs)));
            last = idx;
            xValueHistory = Xs(first:last);
            yValueHistory = Ys(first:last);
            plot(obj.canvas, xValueHistory, yValueHistory, plotProperties{:});
        end
        function applyStaticPlot(obj, frameNum, Xs, Ys, startFrame, endFrame, plotProperties)
            if frameNum < startFrame || frameNum > endFrame
                return;
            end
            obj.ensureCanvas();
            plot(obj.canvas, Xs, Ys, plotProperties{:});
        end
        function applyText(obj, frameNum, txts, Xs, Ys, startFrame, textProperties)
            if frameNum < startFrame
                return;
            end
            idx = frameNum - startFrame + 1;
            if idx > length(txts)
                return;
            end
            obj.ensureCanvas();
            text(obj.canvas, Xs(idx), Ys(idx), txts{idx}, textProperties{:});
        end
    end
end