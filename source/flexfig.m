classdef flexfig < handle
    % flexfig a mouse-editable wrapper for the built in figure class 
    %   
    % flexfig has the unique property of allowing the user to click and 
    %   drag to resize and reposition axes within it.
    %
    % Add an editable axes with the 
    properties (Access = private)
        IsCtrlKeyDown = false
        IsShiftKeyDown = false
    end
    properties
        MainFigure              matlab.ui.Figure                    % The main figure window
        MainPanel               matlab.ui.container.Panel           % Panel containing one or more navigation axes
        Axes                    matlab.graphics.axis.Axes           % List of movable axes
        AxesNames               cell                                % List of axes names
        GridSnap                double = 20                         % Size of snap grid in pixels
        SnapToGrid              logical = false                     % Snap to grid always on?
    end
    properties (Access = private)
        AnchorPoints            cell =   {[0.0, 0.0], [0.0, 0.5], [0.0, 1.0], [0.5, 1.0], [1.0, 1.0], [1.0, 0.5], [1.0, 0.0], [0.5, 0.0], [0.5, 0.5]}  % Axes anchor points in normalized coordinates
        AnchorXControl          cell =   {1,          1,          1,          [],         2,          2,          2,          [],         [1, 2]}
        AnchorYControl          cell =   {1,          [],         2,          2,          2,          [],         1           1,          [1, 2]}
        AnchorVisible           logical = [true,      true,       true,       true,       true,       true,       true,       true,       true]
        AnchorGrabRangeBoost    double = [1,          1,          1,          1,          1,          1,          1,          1,          3]
        AnchorIconBaseXY (2, :) double = [[1.0, 1.0, 0.0, 0.8, 1.0, 1.0, 0.6, 0.4, 1.0, 1.0, 0.0]; [0.0, 1.0, 1.0, 1.0, 0.8, 0.6, 1.0, 1.0, 0.4, 1.0, 1.0]]
        AnchorIconRotation      double = [0,          1,          2,          3,          4,          5,          6,          7,          8] * (-pi/4)
        AnchorIconOffsetX       double = [0,          0,          0,          1,          0,          0,          0,         -1,          0] / sqrt(2)
        AnchorIconOffsetY       double = [0,         -1,          0,          0,          0,          1,          0,          0,          0] / sqrt(2)
        AnchorIconXY            cell =   {}
        AnchorIconHandles       matlab.graphics.Graphics
        AnchorIconScale = 0.05
        GrabAxesIndex = []
        GrabAnchorIndex = []
        GrabAxesXControl = []
        GrabAxesYControl = []
        GrabAxesX = []
        GrabAxesY = []
        GrabAxesStartPosition = []
        GrabRange = 30 % in pixels
    end
    properties (SetObservable)
    end
    methods
        function obj = flexfig(varargin)
            % flexfig constructor - arguments are passed to figure

            % Create figure
            obj.MainFigure = figure(varargin{:}, 'Units', 'normalized');
            % Create panel within figure
            obj.MainPanel = uipanel('Units', 'normalized', 'Position', [0, 0, 1, 1], 'Parent', obj.MainFigure);
            
            % Assemble full anchor handle shape
            baseCoords = obj.AnchorIconBaseXY;
            R = [[0, 1]; [-1, 0]];
            for r = 1:3
                baseCoords = (baseCoords'*R)';
                obj.AnchorIconBaseXY = [obj.AnchorIconBaseXY, baseCoords];
            end

            % Pre-calculate rotated anchor design coordinates for each anchor point
            for anchorIdx = 1:length(obj.AnchorIconRotation)
                angle = obj.AnchorIconRotation(anchorIdx);
                rotationMatrix = [[cos(angle), -sin(angle)]; [sin(angle), cos(angle)]];
                offsetXY = rotationMatrix * [obj.AnchorIconOffsetX(anchorIdx); obj.AnchorIconOffsetY(anchorIdx)];
                obj.AnchorIconXY{anchorIdx} = rotationMatrix * (obj.AnchorIconBaseXY + offsetXY);
            end

            % Set callbacks and other properties
            obj.MainFigure.BusyAction = 'queue';
            obj.MainFigure.KeyPressFcn = @obj.KeyPressHandler;
            obj.MainFigure.KeyReleaseFcn = @obj.KeyReleaseHandler;
            obj.MainFigure.WindowButtonMotionFcn = @obj.MouseMotionHandler;
            obj.MainFigure.WindowButtonDownFcn = @obj.MouseButtonDownHandler;
            obj.MainFigure.WindowButtonUpFcn = @obj.MouseButtonUpHandler;
            obj.MainFigure.CloseRequestFcn = @(varargin)delete(obj);

        end
        function aspectRatio = getAxesBoundaryAspectRatio(obj, axesIdx)
            % Get the aspect ratio of the given axes
            arguments
                obj flexfig
                axesIdx (1, 1) double
            end
            ax = obj.Axes(axesIdx);
            position = flexfig.getPositionInUnits(ax, 'pixels');
            aspectRatio = position(3) / position(4);
        end
        function pixelsPerDataUnit = getPixelsPerDataUnit(obj, axesIdx)
            % Find the number of pixels per data unit in both x and y
            % dimensions
            arguments
                obj flexfig
                axesIdx (1, 1) double
            end
            ax = obj.Axes(axesIdx);
            position = flexfig.getPositionInUnits(ax, 'pixels');
            pixelsPerDataUnit = position(3:4) ./ [diff(xlim(ax)), diff(ylim(ax))];
        end
        function tileAxes(obj, tileSize, margin, snapToGrid)
            % Arrange axes in a tiled pattern
            arguments
                obj flexfig
                tileSize (1, 2) double                  % 2-vector containing the x and y size of the desired axes grid
                margin (1, 1) double = obj.GridSnap;    % Size in pixels of the margin between axes
                snapToGrid (1, 1) logical = true        % Snap the tiled positions to the grid? If true, for best results, margin should be a multiple of obj.GridSnap
            end
            % Create tile coordinates
            [xTiles, yTiles] = ndgrid(1:tileSize(1), 1:tileSize(2));

            % Calculate size of axes
            obj.MainFigure.Units = 'pixels';
            effectiveFigureSize = obj.MainFigure.Position(3:4) - margin * (tileSize + 1);
            axesSize = effectiveFigureSize ./ tileSize;

            numAxes = length(obj.Axes);
            for axesIdx = 1:numAxes
                if axesIdx > numel(xTiles)
                    % Ran out of spaces in tiling
                    break;
                end

                % Determine coordinates of each axes according to the grid
                % size
                obj.Axes(axesIdx).Units = 'pixels';
                x = (xTiles(axesIdx) - 1) * axesSize(1) + xTiles(axesIdx) * margin;
                y = yTiles(axesIdx) * axesSize(2) + yTiles(axesIdx) * margin;
                y = obj.MainFigure.Position(4) - y;
                tiledPosition = [x, y, axesSize];
                if snapToGrid
                    [tiledPosition([1, 3]), tiledPosition([2, 4])] = snapFigCoords(obj, tiledPosition([1, 3]), tiledPosition([2, 4]));
                end

                % Set axes position
                obj.Axes(axesIdx).Position = tiledPosition;
                obj.Axes(axesIdx).Units = 'normalized';
            end
            obj.MainFigure.Units = 'normalized';
        end
        function anchorHandle = drawAnchor(obj, axesIdx, anchorIdx)
            % Draw an anchor handle to indicate a draggable point
            arguments
                obj flexfig
                axesIdx (1, 1) double
                anchorIdx (1, 1) double
            end
            ax = obj.Axes(axesIdx);
            holdState = ishold(ax);
            ax.XLimMode = 'manual';
            ax.YLimMode = 'manual';
            hold(ax, 'on');

            pixelsPerDataUnit = getPixelsPerDataUnit(obj, axesIdx);
            x = obj.AnchorIconXY{anchorIdx}(1, :);
            y = obj.AnchorIconXY{anchorIdx}(2, :);
            sizeAdjustment = 0.8;
            x = sizeAdjustment * x * obj.GrabRange / pixelsPerDataUnit(1);
            y = sizeAdjustment * y * obj.GrabRange / pixelsPerDataUnit(2);
            xl = xlim(ax);
            yl = ylim(ax);
            x = (x + obj.AnchorPoints{anchorIdx}(1) * diff(xl)) + xl(1);
            y = (y + obj.AnchorPoints{anchorIdx}(2) * diff(yl)) + yl(1);
            anchorHandle = line(ax, x, y, 'PickableParts', 'none', 'HitTest', 'off', 'Color', 'k');
            if holdState
                hold(ax, 'on');
            else
                hold(ax, 'off');
            end
        end
        function addAxes(obj, axesName, varargin)
            % Add a new resizable axes
            arguments
                obj flexfig
                axesName char = obj.getUniqueAxesName('axes');
            end
            arguments (Repeating)
                varargin            % Pass in extra arguments to axes constructor
            end

            % Don't let user change axes units
            unitsArgumentPosition = find(strcmp('Units', varargin));
            if ~isempty(unitsArgumentPosition)
                varargin(unitsArgumentPosition:unitsArgumentPosition+1) = [];
            end
            sourceAxesArgumentPosition = find(strcmp('SourceAxes', varargin));
            if ~isempty(sourceAxesArgumentPosition)
                sourceAxes = varargin{sourceAxesArgumentPosition+1};
                copiedAxes = copyobj(sourceAxes, obj.MainPanel);
                varargin(sourceAxesArgumentPosition:sourceAxesArgumentPosition+1) = [];
            else
                copiedAxes = gobjects().empty;
            end

            newAxesIdx = length(obj.Axes) + 1;

            if isempty(copiedAxes)
                obj.Axes(newAxesIdx) = axes(obj.MainPanel, 'Units', 'normalized', varargin{:});
            else
                copiedAxes.Units = 'normalized';
                obj.Axes(newAxesIdx) = copiedAxes;
            end
            obj.AxesNames{newAxesIdx} = axesName;
            obj.AnchorIconHandles(newAxesIdx) = gobjects();
        end
        function axesName = getUniqueAxesName(obj, startingAxesName)
            % Get a unique name for the given starting name, to ensure no
            % two axes have the same name
            arguments
                obj flexfig
                startingAxesName (1, :) char
            end
            trailingNumberIndices = regexp(startingAxesName, '([0-9]+)$', 'tokenExtents');
            if ~isempty(trailingNumberIndices)
                startNumeral = str2double(startingAxesName(trailingNumberIndices(1):trailingNumberIndices(2)));
                startingAxesName(trailingNumberIndices(1):trailingNumberIndices(2)) = [];
            else
                startNumeral = 1;
            end
            numeral = startNumeral;
            while true
                axesName = sprintf('%s_%03d', startingAxesName, numeral);
                if ~any(strcmp(axesName, obj.AxesNames))
                    break;
                end
                numeral = numeral + 1;
            end            
        end
        function ax = getElementAxes(obj, axesIdxOrName)
            % Get the handle to an axes based on an index or name
            arguments
                obj flexfig
                axesIdxOrName       % Either an axes index or an axes name
            end
            if ischar(axesIdxOrName)
                axesIndex = obj.getAxesIndexFromName(axesIdxOrName);
            else
                axesIndex = axesIdxOrName;
            end

            ax = obj.Axes(axesIndex);
        end
        function axesIndex = getAxesIndexFromName(obj, axesName)
            % Find the axes index based on the axes name
            arguments
                obj flexfig
                axesName (1, :) char
            end
            axesIndex = find(strcmp(obj.AxesNames, axesName), 1);
        end
        function destroyAxes(obj, axesIdxOrName)
            % Delete one of the axes based on its index or name
            arguments
                obj flexfig
                axesIdxOrName
            end
            if ischar(axesIdxOrName)
                axesIndex = obj.getAxesIndexFromName(axesIdxOrName);
            else
                axesIndex = axesIdxOrName;
            end

            delete(obj.Axes(axesIndex));
            obj.Axes(axesIndex) = [];
            obj.AxesNames(axesIndex) = [];
        end
        function [xAx, yAx] = mapFigureToAxesCoordinates(obj, axesIdx, xFig, yFig)
            % Transform figure coordinates to axes coordinates for the
            % specified axes index
            arguments
                obj flexfig
                axesIdx (1, 1) double
                xFig (1, :) double
                yFig (1, :) double
            end
            ax = obj.Axes(axesIdx);
            axesPosition = getWidgetFigurePosition(ax, 'normalized');
            xAx = (xFig - axesPosition(1)) / axesPosition(3);
            yAx = (yFig - axesPosition(2)) / axesPosition(4);
        end
        function [xAx, yAx, inAxes] = getAxesPositions(obj, xFig, yFig, firstInside)
            % Transform the given figure coordinates to the axes
            % coordinates for one or more of the axes. If firstInside is
            % true, only return the coordinates for the first axes that the
            % given coordinates fall inside of.
            arguments
                obj flexfig
                xFig (1, 1) double
                yFig (1, 1) double
                firstInside (1, 1) logical = false
            end
            numAxes = length(obj.Axes);

            if ~firstInside
                % Append all axes-based positions and inside boolean
                xAx = zeros(1, numAxes);
                yAx = zeros(1, numAxes);
                inAxes = false(1, numAxes);
            else
                % Only supply axes-based positions for the first axes found
                % to contain the given coordinates
                xAx = [];
                yAx = [];
                inAxes = false;
            end

            for axesIdx = numAxes:-1:1
                [thisXAx, thisYAx] = obj.mapFigureToAxesCoordinates(axesIdx, xFig, yFig);
                thisInAxes = thisXAx >= 0 && thisXAx <= 1 && thisYAx >= 0 && thisYAx <= 1;
                if firstInside
                    if thisInAxes
                        % Stop here
                        xAx = thisXAx;
                        yAx = thisYAx;
                        inAxes = axesIdx;
                        break;
                    end
                else
                    % Append this axes-based coordinates and inside boolean
                    xAx(axesIdx) = thisXAx;
                    yAx(axesIdx) = thisYAx;
                    inAxes(axesIdx) = thisInAxes;
                end

            end
        end
        function anchorIdx = getAnchorInRange(obj, axesIdx, xAx, yAx)
            % Get the anchor index of the first anchor found in range of
            % the given coordinates for the given axes
            arguments
                obj flexfig
                axesIdx (1, 1) double
                xAx (1, 1) double
                yAx (1, 1) double
            end
            ax = obj.Axes(axesIdx);
            axPosition = flexfig.getPositionInUnits(ax, 'pixels');
            xAxPix = axPosition(1) + xAx * axPosition(3);
            yAxPix = axPosition(2) + yAx * axPosition(4);
            foundAnchorInRange = false;
            for anchorIdx = 1:length(obj.AnchorPoints)
                anchorPoint = obj.AnchorPoints{anchorIdx};
                xAnchorPix = axPosition(1) + anchorPoint(1) * axPosition(3);
                yAnchorPix = axPosition(2) + anchorPoint(2) * axPosition(4);
                if ((xAxPix-xAnchorPix)^2 + (yAxPix-yAnchorPix)^2) <= (obj.GrabRange * obj.AnchorGrabRangeBoost(anchorIdx))^2
                    foundAnchorInRange = true;
                    break;
                end
            end
            if ~foundAnchorInRange
                anchorIdx = [];
            end
        end
        function MouseMotionHandler(obj, ~, ~)
            % Respond to mouse motion
            arguments
                obj flexfig
                ~
                ~
            end
            [xFig, yFig] = obj.getFigureCoordinates();
            [xAx, yAx, inAxes] = obj.getAxesPositions(xFig, yFig);

            if ~isempty(obj.GrabAxesIndex)
                ax = obj.Axes(obj.GrabAxesIndex);
                axXCoords = [ax.Position(1), ax.Position(1) + ax.Position(3)];
                axYCoords = [ax.Position(2), ax.Position(2) + ax.Position(4)];
                startXCoords = [obj.GrabAxesStartPosition(1), obj.GrabAxesStartPosition(1) + obj.GrabAxesStartPosition(3)];
                startYCoords = [obj.GrabAxesStartPosition(2), obj.GrabAxesStartPosition(2) + obj.GrabAxesStartPosition(4)];
                if ~isempty(obj.GrabAxesXControl)
                    deltaX = xFig - obj.GrabAxesX;
                    axXCoords(obj.GrabAxesXControl) = startXCoords(obj.GrabAxesXControl) + deltaX;
                    axXCoords = sort(axXCoords);
                end
                if ~isempty(obj.GrabAxesYControl)
                    deltaY = yFig - obj.GrabAxesY;
                    axYCoords(obj.GrabAxesYControl) = startYCoords(obj.GrabAxesYControl) + deltaY;
                    axYCoords = sort(axYCoords);
                end

                if obj.IsShiftKeyDown || obj.SnapToGrid
                    [axXCoords, axYCoords] = obj.snapFigCoords(axXCoords, axYCoords);
                end
                
                ax.Position = [axXCoords(1), axYCoords(1), abs(diff(axXCoords)), abs(diff(axYCoords))];
            end

            for axesIdx = find(inAxes)
                % Loop over any axes we are inside
                if obj.IsCtrlKeyDown
                    anchorIdxInRange = obj.getAnchorInRange(axesIdx, xAx(axesIdx), yAx(axesIdx));
                    if ~isempty(anchorIdxInRange)
                        delete(obj.AnchorIconHandles(axesIdx));
                        if obj.AnchorVisible(anchorIdxInRange)
                            obj.AnchorIconHandles(axesIdx) = obj.drawAnchor(axesIdx, anchorIdxInRange);
                        end
                    else
                        delete(obj.AnchorIconHandles(axesIdx));
                    end
                else
                    delete(obj.AnchorIconHandles(axesIdx));
                end
            end
            for axesIdx = find(~inAxes)
                delete(obj.AnchorIconHandles(axesIdx));
            end
        end
        function [xFig, yFig] = getFigureCoordinates(obj)
            % Get the current figure coordinates of the mouse pointer
            arguments
                obj flexfig
            end
            xFig = obj.MainFigure.CurrentPoint(1, 1);
            yFig = obj.MainFigure.CurrentPoint(1, 2);
        end
        
        function [xSnap, ySnap] = snapFigCoords(obj, xFig, yFig)
            % Snap the given figure coordinates to the nearest grid point
            arguments
                obj flexfig
                xFig (:, :) double
                yFig (:, :) double
            end
            position = flexfig.getPositionInUnits(obj.MainFigure, 'pixels');
            w = position(3);
            h = position(4);
            xSnap = round(xFig*w / obj.GridSnap) * obj.GridSnap / w;
            ySnap = round(yFig*h / obj.GridSnap) * obj.GridSnap / h;
        end

        function MouseButtonDownHandler(obj, ~, ~)
            % Handle mouse button presses
            arguments
                obj flexfig
                ~
                ~
            end
            [xFig, yFig] = obj.getFigureCoordinates();
            
            if obj.IsCtrlKeyDown
                [xAx, yAx, axesIdx] = obj.getAxesPositions(xFig, yFig, true);
                if axesIdx
                    % User clicked inside one of the axes
                    clickedAxesIdx = axesIdx;
                    anchorIdx = obj.getAnchorInRange(clickedAxesIdx, xAx, yAx);
                    if ~isempty(anchorIdx)
                        % User clicked in range of the axes' grab anchors
                        obj.updateAxesGrabPoint(xFig, yFig, clickedAxesIdx, anchorIdx);
                    end
                end
            end
        end

        function updateAxesGrabPoint(obj, xFig, yFig, axesIdx, anchorIdx)
            arguments
                obj flexfig
                xFig (1, :) double
                yFig (1, :) double
                axesIdx double = obj.GrabAxesIndex
                anchorIdx double = []
            end
            if ~isempty(axesIdx)
                obj.GrabAxesIndex = axesIdx;
            end
            if ~isempty(anchorIdx)
                obj.GrabAnchorIndex = anchorIdx;
                obj.GrabAxesXControl = obj.AnchorXControl{anchorIdx};
                obj.GrabAxesYControl = obj.AnchorYControl{anchorIdx};
            end
            if ~isempty(axesIdx)
                obj.GrabAxesStartPosition = obj.Axes(axesIdx).Position;
                obj.GrabAxesX = xFig;
                obj.GrabAxesY = yFig;
            end
        end
        function MouseButtonUpHandler(obj, ~, ~)
            % Handle mouse button releases
            arguments
                obj flexfig
                ~
                ~
            end
            obj.GrabAxesIndex = [];
            obj.GrabAnchorIndex = [];
            obj.GrabAxesXControl = [];
            obj.GrabAxesYControl = [];
            obj.GrabAxesX = [];
            obj.GrabAxesY = [];
        end
        
        function KeyPressHandler(obj, ~, event)
            % Handle key presses
            arguments
                obj flexfig
                ~
                event matlab.ui.eventdata.KeyData
            end
            switch event.Key
                case 'shift'
                    obj.IsShiftKeyDown = true;
                case 'control'
                    obj.IsCtrlKeyDown = true;
            end
        end
        function KeyReleaseHandler(obj, ~, event)
            % Handle key releases
            arguments
                obj flexfig
                ~
                event matlab.ui.eventdata.KeyData
            end
            switch event.Key
                case 'shift'
                    obj.IsShiftKeyDown = false;
                case 'control'
                    obj.IsCtrlKeyDown = false;
            end
        end
        function set.Axes(obj, newAxes)
            % Handle user settings obj.Axes (ensure axes units are
            % normalized)
            for k = 1:length(newAxes)
                if ~strcmp('normalized', newAxes(k).Units)
                    newAxes(k).Units = 'normalized';
                    warning('Axes Units property must remain ''normalized''');
                end
            end
            obj.Axes = newAxes;
        end
        function delete(obj)
            delete(obj.MainFigure);
        end
    end
    methods (Static)
        function position = getPositionInUnits(widget, units)
            arguments
                widget matlab.graphics.Graphics
                units char
            end
            originalUnits = widget.Units;
            widget.Units = units;
            position = widget.Position;
            widget.Units = originalUnits;
        end
    end
end