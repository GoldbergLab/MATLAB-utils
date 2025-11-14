classdef ProgressBar < handle
    properties (Access = private)
        Figure (1, 1)
        Axes (1, 1) matlab.graphics.axis.Axes
        Text (1, 1) matlab.graphics.primitive.Text
        Bar (1, 1) matlab.graphics.primitive.Rectangle
        Width (1, 1) double = 250
        Height (1, 1) double = 30
    end
    properties
        Progress (1, 1) double {mustBeInRange(Progress, 0, 1)}
        Visible (1, 1) matlab.lang.OnOffSwitchState = 'on'
        Message {mustBeText} = "Please wait"
        BackgroundColor {validatecolor} = 'white'
        BarColor {validatecolor} = 'cyan'
        Interpreter = 'none'
        WindowStyle {mustBeMember(WindowStyle, {'modal', 'docked', 'normal'})} = 'modal'
    end
    methods
        function obj = ProgressBar(message, centerOnWidget, options)
            arguments
                message {mustBeText}
                centerOnWidget = groot
                options.Progress (1, 1) double {mustBeInRange(options.Progress, 0, 1)} = 0
                options.Visible (1, 1) matlab.lang.OnOffSwitchState = 'on'
                options.Message {mustBeText} = "Please wait"
                options.BackgroundColor {validatecolor} = 'white'
                options.BarColor {validatecolor} = 'cyan'
                options.Interpreter = 'none'
                options.WindowStyle {mustBeMember(options.WindowStyle, {'modal', 'docked', 'normal'})} = 'modal'
                options.Width (1, 1) double = 250
                options.Height (1, 1) double = 30
            end
            obj.Progress = options.Progress;
            obj.Visible = options.Visible;
            obj.Message = options.Message;
            obj.BackgroundColor = options.BackgroundColor;
            obj.BarColor = options.BarColor;
            obj.Interpreter = options.Interpreter;
            obj.WindowStyle = options.WindowStyle;
            obj.Width = options.Width;
            obj.Height = options.Height;

            if centerOnWidget == groot
                % Just center progress bar in the middle of the screen
                set(0, 'units', 'pixels');
                screenSize = get(0, 'ScreenSize');
                W = screenSize(3);
                H = screenSize(4);
                x = W/2-obj.Width/2;
                y = H/2-obj.Height/2;
            else
                % Center progress bar in the middle of the given widget
                pp = getpixelposition(centerOnWidget);
                x = pp(1) + pp(3)/2 - obj.Width/2;
                y = pp(2) + pp(4)/2 - obj.Height/2;
            end

            obj.Message = message;

            obj.Figure = figure( ...
                'Units', 'pixels', ...
                'Position', [x, y, obj.Width, obj.Height], ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'NumberTitle', 'off', ...
                'Visible', obj.Visible, ...
                'CloseRequestFcn', @(varargin)obj.updateVisible('off') ...
                );
            obj.Axes = axes( ...
                obj.Figure, ...
                'Units', 'pixels', ...
                'Position', [1, 1, obj.Width, obj.Height], ...
                'XLim', [0, 1], ...
                'YLim', [0, 1], ...
                'Color', obj.BackgroundColor ...
                );
            obj.Axes.XAxis.Visible = false;
            obj.Axes.YAxis.Visible = false;
            obj.Bar = rectangle( ...
                obj.Axes, ...
                "Position", [0, 0, 0, 1], ...
                'FaceColor', obj.BarColor ...
                );
            obj.Text = text( ...
                obj.Axes, ...
                'Position', [0.5, 0.5], ...
                'String', obj.Message, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                "Interpreter", obj.Interpreter ...
                );
        end
        function delete(obj)
            delete(obj.Figure);
        end
        function ready = figureReady(obj)
            ready = isa(obj.Figure, 'matlab.ui.Figure') && ~isempty(obj.Figure) && isvalid(obj.Figure);
        end
        function ready = axesReady(obj)
            ready = isa(obj.Axes, 'matlab.graphics.axis.Axes') && ~isempty(obj.Axes) && isvalid(obj.Axes);
        end
        function ready = barReady(obj)
            ready = isa(obj.Bar, 'matlab.graphics.primitive.Rectangle') && ~isempty(obj.Bar) && isvalid(obj.Bar);
        end
        function ready = textReady(obj)
            ready = isa(obj.Text, 'matlab.graphics.primitive.Text') && ~isempty(obj.Text) && isvalid(obj.Text);
        end
    end
    methods (Access = private) % Updaters
        function updateProgress(obj)
            obj.Bar.Position = [0, 0, obj.Progress, 1];
            if ~obj.figureReady(); return; end
            obj.Figure.Visible = 'on';
        end
        function updateColors(obj)
            if ~obj.barReady(); return; end
            obj.Bar.FaceColor = obj.BarColor;
            if ~obj.axesReady(); return; end
            obj.Axes.Color = obj.BackgroundColor;
        end
        function updateVisible(obj, visible)
            arguments
                obj ProgressBar
                visible = obj.Visible
            end
            if ~obj.figureReady(); return; end
            obj.Figure.Visible = visible;
        end
        function updateText(obj)
            if ~obj.textReady(); return; end
            obj.Text.String = obj.Message;
        end
        function updateInterpreter(obj)
            if ~obj.textReady(); return; end
            obj.Text.Interpreter = obj.Interpreter;
        end
        function updateWindowStyle(obj, windowStyle)
            arguments
                obj ProgressBar
                windowStyle {mustBeMember(windowStyle, {'modal', 'docked', 'normal'})} = 'modal'
            end
            if ~obj.figureReady(); return; end
            obj.Figure.WindowStyle = windowStyle;
        end
    end
    methods  % Getters and Setters
        function set.Visible(obj, visible)
            arguments
                obj ProgressBar
                visible (1, 1) matlab.lang.OnOffSwitchState
            end
            obj.Visible = visible;
            obj.updateVisible();
        end
        function set.BackgroundColor(obj, color)
            arguments
                obj ProgressBar
                color {validatecolor}
            end
            obj.BackgroundColor = color;
            obj.updateColors();
        end
        function set.BarColor(obj, color)
            arguments
                obj ProgressBar
                color {validatecolor}
            end
            obj.BarColor = color;
            obj.updateColors();
        end
        function set.Message(obj, message)
            arguments
                obj ProgressBar
                message {mustBeText}
            end
            obj.Message = message;
            obj.updateText();
        end
        function set.Progress(obj, progress)
            arguments
                obj ProgressBar
                progress double {mustBeInRange(progress, 0, 1)}
            end
            obj.Progress = progress;
            obj.updateProgress();
        end
        function set.Interpreter(obj, interpreter)
            obj.Interpreter = interpreter;
            obj.updateInterpreter();
        end
        function set.WindowStyle(obj, windowStyle)
            arguments
                obj ProgressBar
                windowStyle {mustBeMember(windowStyle, {'modal', 'docked', 'normal'})} = 'modal'
            end
            obj.updateWindowStyle(windowStyle);
        end
    end
end