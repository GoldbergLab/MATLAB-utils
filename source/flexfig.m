classdef flexfig < handle
    % flexfig a mouse-editable wrapper for the built in figure class 
    %   
    % flexfig has the unique property of allowing the user to click and 
    %   drag to resize and reposition axes within it.
    %
    % Add an editable axes with the 
    properties (Access = protected)
    end
    properties
        Figure                  matlab.ui.Figure                    % The main figure window
        GridSize                double = 20                         % Size of snap grid in pixels
        SnapToGrid              logical = false                     % Snap to grid always on?
        SnapToAxes              logical = false
    end
    properties (Access = protected)
        AnchorPoints            cell =   {[0.0, 0.0], [0.0, 0.5], [0.0, 1.0], [0.5, 1.0], [1.0, 1.0], [1.0, 0.5], [1.0, 0.0], [0.5, 0.0], [0.5, 0.5]}  % Axes anchor points in normalized coordinates
        AnchorXControl          cell =   {1,          1,          1,          [],         2,          2,          2,          [],         [1, 2]}
        AnchorYControl          cell =   {1,          [],         2,          2,          2,          [],         1           1,          [1, 2]}
        AnchorGrabRangeBoost    double = [1,          1,          1,          1,          1,          1,          1,          1,          inf]
        AnchorPointer           cell =   {'botl',     'left',     'topl',     'top',      'topr',     'right',    'botr',     'bottom',   'fleur'}
        GrabAxes = gobjects().empty
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
            if ~isempty(varargin) && isa(varargin{1}, 'matlab.ui.Figure')
                obj.Figure = varargin{1};
                varargin{1} = [];
            end
            [snapToGrid, found, varargin] = flexfig.extractNameValue(varargin, 'SnapToGrid');
            if found
                obj.SnapToGrid = snapToGrid;
            end
            [gridSize, found, varargin] = flexfig.extractNameValue(varargin, 'GridSize');
            if isempty(obj.Figure)
                if found
                    obj.GridSize = gridSize;
                end
                [fig, found, varargin] = flexfig.extractNameValue(varargin, 'Figure');
                if found
                    % Use figure passed in by user
                    obj.Figure = fig;
                else
                    % Create figure
                    obj.Figure = figure(varargin{:}, 'Units', 'normalized');
                end
            end

            % Set callbacks and other properties
            obj.Figure.BusyAction = 'queue';
            obj.Figure.KeyPressFcn = @obj.KeyPressHandler;
            obj.Figure.KeyReleaseFcn = @obj.KeyReleaseHandler;
            obj.Figure.WindowButtonMotionFcn = @obj.MouseMotionHandler;
            obj.Figure.WindowButtonDownFcn = @obj.MouseButtonDownHandler;
            obj.Figure.WindowButtonUpFcn = @obj.MouseButtonUpHandler;
            obj.Figure.CloseRequestFcn = @(varargin)delete(obj);

        end
        function TileAxes(obj, tileSize, margin, snapToGrid)
            % Arrange axes in a tiled pattern
            arguments
                obj flexfig
                tileSize (1, 2) double                          % 2-vector containing the x and y size of the desired axes grid
                margin (1, 1) double = obj.GridSize;            % Size in pixels of the margin between axes
                snapToGrid (1, 1) logical = obj.SnapToGrid      % Snap the tiled positions to the grid? If true, for best results, margin should be a multiple of obj.GridSnap
            end
            % Create tile coordinates
            [xTiles, yTiles] = ndgrid(1:tileSize(1), 1:tileSize(2));

            % Calculate size of axes
            obj.Figure.Units = 'pixels';
            effectiveFigureSize = obj.Figure.Position(3:4) - margin * (tileSize + 1);
            axesSize = effectiveFigureSize ./ tileSize;

            axesList = obj.getAxesList();
            numAxes = length(axesList);
            for axesIdx = 1:numAxes
                if axesIdx > numel(xTiles)
                    % Ran out of spaces in tiling
                    break;
                end

                % Determine coordinates of each axes according to the grid
                % size
                axesList(axesIdx).Units = 'pixels';
                x = (xTiles(axesIdx) - 1) * axesSize(1) + xTiles(axesIdx) * margin;
                y = yTiles(axesIdx) * axesSize(2) + yTiles(axesIdx) * margin;
                y = obj.Figure.Position(4) - y;
                tiledPosition = [x, y, axesSize];
                if snapToGrid
                    [tiledPosition([1, 3]), tiledPosition([2, 4])] = snapFigCoords(obj, tiledPosition([1, 3]), tiledPosition([2, 4]));
                end

                % Set axes position
                axesList(axesIdx).Position = tiledPosition;
                axesList(axesIdx).Units = 'normalized';
            end
            obj.Figure.Units = 'normalized';
        end
        function code = GenerateCode(obj, filename)
            arguments
                obj flexfig
                filename char = ''
            end
            axesList = obj.getAxesList();
            positions = vertcat(axesList.Position);
            [~, sortIdx] = sortrows(positions(:, 1:2));
            axesList = axesList(sortIdx);

            code = {};
            code{end+1} = sprintf('%% Figure layout code, automatically generated by flexfig on %s', datetime());
            code{end+1} = '';
            code{end+1} = '%% Create figure';
            code{end+1} = 'f = figure(''Units'', ''normalized'');';
            code{end+1} = '%% Initialize empty list of axes';
            code{end+1} = 'ax = gobjects().empty;';
            code{end+1} = '%% Create each axes and position it';
            for k = 1:length(axesList)
                p = num2cell(axesList(k).Position);
                code{end+1} = sprintf('ax(%d) = axes(f, ''Position'', [%f, %f, %f, %f]);', k, p{:}); %#ok<AGROW>
            end
            if ~isempty(filename)
                fileID = fopen(filename, 'w');
                for k = 1:length(code)
                    fprintf(fileID, '%s\r\n', code{k});
                end
                fclose(fileID);
                edit(filename);
            end
        end
        function delete(obj)
            delete(obj.Figure);
        end
    end
    methods (Access = protected)
        function axesList = getAxesList(obj)
            axesMask = arrayfun(@(g)isa(g, 'matlab.graphics.axis.Axes'), obj.Figure.Children);
            axesList = obj.Figure.Children(axesMask);
        end
        function axesIdx = getAxesIdx(obj, ax)
            arguments
                obj flexfig
                ax (1, 1) matlab.graphics.axis.Axes
            end
            axesList = obj.getAxesList();
            axesIdx = find(ax == axesList, 1);
        end
        function setPointer(obj, pointerShape)
            % Set the mouse pointer
            arguments
                obj flexfig
                pointerShape char = 'arrow'
            end
            obj.Figure.Pointer = pointerShape;
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
            axesList = obj.getAxesList();
            numAxes = length(axesList);

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
                [thisXAx, thisYAx] = flexfig.mapFigureToAxesCoordinates(axesList(axesIdx), xFig, yFig);
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
        function anchorIdx = getAnchorInRange(obj, ax, xAx, yAx)
            % Get the anchor index of the closest anchor found in range of
            % the given coordinates for the given axes
            arguments
                obj flexfig
                ax (1, 1) matlab.graphics.axis.Axes
                xAx (1, 1) double
                yAx (1, 1) double
            end
            axPosition = flexfig.getPositionInUnits(ax, 'pixels');
            xAxPix = axPosition(1) + xAx * axPosition(3);
            yAxPix = axPosition(2) + yAx * axPosition(4);
            idxInRange = [];
            distInRange = [];
            for anchorIdx = 1:length(obj.AnchorPoints)
                anchorPoint = obj.AnchorPoints{anchorIdx};
                xAnchorPix = axPosition(1) + anchorPoint(1) * axPosition(3);
                yAnchorPix = axPosition(2) + anchorPoint(2) * axPosition(4);
                dist = (xAxPix-xAnchorPix)^2 + (yAxPix-yAnchorPix)^2;
                if dist <= (obj.GrabRange * obj.AnchorGrabRangeBoost(anchorIdx))^2
                    idxInRange = [idxInRange, anchorIdx];       %#ok<AGROW> 
                    distInRange = [distInRange, dist];          %#ok<AGROW> 
                end
            end
            [~, closestIdx] = min(distInRange);
            anchorIdx = idxInRange(closestIdx);
        end
        function controlDown = isControlDown(obj)
            controlDown = any(strcmp(obj.Figure.CurrentModifier, 'control'));
        end
        function shiftDown = isShiftDown(obj)
            shiftDown = any(strcmp(obj.Figure.CurrentModifier, 'shift'));
        end
        function altDown = isAltDown(obj)
            altDown = any(strcmp(obj.Figure.CurrentModifier, 'alt'));
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

            axesList = obj.getAxesList();

            if ~isempty(obj.GrabAxes)
                ax = obj.GrabAxes;
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

                if obj.isShiftDown() || obj.SnapToGrid || obj.SnapToAxes
                    [axXCoords, axYCoords] = obj.snapFigCoords(axXCoords, axYCoords, obj.SnapToGrid || obj.isShiftDown(), obj.SnapToAxes || obj.isShiftDown());
                end
                
                ax.Position = [axXCoords(1), axYCoords(1), abs(diff(axXCoords)), abs(diff(axYCoords))];
            else
                for axesIdx = 1:length(axesList)
                    axesList(axesIdx).XLimMode = 'manual';
                    axesList(axesIdx).YLimMode = 'manual';
                end
                obj.updatePointer();
            end
        end
        function updatePointer(obj)
            if ~obj.isControlDown()
                obj.setPointer();
                return;
            end
            [xFig, yFig] = obj.getFigureCoordinates();
            [xAx, yAx, inAxes] = obj.getAxesPositions(xFig, yFig);
            anchorIdxInRange = [];
            axesList = obj.getAxesList();
            for axesIdx = find(inAxes)
                % Loop over any axes we are inside
                anchorIdxInRange = obj.getAnchorInRange(axesList(axesIdx), xAx(axesIdx), yAx(axesIdx));
                if ~isempty(anchorIdxInRange)
                    break;
                end
            end
            if ~isempty(anchorIdxInRange)
                obj.setPointer(obj.AnchorPointer{anchorIdxInRange});
            else
                obj.setPointer();
            end
        end
        function [xFig, yFig] = getFigureCoordinates(obj)
            % Get the current figure coordinates of the mouse pointer
            arguments
                obj flexfig
            end
            originalUnits = obj.Figure.Units;
            obj.Figure.Units = 'normalized';
            xFig = obj.Figure.CurrentPoint(1, 1);
            yFig = obj.Figure.CurrentPoint(1, 2);
            obj.Figure.Units = originalUnits;

        end
        function [xSnaps, ySnaps] = snapFigCoords(obj, xFigs, yFigs, snapToGrid, snapToAxes)
            % Snap the given figure coordinates to the nearest grid point
            arguments
                obj flexfig
                xFigs (1, :) double
                yFigs (1, :) double
                snapToGrid (1, 1) logical = obj.SnapToGrid
                snapToAxes (1, 1) logical = obj.SnapToAxes
            end
            position = flexfig.getPositionInUnits(obj.Figure, 'pixels');
            w = position(3);
            h = position(4);
            xSnaps = xFigs;
            ySnaps = yFigs;
            if snapToGrid
                xSnaps = round(xFigs * w / obj.GridSize) * obj.GridSize / w;
                ySnaps = round(yFigs * h / obj.GridSize) * obj.GridSize / h;
            end
            if snapToAxes
                axesList = obj.getAxesList();
                positions = vertcat(axesList.Position);
                if ~isempty(positions)
                    xGuides = [positions(:, 1); positions(:, 1) + positions(:, 3)];
                    yGuides = [positions(:, 2); positions(:, 2) + positions(:, 4)];
                    for k = 1:length(xFigs)
                        xFig = xFigs(k);
                        yFig = yFigs(k);
                        [minXDist, minXIdx] = min(abs(xGuides - xFig));
                        [minYDist, minYIdx] = min(abs(yGuides - yFig));
                        if snapToGrid
                            xGridDist = abs(xSnaps(k) - xFig);
                            yGridDist = abs(ySnaps(k) - yFig);
                        end
                        if (~snapToGrid || minXDist < xGridDist) && minXDist < (obj.GridSize/w)
                            xSnaps(k) = xGuides(minXIdx);
                        end
                        if (~snapToGrid || minYDist < yGridDist) && minYDist < (obj.GridSize/h)
                            ySnaps(k) = yGuides(minYIdx);
                        end
                    end
                end
            end
        end
        function MouseButtonDownHandler(obj, ~, ~)
            % Handle mouse button presses
            arguments
                obj flexfig
                ~
                ~
            end
            [xFig, yFig] = obj.getFigureCoordinates();
            
            axesList = obj.getAxesList();

            if obj.isControlDown()
                [xAx, yAx, axesIdx] = obj.getAxesPositions(xFig, yFig, true);
                if axesIdx
                    % User clicked inside one of the axes
                    clickedAxes = axesList(axesIdx);
                    anchorIdx = obj.getAnchorInRange(clickedAxes, xAx, yAx);
                    if ~isempty(anchorIdx)
                        % User clicked in range of the axes' grab anchors
                        obj.updateAxesGrabPoint(xFig, yFig, clickedAxes, anchorIdx);
                    end
                end
            else
                if obj.isAltDown()
                    ax = axes('Position', [xFig, yFig, 0, 0], 'Parent', obj.Figure);
                    anchorIdx = 7;  % Bottom right anchor
                    obj.updateAxesGrabPoint(xFig, yFig, ax, anchorIdx);
                end
            end
        end
        function updateAxesGrabPoint(obj, xFig, yFig, ax, anchorIdx)
            arguments
                obj flexfig
                xFig (1, :) double
                yFig (1, :) double
                ax (1, 1) matlab.graphics.axis.Axes = obj.GrabAxes
                anchorIdx double = []
            end
            if ~isempty(ax)
                obj.GrabAxes = ax;
                obj.Figure.CurrentAxes = ax;
                % Rearrange figure Children to put the grabbed axes on top
                grabAxesIdx = obj.getAxesIdx(ax);
                obj.Figure.Children([1, grabAxesIdx]) = obj.Figure.Children([grabAxesIdx, 1]);
            end
            if ~isempty(anchorIdx)
                obj.GrabAnchorIndex = anchorIdx;
                obj.GrabAxesXControl = obj.AnchorXControl{anchorIdx};
                obj.GrabAxesYControl = obj.AnchorYControl{anchorIdx};
            end
            if ~isempty(ax)
                obj.GrabAxesStartPosition = ax.Position;
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
            obj.endGrab();
        end
        function endGrab(obj)
            obj.GrabAxes = gobjects().empty;
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
                case 'escape'
                    if ~isempty(obj.GrabAxes)
                        delete(obj.GrabAxes);
                        obj.endGrab();
                    end
            end
            obj.updatePointer();
        end
        function KeyReleaseHandler(obj, ~, event)
            % Handle key releases
            arguments
                obj flexfig
                ~
                event matlab.ui.eventdata.KeyData
            end
            switch event.Key
            end
            obj.updatePointer();
        end
    end
    methods (Static, Access = protected)
        function [xAx, yAx] = mapFigureToAxesCoordinates(ax, xFig, yFig)
            % Transform figure coordinates to axes coordinates for the
            % specified axes index
            arguments
                ax (1, 1) matlab.graphics.axis.Axes
                xFig (1, :) double
                yFig (1, :) double
            end
            axesPosition = getWidgetFigurePosition(ax, 'normalized');
            xAx = (xFig - axesPosition(1)) / axesPosition(3);
            yAx = (yFig - axesPosition(2)) / axesPosition(4);
        end
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
        function aspectRatio = getAxesBoundaryAspectRatio(ax)
            % Get the aspect ratio of the given axes
            arguments
                ax (1, 1) matlab.graphics.axis.Axes
            end
            position = flexfig.getPositionInUnits(ax, 'pixels');
            aspectRatio = position(3) / position(4);
        end
        function pixelsPerDataUnit = getPixelsPerDataUnit(ax)
            % Find the number of pixels per data unit in both x and y
            % dimensions
            arguments
                ax (1, 1) matlab.graphics.axis.Axes
            end
            position = flexfig.getPositionInUnits(ax, 'pixels');
            pixelsPerDataUnit = position(3:4) ./ [diff(xlim(ax)), diff(ylim(ax))];
        end
        function [value, found, args] = extractNameValue(args, name)
            idx = find(strcmp(name, args), 1);
            if isempty(idx)
                value = [];
                found = false;
            else
                value = args{idx+1};
                found = true;
                args(idx:idx+1) = [];
            end
        end
    end
end