function tileChildren(parent, tileSize, margin)
    % Arrange children in a figure in a tiled pattern
    arguments
        parent
        tileSize (1, 2) double                          % 2-vector containing the x and y size of the desired axes grid
        margin (1, 1) double = 10;                      % Size in pixels of the margin between widgets
    end
    % Create tile coordinates
    [xTiles, yTiles] = ndgrid(1:tileSize(1), 1:tileSize(2));

    % Calculate size of axes
    originalParentUnits = parent.Units;
    parent.Units = 'pixels';
    effectiveParentSize = parent.Position(3:4) - margin * (tileSize + 1);
    axesSize = effectiveParentSize ./ tileSize;

    numChildren = length(parent.Children);
    for childIdx = 1:numChildren
        if childIdx > numel(xTiles)
            % Ran out of spaces in tiling
            break;
        end

        % Determine coordinates of each axes according to the grid
        % size
        originalUnits = parent.Children(childIdx).Units;
        parent.Children(childIdx).Units = 'pixels';
        x = (xTiles(childIdx) - 1) * axesSize(1) + xTiles(childIdx) * margin;
        y = yTiles(childIdx) * axesSize(2) + yTiles(childIdx) * margin;
        y = parent.Position(4) - y;
        tiledPosition = [x, y, axesSize];

        % Set axes position
        parent.Children(childIdx).Position = tiledPosition;
        parent.Children(childIdx).Units = originalUnits;
    end
    parent.Units = originalParentUnits;
end