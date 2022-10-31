classdef VideoPainter < VideoBrowser
    properties (Access = private)
        IsPainting               logical = false
        IsErasing                logical = false
    end
    properties
        PaintMask          logical = logical.empty()            % Painted mask stack
        PaintMaskImage     matlab.graphics.primitive.Image      % Image handle to paint mask
        PaintMaskColor     double = [1, 0, 0]                   % Color of paint mask
        PaintBrush         struct                               % Brush
        PaintBrushMarker   matlab.graphics.primitive.Rectangle  % Brush marker
    end
    methods
        function obj = VideoPainter(varargin)
            obj@VideoBrowser(varargin{:});
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
            obj.PaintBrush.Brush = strel('disk', obj.PaintBrush.BrushRadius).Neighborhood;
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
            if isempty(obj.PaintBrushMarker)
                obj.PaintBrushMarker = rectangle('Position', [x1, y1, w, h], 'Curvature',[1,1], 'EdgeColor', obj.PaintBrush.EdgeColor, 'HitTest', 'off', 'PickableParts', 'none', 'Parent', obj.VideoAxes);
            else
                obj.PaintBrushMarker.EdgeColor = obj.PaintBrush.EdgeColor;
                obj.PaintBrushMarker.Position = [x1, y1, w, h];
            end
        end
        function VideoClickHandler(obj, src, evt)
            VideoClickHandler@VideoBrowser(obj, src, evt);
            [x, y] = obj.getCurrentVideoPoint();
            switch obj.MainFigure.SelectionType
                case 'normal'
                    painted = obj.paint(x, y);
                    if painted
                        obj.updateVideoFrame(true)
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
        function MouseDownHandler(obj, src, evt)
            MouseDownHandler@VideoBrowser(obj, src, evt)
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inVideoAxes(x, y)
                obj.updatePaintBrushParams();
                obj.IsPainting = true;
            end
        end
        function ScrollWheelHandler(obj, src, evt)
            newRadius = obj.PaintBrush.BrushRadius - evt.VerticalScrollCount;
            if newRadius > 1
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
        function MouseUpHandler(obj, src, evt)
            MouseUpHandler@VideoBrowser(obj, src, evt)
            if obj.IsPainting
                obj.IsPainting = false;
            end
        end
    end
end