classdef VideoROISelector < VideoBrowser
    properties (Access = private)
        RectangleHandle         
    end
    properties
        X = []
        Y = []
        W = []
        H = []
    end
    properties (Transient)
        StrokeEndHandler        function_handle = @NOP               % Callback that fires when user completes a stroke, or uses undo/redo
    end
    properties (SetObservable, Access = private)
        IsPainting              logical = false                      % Is user currently holding mouse button down on video axes?
    end
    methods
        function obj = VideoROISelector(videoData, options)
            arguments
                videoData
                options.NavigationData
                options.NavigationColor
                options.NavigationColormap
                options.NavigationCLim
                options.Title
                options.Async
            end
            vbOptions = options;
            args = namedargs2cell(vbOptions);
            obj@VideoBrowser(videoData, args{:});
        end
        function createDisplayArea(obj)
            createDisplayArea@VideoBrowser(obj);
            obj.MainFigure.Name = 'Video ROI Selector';
            obj.MainFigure.WindowScrollWheelFcn = @obj.ScrollWheelHandler;
        end
        function updateVideoFrame(obj, rectangleOnly)
            arguments
                obj VideoROISelector
                rectangleOnly logical = false
            end
            if ~rectangleOnly
                % If we're not just updating the paint, update everything
                updateVideoFrame@VideoBrowser(obj);
            end
            % Update rectangle

        end
        function VideoClickHandler(obj, src, evt)
            VideoClickHandler@VideoBrowser(obj, src, evt);
            [x, y] = obj.getCurrentVideoPoint();
            switch obj.MainFigure.SelectionType
                case 'normal'
                    if ~isgraphics(obj.RectangleHandle)
                        obj.X = x;
                        obj.Y = y;
                        obj.W = 0;
                        obj.H = 0;
                        obj.RectangleHandle = obj.createNewRectangle();
                    else
                        obj.normalizeROICoordinates();
                        delete(obj.RectangleHandle);
                    end
            end
        end
        function createNewRectangle(obj)
            if isempty(obj.RectangleHandle)
                delete(obj.RectangleHandle);
            end
            obj.RectangleHandle = rectangle(obj.VideoAxes, 'Position', [obj.X, obj.Y, obj.W, obj.H]);
        end
        function updateRectangleCoordinates(obj, x, y)
            obj.W = x - obj.X;
            obj.H = y - obj.Y;
        end
        function normalizeROICoordinates(obj)
            if obj.W < 0
                obj.W = abs(obj.W);
                obj.X = obj.X - obj.W;
            end
            if obj.H < 0
                obj.H = abs(obj.H);
                obj.Y = obj.Y - obj.H;
            end
        end
        function cancelROI(obj)
            delete(obj.RectangleHandle);
            obj.X = [];
            obj.Y = [];
            obj.W = [];
            obj.H = [];
        end
        function KeyPressHandler(obj, src, evt)
            KeyPressHandler@VideoBrowser(obj, src, evt);
            switch evt.Key
                % if any(strcmp(evt.Modifier, 'control'))
                case 'esc'
                    obj.cancelROI(obj);
            end
        end
        function MouseMotionHandler(obj, src, evt)
            MouseMotionHandler@VideoBrowser(obj, src, evt);
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inVideoAxes(x, y)
                [x, y] = obj.getCurrentVideoPoint();
                obj.updateRectangleCoordinates(x, y);
            end
        end
        function ScrollWheelHandler(obj, src, evt)
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            if obj.inVideoAxes(x, y)
                % [x, y] = obj.getCurrentVideoPoint();
                obj.scaleRectangelCoordinates(evt.VerticalScrollCount);
            end
        end
        function MouseDownHandler(obj, src, evt)
            MouseDownHandler@VideoBrowser(obj, src, evt)
            x = src.CurrentPoint(1, 1);
            y = src.CurrentPoint(1, 2);
            switch obj.MainFigure.SelectionType
                case 'normal'
            end
        end
        function MouseUpHandler(obj, src, evt)
            MouseUpHandler@VideoBrowser(obj, src, evt)
        end
    end
end