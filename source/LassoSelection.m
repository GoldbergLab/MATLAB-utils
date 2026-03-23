classdef LassoSelection < handle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LassoSelection: Interactive polygon/freehand lasso selection on axes
% usage:
%    lasso = LassoSelection(ax)
%    lasso = LassoSelection(ax, 'LineStyle', '--', 'Color', 'r')
%
% Create a LassoSelection attached to an axes. Call add_point() from a
%   figure callback (e.g., WindowButtonMotionFcn for freehand drawing, or
%   WindowButtonDownFcn for point-by-point polygon definition) to build up
%   the selection polygon interactively.
%
% When done, call get_selected(xCoords, yCoords) to get a logical mask of
%   which points fall inside the polygon.
%
% Call clear() to reset the selection for reuse, or delete the object when
%   finished.
%
% Example (freehand lasso):
%    lasso = LassoSelection(gca);
%    fig.WindowButtonDownFcn = @(~,~) startLasso();
%    fig.WindowButtonMotionFcn = @(~,evt) lasso.add_point(gca().CurrentPoint(1,1:2));
%    fig.WindowButtonUpFcn = @(~,~) finishLasso();
%
% Example (point-by-point polygon):
%    lasso = LassoSelection(gca);
%    fig.WindowButtonDownFcn = @(~,~) lasso.add_point(gca().CurrentPoint(1,1:2));
%    % ... later, when done clicking:
%    mask = lasso.get_selected(xData, yData);
%
% See also: inpolygon
%
% Version: 1.0
% Author:  Brian Kardon / Claude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (SetAccess = private)
        Axes            matlab.graphics.axis.Axes   % The axes this lasso is attached to
        Points          (:, 2) double = zeros(0, 2) % Nx2 array of [x, y] polygon vertices
        LineHandle      matlab.graphics.Graphics     % Handle to the displayed polygon line
    end

    properties
        LineStyle       (1, :) char = '--'          % Line style for the polygon outline
        LineColor                   = 'k'           % Color of the polygon outline
        LineWidth       (1, 1) double = 1.5         % Width of the polygon outline
        CloseLine       (1, 1) logical = true       % Whether to visually close the polygon
    end

    methods
        function obj = LassoSelection(ax, options)
            % Construct a LassoSelection attached to the given axes.
            %
            % Arguments:
            %   ax - The axes to draw the lasso polygon on
            %   options - Name/value pairs for line appearance:
            %       LineStyle: line style (default '--')
            %       Color: line color (default 'k')
            %       LineWidth: line width (default 1.5)
            %       CloseLine: visually close the polygon (default true)
            arguments
                ax (1, 1) matlab.graphics.axis.Axes
                options.LineStyle (1, :) char = '--'
                options.Color = 'k'
                options.LineWidth (1, 1) double = 1.5
                options.CloseLine (1, 1) logical = true
            end

            obj.Axes = ax;
            obj.LineStyle = options.LineStyle;
            obj.LineColor = options.Color;
            obj.LineWidth = options.LineWidth;
            obj.CloseLine = options.CloseLine;

            % Create the line object (initially empty) on the target axes
            holdState = ishold(ax);
            hold(ax, 'on');
            obj.LineHandle = line(ax, NaN, NaN, ...
                'LineStyle', obj.LineStyle, ...
                'Color', obj.LineColor, ...
                'LineWidth', obj.LineWidth, ...
                'PickableParts', 'none', ...
                'HitTest', 'off', ...
                'HandleVisibility', 'off');
            if ~holdState
                hold(ax, 'off');
            end
        end

        function add_point(obj, point)
            % Add a vertex to the lasso polygon and update the display.
            %
            % Arguments:
            %   point - Either a 1x2 [x, y] coordinate, or a point from
            %       axes CurrentPoint (only the first row is used).
            arguments
                obj LassoSelection
                point double
            end

            if size(point, 1) > 1
                % CurrentPoint is 2x3; take first row, first two columns
                point = point(1, 1:2);
            end

            obj.Points(end + 1, :) = point;
            obj.update_line();
        end

        function mask = get_selected(obj, xCoords, yCoords)
            % Return a logical mask indicating which coordinates fall
            %   inside the lasso polygon.
            %
            % Arguments:
            %   xCoords - vector of x coordinates to test
            %   yCoords - vector of y coordinates to test (same size as xCoords)
            %
            % Returns:
            %   mask - logical array the same size as xCoords, true where
            %       the point is inside or on the edge of the polygon
            arguments
                obj LassoSelection
                xCoords double
                yCoords double
            end

            if size(obj.Points, 1) < 3
                % Need at least 3 points to form a polygon
                mask = false(size(xCoords));
                return;
            end

            mask = inpolygon(xCoords, yCoords, obj.Points(:, 1), obj.Points(:, 2));
        end

        function clear(obj)
            % Reset the lasso, removing all points and clearing the line.
            obj.Points = zeros(0, 2);
            obj.update_line();
        end

        function delete(obj)
            % Clean up the line object when the LassoSelection is destroyed.
            if ~isempty(obj.LineHandle) && isvalid(obj.LineHandle)
                delete(obj.LineHandle);
            end
        end
    end

    methods (Access = private)
        function update_line(obj)
            % Refresh the displayed line to reflect the current points.
            if isempty(obj.Points)
                obj.LineHandle.XData = NaN;
                obj.LineHandle.YData = NaN;
                return;
            end

            xData = obj.Points(:, 1);
            yData = obj.Points(:, 2);

            % Close the polygon visually by appending the first point
            if obj.CloseLine && size(obj.Points, 1) > 1
                xData(end + 1) = xData(1);
                yData(end + 1) = yData(1);
            end

            obj.LineHandle.XData = xData;
            obj.LineHandle.YData = yData;
        end
    end
end
