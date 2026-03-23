function demo_LassoSelection()
% demo_LassoSelection
%   Interactive demo of the LassoSelection class.
%
%   Click and drag on the scatter plot to draw a freehand lasso around
%   points. When you release the mouse button, points inside the lasso are
%   highlighted in red. Click and drag again to make a new selection.

%% Create some test data with three clusters
rng(42);
cluster1_x = randn(80, 1) * 0.6 + 2;
cluster1_y = randn(80, 1) * 0.6 + 3;
cluster2_x = randn(80, 1) * 0.8 + 6;
cluster2_y = randn(80, 1) * 0.4 + 5;
cluster3_x = randn(80, 1) * 0.5 + 4;
cluster3_y = randn(80, 1) * 0.7 + 1;

xData = [cluster1_x; cluster2_x; cluster3_x];
yData = [cluster1_y; cluster2_y; cluster3_y];

%% Set up the figure and scatter plot
fig = figure('Name', 'LassoSelection Demo', 'NumberTitle', 'off');
ax = axes(fig);
scatter(ax, xData, yData, 25, [0.5 0.5 0.5], 'filled');
hold(ax, 'on');
highlightScatter = scatter(ax, NaN, NaN, 40, 'r', 'filled');
hold(ax, 'off');
title(ax, 'Click and drag to lasso-select points');
xlabel(ax, 'X');
ylabel(ax, 'Y');

%% Create the lasso
lasso = LassoSelection(ax, 'Color', [0.2 0.6 1.0], 'LineWidth', 2);

%% Wire up mouse callbacks for freehand drawing
isDrawing = false;

fig.WindowButtonDownFcn = @(~, ~) startDrawing();
fig.WindowButtonMotionFcn = @(~, ~) continueDrawing();
fig.WindowButtonUpFcn = @(~, ~) finishDrawing();

%% Callback functions (nested — share workspace with parent function)
    function startDrawing()
        isDrawing = true;

        % Clear previous selection
        lasso.clear();
        highlightScatter.XData = NaN;
        highlightScatter.YData = NaN;
        title(ax, 'Drawing...');

        % Add the first point
        point = ax.CurrentPoint(1, 1:2);
        lasso.add_point(point);
    end

    function continueDrawing()
        if ~isDrawing
            return;
        end
        point = ax.CurrentPoint(1, 1:2);
        lasso.add_point(point);
    end

    function finishDrawing()
        if ~isDrawing
            return;
        end
        isDrawing = false;

        % Find which points are inside the lasso
        mask = lasso.get_selected(xData, yData);
        numSelected = sum(mask);

        % Update highlight scatter
        if numSelected > 0
            highlightScatter.XData = xData(mask);
            highlightScatter.YData = yData(mask);
        else
            highlightScatter.XData = NaN;
            highlightScatter.YData = NaN;
        end

        title(ax, sprintf('Selected %d of %d points  —  drag again to re-select', ...
            numSelected, length(xData)));
    end
end
