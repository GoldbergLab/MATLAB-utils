classdef uitable2 < handle
    %% Additional properties
    properties (SetAccess = private)
        PreviousSelection = []
        Selection       = []
        Size
        NumRows
        NumColumns
    end
    properties (Access = private)
        UserBackgroundColor = ones(0, 3);
    end
    properties
        RowSelectionColor = [0.7, 0.7, 1];
        SelectedRow     = []
        ColumnSelectable = logical.empty()   % Can a click in this column change the row selection?
    end
    properties
        %% Overridden properties
        CellSelectionCallback function_handle = @NOP
    end
    properties
        %% Dummy properties - just passed to uitable
        Data
        ColumnName
        ColumnWidth
        ColumnEditable
        ColumnRearrangeable
        ColumnFormat
        RowName
        FontName
        FontSize
        FontWeight
        FontAngle
        FontUnits
        Visible
        Enable
        Tooltip
        ContextMenu
        BackgroundColor
        ForegroundColor
        RowStriping
        Position
        InnerPosition
        OuterPosition
        Units
        CellEditCallback
        ButtonDownFcn
        KeyPressFcn
        KeyReleaseFcn
        CreateFcn
        DeleteFcn
        Interruptible
        BusyAction
        BeingDeleted
        HitTest
        Parent
        Children
        HandleVisibility
        Type
        Tag
        UserData
        Extent
    end
    properties (Access = private)
        UITable matlab.ui.control.Table
    end
    methods
        function obj = uitable2(varargin)
            obj.UITable = uitable(varargin{:});
            obj.UITable.Interruptible = 'off';
            obj.UITable.BusyAction = 'queue';
            obj.UITable.CellSelectionCallback = @obj.SelectionCallback;
        end

        function SelectionCallback(obj, src, event)
            if ~isempty(event.Indices) && ~isequal(obj.Selection, event.Indices)
                % Update PreviousSelection property
                obj.PreviousSelection = obj.Selection;
                % Update Selection property
                obj.Selection = event.Indices;
                if isempty(event.Indices) || obj.ColumnSelectable(event.Indices(1, 2))
                    % First selection index is not in a non-selectable column.
                    % Update SelectedRow
                    % Update SelectedRow property
                    obj.SelectedRow = min(obj.Selection(:, 1));
                    obj.UpdateBackgroundColor();
                end
                % Call callback
                obj.CellSelectionCallback(src, event);
            end
        end

        %% New getters/setters
        function set.ColumnSelectable(obj, value)
            if ~isempty(value) && (~isrow(value) || length(value) ~= obj.NumColumns || ~islogical(value))
                error('ColumnSelectable must be a logical row vector with length equal to the number of columns, or an empty array.')
            end
            obj.ColumnSelectable = value;
        end

        function set.SelectedRow(obj, value)
            if ~isequal(obj.SelectedRow, value)
                obj.SelectedRow = value;
                obj.UpdateBackgroundColor();
            end
        end

        function value = get.Size(obj)
            value = size(obj.UITable.Data);
        end
        function value = get.NumRows(obj)
            value = obj.Size(1);
        end
        function value = get.NumColumns(obj)
            value = obj.Size(2);
        end

        %% Other methods
        function UpdateColumnSelectable(obj)
            if length(obj.ColumnSelectable) > obj.NumColumns
                obj.ColumnSelectable = obj.ColumnSelectable(1:obj.NumColumns);
            elseif length(obj.ColumnSelectable) < obj.NumColumns
                obj.ColumnSelectable = [obj.ColumnSelectable, false(1, obj.NumColumns - length(obj.ColumnSelectable))];
            end
        end
        function UpdateBackgroundColorSize(obj)
            % Ensure BackgroundColor has the same # of rows as the data
            numRows = obj.Size(1);
            colorSize = size(obj.UserBackgroundColor);
            if colorSize(2) ~= 3
                error('Something went wrong with the background color size')
            end
            rowDifference = numRows - colorSize(1);
            if rowDifference > 0
                % Add on white row colors
                obj.UserBackgroundColor(end+1:end+rowDifference, :) = ones(rowDifference, 3);
            elseif rowDifference < 0
                % Trim off row colors
                obj.UserBackgroundColor = obj.UserBackgroundColor(1:numRows, :);
            end
        end
        function ResetBackgroundColor(obj, color)
            arguments
                obj          uitable2
                color (1, 3) double   = [1, 1, 1]
            end
            obj.UserBackgroundColor = repmat(color, obj.NumRows, 1);
            obj.UpdateBackgroundColor();
        end
        function UpdateBackgroundColor(obj)
            % Attempt to shoehorn background color into the same size as
            % the data
            obj.UpdateBackgroundColorSize();
            backgroundColor = obj.UserBackgroundColor;
            if ~isempty(obj.SelectedRow)
                backgroundColor(obj.SelectedRow, :) = obj.RowSelectionColor;
            end
            temp = obj.UITable.CellSelectionCallback;
            obj.UITable.CellSelectionCallback = @NOP;
            obj.UITable.BackgroundColor = backgroundColor;
            obj.UITable.CellSelectionCallback = temp;
        end

        %% Getters
        function value = get.Data(obj)
            value = obj.UITable.Data;
        end

        function value = get.ColumnName(obj)
            value = obj.UITable.ColumnName;
        end
        
        function value = get.ColumnWidth(obj)
            value = obj.UITable.ColumnWidth;
        end
        
        function value = get.ColumnEditable(obj)
            value = obj.UITable.ColumnEditable;
        end
        
        function value = get.ColumnRearrangeable(obj)
            try
                value = obj.UITable.ColumnRearrangeable;
            catch
                % 2021a and possibly earlier versions error on this
                value = false;
            end
        end
        
        function value = get.ColumnFormat(obj)
            value = obj.UITable.ColumnFormat;
        end
        
        function value = get.RowName(obj)
            value = obj.UITable.RowName;
        end
        
        function value = get.FontName(obj)
            value = obj.UITable.FontName;
        end
        
        function value = get.FontSize(obj)
            value = obj.UITable.FontSize;
        end
        
        function value = get.FontWeight(obj)
            value = obj.UITable.FontWeight;
        end
        
        function value = get.FontAngle(obj)
            value = obj.UITable.FontAngle;
        end
        
        function value = get.FontUnits(obj)
            value = obj.UITable.FontUnits;
        end
        
        function value = get.Visible(obj)
            value = obj.UITable.Visible;
        end
        
        function value = get.Enable(obj)
            value = obj.UITable.Enable;
        end
        
        function value = get.Tooltip(obj)
            value = obj.UITable.Tooltip;
        end
        
        function value = get.ContextMenu(obj)
            value = obj.UITable.ContextMenu;
        end
        
        function value = get.ForegroundColor(obj)
            value = obj.UITable.ForegroundColor;
        end
        
        function value = get.BackgroundColor(obj)
            value = obj.UITable.BackgroundColor;
        end
        
        function value = get.RowStriping(obj)
            value = obj.UITable.RowStriping;
        end
        
        function value = get.Position(obj)
            value = obj.UITable.Position;
        end
        
        function value = get.InnerPosition(obj)
            value = obj.UITable.InnerPosition;
        end
        
        function value = get.OuterPosition(obj)
            value = obj.UITable.OuterPosition;
        end
        
        function value = get.Units(obj)
            value = obj.UITable.Units;
        end
        
        function value = get.CellEditCallback(obj)
            value = obj.UITable.CellEditCallback;
        end
        
        function value = get.ButtonDownFcn(obj)
            value = obj.UITable.ButtonDownFcn;
        end
        
        function value = get.KeyPressFcn(obj)
            value = obj.UITable.KeyPressFcn;
        end
        
        function value = get.KeyReleaseFcn(obj)
            value = obj.UITable.KeyReleaseFcn;
        end
        
        function value = get.CreateFcn(obj)
            value = obj.UITable.CreateFcn;
        end
        
        function value = get.DeleteFcn(obj)
            value = obj.UITable.DeleteFcn;
        end
        
