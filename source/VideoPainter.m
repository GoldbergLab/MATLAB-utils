classdef VideoPainter < VideoBrowser
    properties (Access = private)
        IsPainting          logical = false                      % Is user currently holding mouse button down on video axes?
        IsErasing           logical = false                      % Is GUI currently in erase mode?
        Stack               StateStack                           % Undo/redo stack
    end
    properties
        PaintMaskImage      matlab.graphics.primitive.Image      % Image handle to paint mask
        PaintMaskColor      double = [1, 0, 0]                   % Color of paint mask
        PaintBrush          struct                               % Brush
        PaintBrushMarker    matlab.graphics.primitive.Rectangle  % Brush marker
        PaintMask           logical = logical.empty()            % Painted mask stack
        PaintEnabled        logical = true;                      % Enable painting with mouse?
    end
    properties (SetObservable)
    end
    methods
        function obj = VideoPainter(varargin)
            obj@VideoBrowser(varargin{:});
            obj.Stack = StateStack(100);
            obj.SaveState();
        end
        function createDisplayArea(obj)
            createDisplayArea@VideoBrowser(obj);
            obj.MainFigure.Name = 'Video Painter';
            obj.MainFigure.WindowScrollWheelFcn = @obj.ScrollWheelHandler;
        end
        function updateVideoFrame(obj, paintOnly)
            if ~exist('paintOnly', 'var') || ~paintOnly
                % If we're not just updating the paint, update everything
                updateVideoFrame@VideoBrowser(obj);
            end
            if isempty(obj.PaintMask)
                obj.PaintMask = false(size(obj.VideoData, [1, 2, 3]));
            end
            if isempty(obj.PaintMaskImage) || ~isvalid(obj.PaintMaskImage)
                % Initialize mask overlay (first call only)
                [~, h, w] = size(obj.PaintMask);
                paintData = repmat(permute(obj.PaintMaskColor, [3, 1, 2]), h, w, 1);
                hold(obj.VideoAxes, 'on');
                obj.PaintMaskImage = imshow(paintData, 'Parent', obj.VideoAxes);
                obj.PaintMaskImage.HitTest = 'off';
                obj.PaintMaskImage.PickableParts = 'none';
                obj.VideoAxes.HitTest = 'on';
                obj.VideoAxes.PickableParts = 'all';
            end
            % Update alpha data to make mask region overlay visible
            obj.PaintMaskImage.AlphaData = squeeze(obj.PaintMask(obj.CurrentFrameNum, :, :)*0.4);
        end
        function updatePaintBrushParams(obj)
            if ~isfield(obj.PaintBrush, 'BrushRadius')
                obj.PaintBrush(1).BrushRadius = 8;
            end
            obj.PaintBrush.Brush = createCircleMask(obj.PaintBrush.BrushRadius);
            obj.PaintBrush.ActualBrushRadius = (size(obj.PaintBrush.Brush, 1) - 1) / 2;
            if obj.IsErasing
                obj.PaintBrush.EdgeColor = [0, 0, 1];
            else
                obj.PaintBrush.EdgeColor = [0, 1, 0];
            end
            obj.PaintBrush.xMin = obj.PaintBrush.BrushRadius+1;
            obj.PaintBrush.yMin = obj.PaintBrush.BrushRadius+1;
            obj.PaintBrush.xMax = size(obj.PaintMask, 3) - obj.PaintBrush.BrushRadius;
            obj.PaintBrush.yMax = size(obj.PaintMask, 2) - obj.PaintBrush.BrushRadius;
        end
        function updatePaintBrush(obj, x, y)
            % Create/update brush marker (a circle constructed from a
            % rectangle with curved corners *eyeroll*)
            if isempty(obj.PaintBrush)
                obj.updatePaintBrushParams();
            end
            r = obj.PaintBrush.BrushRadius;
            x1 = x - r - 0.5;
            w = 2 * r + 1;
            y1 = y - r - 0.5;
            h = 2 * r + 1;
            if obj.PaintEnabled
                if isempty(obj.PaintBrushMarker)
                    obj.PaintBrushMarker = rectangle('Position', [x1, y1, w, h], 'Curvature',[1,1], 'EdgeColor', obj.PaintBrush.EdgeColor, 'HitTest', 'off', 'PickableParts', 'none', 'Parent', obj.VideoAxes);
                else
                    obj.PaintBrushMarker.EdgeColor = obj.PaintBrush.EdgeColor;
                    obj.PaintBrushMarker.Position = [x1, y1, w, h];
                    obj.PaintBrushMarker.Visible = 'on';
                end
            else
                obj.PaintBrushMarker.Visible = 'off';
            end
        end
        function state = getState(obj)
            % Get current state (for the undo/redo stack)
            state.frameNum = obj.CurrentFrameNum;
            state.frame = squeeze(obj.PaintMask(obj.CurrentFrameNum, :, :));
        end
        function setState(obj, state)
            % Set current state (from the undo/redo stack)
            obj.CurrentFrameNum = state.frameNum;
            obj.PaintMask(obj.CurrentFrameNum, :, :) = state.frame;
            obj.updateVideoFrame();
        end
        function VideoClickHandler(obj, src, evt)
            VideoClickHandler@VideoBrowser(obj, src, evt);
            [x, y] = obj.getCurrentVideoPoint();
            switch obj.MainFigure.SelectionType
                case 'normal'
                    if obj.PaintEnabled
                        painted = obj.paint(x, y);
                        if painted
                            obj.updateVideoFrame(true)
                        end
                    end
            end
        end
        function painted = paint(obj, x, y)
            % x & y are in video coords
            if x >= obj.PaintBrush.xMin && x <= obj.PaintBrush.xMax && y >= obj.PaintBrush.yMin && y <= obj.PaintBrush.yMax
                r = obj.PaintBrush.ActualBrushRadius;
                if obj.IsErasing
                    obj.PaintMask(obj.CurrentFrameNum, y-r:y+r, x-r:x+r) = squeeze(obj.PaintMask(obj.CurrentFrameNum, y-r:y+r, x-r:x+r)) & ~obj.PaintBrush.Brush;
                else
                    obj.PaintMask(obj.CurrentFrameNum, y-r:y+r, x-r:x+r) = squeeze(obj.PaintMask(obj.CurrentFrameNum, y-r:y+r, x-r:x+r)) | obj.PaintBrush.Brush;
                end
                painted = true;
            else
                painted = false;
            end
        end
        function KeyPressHandler(obj, src, evt)
            KeyPressHandler@VideoBrowser(obj, src, evt);
            switch evt.Key
                case 'e'
                    obj.IsErasing = ~obj.IsErasing;
                    obj.updatePaintBrushParams();
                    x = src.CurrentPoint(1, 1);
                    y = src.CurrentPoint(1, 2);
                    if obj.inVideoAxes(x, y)
                        [x, y] = obj.getCurrentVideoPoint();
                        obj.updatePaintBrush(x, y);
                    end
                case 'z'
                    if any(strcmp(evt.Modifier, 'control'))
                        obj.Undo();
                    end
                case 'y'
                    if any(strcmp(evt.Modifier, 'control'))
                        obj.Redo();
                    end
            end
        end
        function MouseMotionHandler(obj, src, evt)
            MouseMotionHandler@VideoBrowser(obj, src, evt);
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inVideoAxes(x, y)
                [x, y] = obj.getCurrentVideoPoint();

                obj.updatePaintBrush(x, y);

                if obj.IsPainting
                    % We're painting!
                    painted = obj.paint(x, y);
                    if painted
                        obj.updateVideoFrame(true)
                    end
                end
            end
        end
        function ScrollWheelHandler(obj, src, evt)
            newRadius = obj.PaintBrush.BrushRadius - evt.VerticalScrollCount;
            if newRadius >= 0
                obj.PaintBrush.BrushRadius = newRadius;
                obj.updatePaintBrushParams();
                x = src.CurrentPoint(1, 1);
                y = src.CurrentPoint(1, 2);
                if obj.inVideoAxes(x, y)
                    [x, y] = obj.getCurrentVideoPoint();
                    obj.updatePaintBrush(x, y);
                end
            end
        end
        function MouseDownHandler(obj, src, evt)
            MouseDownHandler@VideoBrowser(obj, src, evt)
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            switch obj.MainFigure.SelectionType
                case 'normal'
                    if obj.PaintEnabled
                        if obj.inVideoAxes(x, y)
                            obj.updatePaintBrushParams();
                            obj.SaveState();
                            obj.IsPainting = true;
                        end
                    end
            end
        end
        function MouseUpHandler(obj, src, evt)
            MouseUpHandler@VideoBrowser(obj, src, evt)
            if obj.IsPainting
                obj.IsPainting = false;
            end
        end
        function ClearStack(obj)
            if ~isempty(obj.Stack)
                obj.Stack.Clear();
            end
        end
        function SaveState(obj)
            if ~isempty(obj.Stack)
                obj.Stack.SaveState(obj.getState());
            end
        end
        function Undo(obj)
            if ~isempty(obj.Stack)
                currentState = obj.getState();
                newState = obj.Stack.UndoState(currentState);
                obj.setState(newState);
            end
        end
        function Redo(obj)
            if ~isempty(obj.Stack)
                currentState = obj.getState();
                newState = obj.Stack.RedoState(currentState);
                obj.setState(newState);
            end
        end
    end
end