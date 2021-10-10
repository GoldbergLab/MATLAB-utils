classdef VideoPlotter < handle
    properties
        video = []
        maskedVideo = []
        overlayMasks = {}
        overlayAlphas = {}
        areMasksStatic = []
        overlayOrigins = {}
        xValues = {}
        yValues = {}
        plotProperties = {}
        plotHistoryModes = {}
        numFrames = []
        videoWidth = []
        videoHeight = []
        figureCanvas = matlab.ui.Figure.empty()
        canvas = matlab.graphics.axis.Axes.empty()
        overlayTexts = {}
        overlayTextXs = {}
        overlayTextYs = {}
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
            alpha3 = alpha * mask;
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
        end
        function generateMaskedVideo(obj)
            obj.maskedVideo = obj.video;
            for k = 1:length(obj.overlayMasks)
                x = obj.overlayOrigins{k}(1);
                y = obj.overlayOrigins{k}(2);
                w = size(obj.overlayMasks{k}, 2);
                h = size(obj.overlayMasks{k}, 1);
                inverseAlphas = (1-obj.overlayAlphas{k});
                alphaSize = size(inverseAlphas);
                inverseAlphas = reshape(inverseAlphas, [alphaSize(1:2), 1, alphaSize(3)]);
                subFrame = double(obj.maskedVideo(y:y+h-1, x:x+w-1, :, :));
                subFrameAlpha = cat(3, uint8(inverseAlphas.*subFrame(:, :, 1, :)), ...
                                       uint8(inverseAlphas.*subFrame(:, :, 2, :)), ...
                                       uint8(inverseAlphas.*subFrame(:, :, 3, :)));
                obj.maskedVideo(y:y+h-1, x:x+w-1, :, :) = obj.overlayMasks{k} + subFrameAlpha;
            end
        end
        function addPlot(obj, xValues, yValues, historyMode, varargin)
            % xValues = a vector of x-values, one per video frame (except
            %   for static plots, which may have any number of values)
            % yValues = a vector of y-values, one per video frame (except
            %   for static plots, which may have any number of values)
            % historyMode = how previous values should be dealt with,
            % expressed as a double from 0 to 1.
            %   0: no previous values will be plotted
            %   0-1: fraction of total frames before which values will disappear
            %   1: all previous values will be plotted
            %   NaN: static plot - all values plotted on every frame
            % varargin = zero or more arguments of the form that the
            %   standard 'plot' function would accept.
            if ~isnan(historyMode) && (length(xValues) ~= obj.numFrames)
                error('Number of x-values in vector (%d) does not match the number of frames in the video (%d)', length(xValues, obj.numFrames));
            end
            if ~isnan(historyMode) && (length(xValues) ~= obj.numFrames)
                error('Number of x-values in vector (%d) does not match the number of frames in the video (%d)', length(xValues, obj.numFrames));
            end
            if length(xValues) ~= length(yValues)
                error('Number of x and y values must be equal.');
            end
            if ~isnumeric(historyMode) || historyMode < 0 || historyMode > 1
                error('History mode must be a double between 0 and 1, inclusive');
            end
            obj.xValues = [obj.xValues, xValues];
            obj.yValues = [obj.yValues, yValues];
            obj.plotProperties = [obj.plotProperties, {varargin}];
            obj.plotHistoryModes = [obj.plotHistoryModes, historyMode];
        end
        function removePlot(obj, idx)
            if idx > length(obj.xValues)
                error('Plot index %d is out of range - there are %d plots.', idx, length(obj.xValues));
            end
            obj.xValues(idx) = [];
            obj.yValues(idx) = [];
            obj.plotProperties(idx) = [];
            obj.plotHistoryModes(idx) = [];
        end
        function addText(obj, txts, xCoords, yCoords, varargin)
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
                    txts = repmat({txts}, 1, obj.numFrames);
                case 'cell'
                    % User has passed in a cell array, hopefully with one
                    % string per frame
                    if length(txts) ~= obj.numFrames
                        error('If txts argument is a cell array, it must have the same length as the number of frames in the video.');
                    end
                    if ~all(cellfun(@ischar, txts))
                        error('If txts argument is a cell array, it must be a cell array of char arrays, one per video frame.');
                    end
                otherwise
                    error('txts argument must be either a char array, or a cell array of char arrays, one per video frame.');
            end
            switch length(xCoords)
                case 1
                    % User has passed in a single x coordinate - repeat it
                    % for each frame
                    xCoords = repmat(xCoords, 1, obj.numFrames);
                case obj.numFrames
                    % User has passed in one x coordinate for each frame
                otherwise
                    error('xCoords argument must either be a scalar, or a 1D vector of x coordinates, one per video frame.');
            end
            switch length(yCoords)
                case 1
                    % User has passed in a single y coordinate - repeat it
                    % for each frame
                    yCoords = repmat(yCoords, 1, obj.numFrames);
                case obj.numFrames
                    % User has passed in one y coordinate for each frame
                otherwise
                    error('yCoords argument must either be a scalar, or a 1D vector of x coordinates, one per video frame.');
            end
            obj.overlayTexts = [obj.overlayTexts, {txts}];
            obj.overlayTextXs = [obj.overlayTextXs, xCoords];
            obj.overlayTextYs = [obj.overlayTextYs, yCoords];
            obj.overlayTextProperties = [obj.overlayTextProperties, {varargin}];
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
%             obj.canvas.XLimMode = 'manual';
%             obj.canvas.YLimMode = 'manual';
%            obj.freezeCanvas();
%             for k = 1:length(obj.overlayMasks)
%                 obj.applyMask(obj.overlayMasks{k}(:, :, :, frameNum), obj.overlayAlphas{k}(:, :, frameNum), obj.overlayOrigins{k});
%             end
            for k = 1:length(obj.xValues)
                obj.applyPlot(frameNum, obj.xValues{k}, obj.yValues{k}, obj.plotHistoryModes{k}, obj.plotProperties{k});
            end
            for k = 1:length(obj.overlayTexts)
                obj.applyText(obj.overlayTexts{k}{frameNum}, ...
                    obj.overlayTextXs{k}(frameNum), ...
                    obj.overlayTextYs{k}(frameNum), ...
                    obj.overlayTextProperties{k});
            end
            frame = getframe(obj.canvas);
            frame = uint8(frame.cdata);
%            delete(obj.canvas);
%            delete(obj.figureCanvas);
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
                fprintf('Creating frame %d of %d...\n', frameNum-startFrame+1, endFrame-startFrame+1);
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
        function applyPlot(obj, frameNum, xValues, yValues, historyMode, plotProperties)
            obj.ensureCanvas();
            if isnan(historyMode)
                % Static plot - plot all values on every frame
                first = 1;
                last = length(xValues);
            else
                % Non-static plot - plot all or some values up to current
                % frame
                first = max(1, round(frameNum - historyMode*obj.numFrames));
                last = frameNum;
            end
            xValueHistory = xValues(first:last);
            yValueHistory = yValues(first:last);
            plot(obj.canvas, xValueHistory, yValueHistory, plotProperties{:});
        end
        function applyText(obj, txt, x, y, textProperties)
            obj.ensureCanvas();
            text(obj.canvas, x, y, txt, textProperties{:});
        end
%         function applyMask(obj, mask, alpha, origin)
%             obj.ensureCanvas();
%             x = [origin(1), origin(1) + size(mask, 2) - 1];
%             y = [origin(2), origin(2) + size(mask, 1) - 1];
%             im = image(x, y, mask, 'Parent', obj.canvas);
%             set(im, 'AlphaData', alpha);
%         end
    end
end