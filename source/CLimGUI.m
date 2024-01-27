classdef CLimGUI < handle
    properties
        ParentFigure                matlab.ui.Figure
        ImageAxes                   matlab.graphics.axis.Axes
        CLimIncrement               double
        LowerBoundIncreaseButton    matlab.ui.control.UIControl
        LowerBoundDecreaseButton    matlab.ui.control.UIControl
        UpperBoundIncreaseButton    matlab.ui.control.UIControl
        UpperBoundDecreaseButton    matlab.ui.control.UIControl
        BoundEntries                matlab.ui.control.UIControl
    end
    methods
        function obj = CLimGUI(ax, increment, parent_figure)
            obj.ImageAxes = ax;

            if ~exist('increment', 'var') || isempty(increment)
                increment = 0.5;
            end
            if ~exist('parent_figure', 'var') || isempty(parent_figure)
                ax_position = getWidgetScreenPosition(obj.ImageAxes, 'pixels');
                GUI_width = 150;
                GUI_height = 40;
                fig_position = [ax_position(1) + ax_position(3) - GUI_width, ax_position(2) + ax_position(4), GUI_width, GUI_height];
                obj.ParentFigure = figure("Units", "pixels", "Position", fig_position, "MenuBar", "none", "DockControls", "off", "ToolBar", "none", "Name", "CLim GUI", "NumberTitle", "off");
            else
                obj.ParentFigure = parent_figure;
            end
            
            obj.CLimIncrement = increment;
            obj.LowerBoundIncreaseButton = uicontrol("Style", "pushbutton", "String", "↑", "Units", "normalized", "Position", [0.000, 0.375, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(1,  obj.CLimIncrement));
            obj.LowerBoundDecreaseButton = uicontrol("Style", "pushbutton", "String", "↓", "Units", "normalized", "Position", [0.000, 0.000, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(1, -obj.CLimIncrement));
            obj.UpperBoundIncreaseButton = uicontrol("Style", "pushbutton", "String", "↑", "Units", "normalized", "Position", [0.750, 0.375, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(2,  obj.CLimIncrement));
            obj.UpperBoundDecreaseButton = uicontrol("Style", "pushbutton", "String", "↓", "Units", "normalized", "Position", [0.750, 0.000, 0.250, 0.500], "Callback", @(~, ~)obj.AlterCLim(2, -obj.CLimIncrement));
            obj.BoundEntries(1) =          uicontrol("Style", "edit", "String", '', "Units", "normalized",        "Position", [0.250, 0.000, 0.250, 1]);
            obj.BoundEntries(2) =          uicontrol("Style", "edit", "String", '', "Units", "normalized",        "Position", [0.500, 0.000, 0.250, 1]);
            obj.UpdateCLimFromAxes();
        end
        function AlterCLim(obj, bound, amount)
            obj.BoundEntries(bound).String = num2str(str2double(obj.BoundEntries(bound).String) + amount);
            obj.SanitizeCLim();
            obj.ApplyCLimToAxes();
        end
        function SanitizeCLim(obj)
            str2double(obj.BoundEntries(1).String)
            str2double(obj.BoundEntries(2).String)
            if str2double(obj.BoundEntries(1).String) >= str2double(obj.BoundEntries(2).String)
                obj.BoundEntries(2).String = num2str(str2double(obj.BoundEntries(1).String) + obj.CLimIncrement);
            end
        end
        function UpdateCLimFromAxes(obj)
            obj.BoundEntries(1).String = num2str(obj.ImageAxes.CLim(1));
            obj.BoundEntries(2).String = num2str(obj.ImageAxes.CLim(2));
        end
        function ApplyCLimToAxes(obj)
            new_clim = [str2double(obj.BoundEntries(1).String), str2double(obj.BoundEntries(2).String)];
            obj.ImageAxes.CLim = new_clim;
        end
    end
end