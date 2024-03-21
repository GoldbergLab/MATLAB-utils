classdef uicheckboxgroup < matlab.ui.componentcontainer.ComponentContainer
    properties
        NumRows double = 3
        NumColumns double = []
    end
    properties (Access = private, Transient, NonCopyable)
        Panel (1, 1) matlab.ui.container.Panel
        CheckBoxes
    end
    properties
        Enable = 'on'
        Tooltip = ''
        TooltipString = ''
        HorizontalAlignment
        Value (1, :) logical = logical.empty()
        String (1, :) cell {mustBeText} = {}
        ForegroundColor (1, 3) double = [0, 0, 0]
        FontName = 'fixedwidth'
        FontSize (1, 1) double = 12
        FontWeight (1, :) char = 'normal'
        FontAngle (1, :) char = 'normal'
        FontUnits (1, :) char = 'points'
        Callback
        KeyPressFcn
        KeyReleaseFcn
    end
    properties
        TileShape (1, :) char {mustBeMember(TileShape, {'auto', 'row', 'column'})} = 'auto'
    end
    methods (Access = protected)
        function setup(obj)
            obj.Panel = uipanel('Parent', obj);
            obj.CheckBoxes = gobjects().empty;
            obj.Units = 'normalized';
            obj.Position = [0, 0, 1, 1];
        end
        function update(obj)
            obj.Panel.Units = obj.Units;
            obj.Panel.Position = obj.Position;
            obj.Panel.ForegroundColor = obj.ForegroundColor;
            obj.Panel.BackgroundColor = obj.BackgroundColor;
            obj.Panel.FontName = obj.FontName;
            obj.Panel.FontSize = obj.FontSize;
            obj.Panel.FontWeight = obj.FontWeight;
            obj.Panel.FontAngle = obj.FontAngle;
            obj.Panel.FontUnits = obj.FontUnits;
            obj.Panel.Visible = obj.Visible;
            obj.Panel.Enable = obj.Enable;
            obj.Panel.Tooltip = obj.Tooltip;
            obj.Panel.ContextMenu = obj.ContextMenu;
            obj.Panel.ButtonDownFcn = obj.ButtonDownFcn;
            obj.Panel.HandleVisibility = obj.HandleVisibility;
            obj.Panel.Interruptible = obj.Interruptible;
            obj.Panel.BusyAction = obj.BusyAction;
            obj.Panel.HitTest = obj.HitTest;

            numButtons = length(obj.String);
            if length(obj.Value) < numButtons
                obj.Value(end+1:numButtons) = false;
            end
            if numButtons ~= length(obj.CheckBoxes)
                % Check box complement does not match String property -
                % recreate check boxes
                for k = 1:numButtons
                    obj.CheckBoxes(k) = uicontrol('Parent', obj.Panel, 'Style', 'checkbox', 'String', obj.String{k}, 'Units', 'normalized');
                end
            end
            switch obj.TileShape
                case 'auto'
                    numColumns = ceil(sqrt(numButtons));
                    numRows = ceil(numButtons/numColumns);
                    tileSize = [numColumns, numRows];
                case 'row'
                    tileSize = [numButtons, 1];
                case 'column'
                    tileSize = [1, numButtons];
            end
            tileChildren(obj.Panel, tileSize);
            for k = 1:numButtons
                obj.CheckBoxes(k).ForegroundColor = obj.ForegroundColor;
                obj.CheckBoxes(k).BackgroundColor = obj.BackgroundColor;
                obj.CheckBoxes(k).Value = obj.Value(k);
                obj.CheckBoxes(k).String = obj.String{k};
                obj.CheckBoxes(k).FontName = obj.FontName;
                obj.CheckBoxes(k).FontSize = obj.FontSize;
                obj.CheckBoxes(k).FontWeight = obj.FontWeight;
                obj.CheckBoxes(k).FontAngle = obj.FontAngle;
                obj.CheckBoxes(k).FontUnits = obj.FontUnits;
                obj.CheckBoxes(k).Callback = obj.Callback;
                obj.Panel.Interruptible = obj.Interruptible;
                obj.Panel.BusyAction = obj.BusyAction;
                obj.Panel.HitTest = obj.HitTest;
            end
        end
    end
    methods
        % Getters + setters
        function values = get.Value(obj)
            if isempty(obj.CheckBoxes)
                values = logical.empty();
            else
                values = [obj.CheckBoxes.Value];
            end
        end
        function set.Value(obj, values)
            obj.Value = values;
        end
        function set.TileShape(obj, tileShape)
            obj.TileShape = tileShape;
            obj.update();
        end
    end
end