%         function value = get.CellSelectionCallback(obj)
%             value = obj.UITable.CellSelectionCallback;
%         end
%         
        function value = get.Interruptible(obj)
            value = obj.UITable.Interruptible;
        end
        
        function value = get.BusyAction(obj)
            value = obj.UITable.BusyAction;
        end
        
        function value = get.BeingDeleted(obj)
            value = obj.UITable.BeingDeleted;
        end
        
        function value = get.HitTest(obj)
            value = obj.UITable.HitTest;
        end
        
        function value = get.Parent(obj)
            value = obj.UITable.Parent;
        end
        
        function value = get.Children(obj)
            value = obj.UITable.Children;
        end
        
        function value = get.HandleVisibility(obj)
            value = obj.UITable.HandleVisibility;
        end
        
        function value = get.Type(obj)
            value = obj.UITable.Type;
        end
        
        function value = get.Tag(obj)
            value = obj.UITable.Tag;
        end
        
        function value = get.UserData(obj)
            value = obj.UITable.UserData;
        end
        
        function value = get.Extent(obj)
            value = obj.UITable.Extent;
        end       

        %% Setters
        function set.Data(obj, value)
            obj.Selection = []; %#ok<*MCSUP> 
            obj.UITable.Data = value; 
            obj.UpdateBackgroundColor();
            obj.UpdateColumnSelectable();
        end
        
        function set.ColumnName(obj, value)
            obj.UITable.ColumnName = value;
        end
        
        function set.ColumnWidth(obj, value)
            obj.UITable.ColumnWidth = value;
        end
        
        function set.ColumnEditable(obj, value)
            obj.UITable.ColumnEditable = value;
        end
        
        function set.ColumnRearrangeable(obj, value)
            try
                obj.UITable.ColumnRearrangeable = value;
            catch ME
                % 2021a and possibly earlier versions error on this
                warning('This version of MATLAB does not appear to allow rearranging columns in a uitable - please upgrade to MATLAB 2022 or later to get that feature.');
            end
        end
        
        function set.ColumnFormat(obj, value)
            obj.UITable.ColumnFormat = value;
        end
        
        function set.RowName(obj, value)
            obj.UITable.RowName = value;
        end
        
        function set.FontName(obj, value)
            obj.UITable.FontName = value;
        end
        
        function set.FontSize(obj, value)
            obj.UITable.FontSize = value;
        end
        
        function set.FontWeight(obj, value)
            obj.UITable.FontWeight = value;
        end
        
        function set.FontAngle(obj, value)
            obj.UITable.FontAngle = value;
        end
        
        function set.FontUnits(obj, value)
            obj.UITable.FontUnits = value;
        end
        
        function set.Visible(obj, value)
            obj.UITable.Visible = value;
        end
        
        function set.Enable(obj, value)
            obj.UITable.Enable = value;
        end
        
        function set.Tooltip(obj, value)
            obj.UITable.Tooltip = value;
        end
        
        function set.ContextMenu(obj, value)
            obj.UITable.ContextMenu = value;
        end
        
        function set.ForegroundColor(obj, value)
            obj.UITable.ForegroundColor = value;
        end

        function set.BackgroundColor(obj, value)
            if size(value, 1) ~= obj.Size(1) || size(value, 2) ~= 3
                error('Background color size must be a Mx3 array, where M is the number of rows in the data');
            end
            obj.UserBackgroundColor = value;
            obj.UpdateBackgroundColor();
        end
        
        function set.RowStriping(obj, value)
            obj.UITable.RowStriping = value;
        end
        
        function set.Position(obj, value)
            obj.UITable.Position = value;
        end
        
        function set.InnerPosition(obj, value)
            obj.UITable.InnerPosition = value;
        end
        
        function set.OuterPosition(obj, value)
            obj.UITable.OuterPosition = value;
        end
        
        function set.Units(obj, value)
            obj.UITable.Units = value;
        end
        
        function set.CellEditCallback(obj, value)
            obj.UITable.CellEditCallback = value;
        end
        
        function set.ButtonDownFcn(obj, value)
            obj.UITable.ButtonDownFcn = value;
        end
        
        function set.KeyPressFcn(obj, value)
            obj.UITable.KeyPressFcn = value;
        end
        
        function set.KeyReleaseFcn(obj, value)
            obj.UITable.KeyReleaseFcn = value;
        end
        
        function set.CreateFcn(obj, value)
            obj.UITable.CreateFcn = value;
        end
        
        function set.DeleteFcn(obj, value)
            obj.UITable.DeleteFcn = value;
        end
        
%         function set.CellSelectionCallback(obj, value)
%             obj.UITable.CellSelectionCallback = value;
%         end
%         
        function set.Interruptible(obj, value)
            obj.UITable.Interruptible = value;
        end
        
        function set.BusyAction(obj, value)
            obj.UITable.BusyAction = value;
        end
        
        function set.BeingDeleted(obj, value)
            obj.UITable.BeingDeleted = value;
        end
        
        function set.HitTest(obj, value)
            obj.UITable.HitTest = value;
        end
        
        function set.Parent(obj, value)
            obj.UITable.Parent = value;
        end
        
        function set.Children(obj, value)
            obj.UITable.Children = value;
        end
        
        function set.HandleVisibility(obj, value)
            obj.UITable.HandleVisibility = value;
        end
        
        function set.Type(obj, value)
            obj.UITable.Type = value;
        end
        
        function set.Tag(obj, value)
            obj.UITable.Tag = value;
        end
        
        function set.UserData(obj, value)
            obj.UITable.UserData = value;
        end
        
        function set.Extent(obj, value)
            obj.UITable.Extent = value;
        end     
    end
end