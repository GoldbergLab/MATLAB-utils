classdef CLimGUI < handle
    properties
        CLim                        (1, 2) double = [0, 1]
        ParentFigure                matlab.ui.Figure
        ClimChangedCallback         (1, 1) function_handle = @NOP
    end
    properties (Access = protected)
        Image                       matlab.graphics.primitive.Image
        ImageFunction               function_handle
        ImageAxes                   matlab.graphics.axis.Axes
        HistogramAxes               matlab.graphics.axis.Axes
        HistogramHighlight
        CLimIncrement               double
        ControlPanel                matlab.ui.container.Panel
        LowerBoundIncreaseButton    matlab.ui.control.UIControl
        LowerBoundDecreaseButton    matlab.ui.control.UIControl
        UpperBoundIncreaseButton    matlab.ui.control.UIControl
        UpperBoundDecreaseButton    matlab.ui.control.UIControl
        BoundEntries                matlab.ui.control.UIControl
        IsSelectingCLim             logical
        BoundsToText                function_handle = @(bound)sprintf('%.03f', bound)
    end
    properties (Dependent)
        Visible                     (1, 1) logical
    end
    methods
        function obj = CLimGUI(imageOrAxes, parent_figure, options)
            arguments
                imageOrAxes {mustBeA(imageOrAxes, {'matlab.graphics.Graphics', 'function_handle'})} 
                parent_figure matlab.ui.Figure = matlab.ui.Figure.empty()
                options.ClimChangedCallback function_handle = @NOP
                options.Visible = true
            end
            obj.ClimChangedCallback = options.ClimChangedCallback;
            switch class(imageOrAxes)
                case 'matlab.graphics.primitive.Image'
                    obj.Image = imageOrAxes;
                    obj.ImageAxes = obj.Image.Parent;
                case 'matlab.graphics.axis.Axes'
                    obj.ImageAxes = imageOrAxes;
                    % Find an image in the axes
                    imageIndex = find(arrayfun(@(c)isa(c, 'matlab.graphics.primitive.Image'), obj.ImageAxes.Children), 1);
                    if isempty(imageIndex)
                        obj.Image = matlab.graphics.primitive.Image.empty();
                    else
                        obj.Image = obj.ImageAxes.Children(imageIndex);
                    end
                case 'function_handle'
                    obj.ImageFunction = imageOrAxes;
                    obj.ImageAxes = obj.Image.Parent;
                otherwise
                    error('imageOrAxes should either be a handle for an image or axes or a function that retrieves an image or axes')
            end

            if ~exist('parent_figure', 'var') || isempty(parent_figure)
                ax_position = getWidgetScreenPosition(obj.ImageAxes, 'pixels');
                GUI_width = 175;
                GUI_height = 100;
                fig_position = [ax_position(1) + ax_position(3) - GUI_width, ax_position(2) + ax_position(4), GUI_width, GUI_height];
                obj.ParentFigure = figure("Units", "pixels", "Position", fig_position, "MenuBar", "none", "DockControls", "off", "ToolBar", "none", "Name", "CLim GUI", "NumberTitle", "off", "Visible", options.Visible);
            else
                obj.ParentFigure = parent_figure;
            end

            obj.ParentFigure.WindowButtonDownFcn = @obj.MouseDownHandler;
            obj.ParentFigure.WindowButtonUpFcn = @obj.MouseUpHandler;
            obj.ParentFigure.WindowButtonMotionFcn = @obj.MouseMotionHandler;
            obj.ParentFigure.WindowKeyPressFcn = @obj.KeyPressHandler;
            
            obj.CLimIncrement = 0.5;
            obj.ControlPanel = uipanel("Parent", obj.ParentFigure);
            obj.LowerBoundIncreaseButton = uicontrol("Parent", obj.ControlPanel, "Style", "pushbutton", "String", "↑", "Units", "normalized", "Position", [0.000, 0.500, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(1,  obj.CLimIncrement));
            obj.LowerBoundDecreaseButton = uicontrol("Parent", obj.ControlPanel, "Style", "pushbutton", "String", "↓", "Units", "normalized", "Position", [0.000, 0.000, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(1, -obj.CLimIncrement));
            obj.UpperBoundIncreaseButton = uicontrol("Parent", obj.ControlPanel, "Style", "pushbutton", "String", "↑", "Units", "normalized", "Position", [0.750, 0.500, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(2,  obj.CLimIncrement));
            obj.UpperBoundDecreaseButton = uicontrol("Parent", obj.ControlPanel, "Style", "pushbutton", "String", "↓", "Units", "normalized", "Position", [0.750, 0.000, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(2, -obj.CLimIncrement));
            obj.BoundEntries(1) =          uicontrol("Parent", obj.ControlPanel, "Style", "edit", "String", '', "Units", "normalized",        "Position", [0.250, 0.000, 0.250, 1.000], "Callback", @(~, ~)obj.CLimChangeHandler());
            obj.BoundEntries(2) =          uicontrol("Parent", obj.ControlPanel, "Style", "edit", "String", '', "Units", "normalized",        "Position", [0.500, 0.000, 0.250, 1.000], "Callback", @(~, ~)obj.CLimChangeHandler());
            obj.HistogramAxes = axes(obj.ParentFigure);
            if ~isvalid(obj.Image) || isempty(obj.Image)
                obj.ControlPanel.Position =  [0.000, 0.000, 1.000, 1.000];
                obj.HistogramAxes.Visible = "off";
            else
                obj.ControlPanel.Position =  [0.000, 0.000, 1.000, 0.500];
                obj.HistogramAxes.Position = [0.000, 0.500, 1.000, 0.500];
            end
            obj.UpdateCLimFromAxes();
            obj.UpdateHistogram();
            obj.UpdateHistogramHighlight();
        end
        function image = get.Image(obj)
            if ~isempty(obj.ImageFunction)
                % Update image from image function if it exists
                obj.Image = obj.ImageFunction();
            end
            image = obj.Image;
        end
        function AlterCLim(obj, bound, amount)
            obj.BoundEntries(bound).String = obj.BoundsToText(str2double(obj.BoundEntries(bound).String) + amount);
            obj.SanitizeCLim();
            obj.CLimChangeHandler();
        end
        function SetCLim(obj, bound, value)
            for k = 1:length(bound)
                obj.BoundEntries(bound(k)).String = obj.BoundsToText(value(k));
            end
            obj.SanitizeCLim();
            obj.CLimChangeHandler();
        end
        function clim = GetCLim(obj)
            obj.SanitizeCLim();
            clim = [str2double(obj.BoundEntries(1).String), str2double(obj.BoundEntries(2).String)];
        end
        function SanitizeCLim(obj)
            if str2double(obj.BoundEntries(1).String) >= str2double(obj.BoundEntries(2).String)
                obj.BoundEntries(2).String = obj.BoundsToText(str2double(obj.BoundEntries(1).String) + obj.CLimIncrement);
            end
        end
        function UpdateHistogram(obj)
            cla(obj.HistogramAxes);
            if ~isempty(obj.Image)
                histogram(obj.HistogramAxes, obj.Image.CData(:), 'EdgeColor', 'none', 'FaceColor', [0, 0, 1]);
            end
            obj.CLimIncrement = diff(xlim(obj.HistogramAxes))/20;
        end
        function UpdateHistogramHighlight(obj)
            delete(obj.HistogramHighlight);
            if ~isempty(obj.Image)
                mask_x = linspace(obj.HistogramAxes.XLim(1), obj.HistogramAxes.XLim(2), 1000);
                mask = zeros(size(mask_x), 'logical');
                clim = [str2double(obj.BoundEntries(1).String), str2double(obj.BoundEntries(2).String)];
                mask(mask_x >= clim(1) & mask_x <= clim(2)) = true;
                delete(obj.HistogramHighlight);
                obj.HistogramHighlight = highlight_plot(obj.HistogramAxes, mask_x, mask);
            end
        end
        function UpdateCLimFromAxes(obj)
            obj.SetCLim(1:2, obj.ImageAxes.CLim);
        end
        function CLimChangeHandler(obj)
            obj.CLim = obj.GetCLim();
            obj.UpdateHistogram();
            obj.UpdateHistogramHighlight();
            obj.ApplyCLimToAxes();
            obj.ClimChangedCallback(obj.CLim);
        end
        function ApplyCLimToAxes(obj)
            new_clim = [str2double(obj.BoundEntries(1).String), str2double(obj.BoundEntries(2).String)];
            obj.ImageAxes.CLim = new_clim;
        end
        function inside = inHistogramAxes(obj, x, y)
            % Determine if the given figure coordinates fall within the
            %   borders of the HistogramAxes or not..
            originalUnits = obj.HistogramAxes.Units;
            obj.HistogramAxes.Units = "pixels";
            if y < obj.HistogramAxes.Position(2)
                inside = false;
            elseif y > obj.HistogramAxes.Position(2) + obj.HistogramAxes.Position(4)
                inside = false;
            elseif (x < obj.HistogramAxes.Position(1))
                inside = false;
            elseif x > obj.HistogramAxes.Position(1) + obj.HistogramAxes.Position(3)
                inside = false;
            else
                inside = true;
            end
            obj.HistogramAxes.Units = originalUnits;
        end
        function colorVal = mapFigureXToColor(obj, x)
            % Convert a figure x coordinate to color val on the histogram
            %   axes
            originalUnits = obj.HistogramAxes.Units;
            obj.HistogramAxes.Units = obj.ParentFigure.Units;
            colorVal = (x - obj.HistogramAxes.Position(1)) * diff(obj.HistogramAxes.XLim) / obj.HistogramAxes.Position(3) + obj.HistogramAxes.XLim(1);
            obj.HistogramAxes.Units = originalUnits;
        end
        function MouseMotionHandler(obj, ~, ~)
            if obj.IsSelectingCLim
                xFig = obj.ParentFigure.CurrentPoint(1, 1);
                yFig = obj.ParentFigure.CurrentPoint(1, 2);
    
                if obj.inHistogramAxes(xFig, yFig)
                    colorVal = obj.mapFigureXToColor(xFig);
                    currentCLim = obj.GetCLim();
                    middleCLim = mean(currentCLim);
                    if colorVal <= middleCLim
                        obj.SetCLim(1, colorVal);
                    else
                        obj.SetCLim(2, colorVal);
                    end
                end
            end

        end
        function MouseDownHandler(obj, ~, ~)
            % Handle user mouse click
            xFig = obj.ParentFigure.CurrentPoint(1, 1);
            yFig = obj.ParentFigure.CurrentPoint(1, 2);

            if obj.inHistogramAxes(xFig, yFig)
                % Mouse click is in histogram axes
                obj.IsSelectingCLim = true;

                colorVal = obj.mapFigureXToColor(xFig);
                currentCLim = obj.GetCLim();
                middleCLim = mean(currentCLim);
                if colorVal <= middleCLim
                    obj.SetCLim(1, colorVal);
                else
                    obj.SetCLim(2, colorVal);
                end
            end
            obj.CLimChangeHandler();
        end
        function MouseUpHandler(obj, ~, ~)
            obj.IsSelectingCLim = false;
        end
        function KeyPressHandler(obj, ~, event)
            if any(strcmp(event.Modifier, 'control'))
                % User is pressing control
                switch event.Key
                    case 'c'
                    % Copy clim to clipboard
                    clipboard('copy', sprintf('[%s, %s]', obj.BoundEntries(1).String, obj.BoundEntries(2).String));
                end
            end
        end
        function set.Visible(obj, visible)
            obj.ParentFigure.Visible = visible;
        end
        function visible = get.Visible(obj)
            visible = obj.ParentFigure.Visible;
        end
    end
end