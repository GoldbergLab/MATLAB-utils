function tileChildren(parent, tileSize, margin, preserveAspectRatio)
    % Arrange children of a container in a tiled pattern
    arguments
        parent
        tileSize (1, 2) double                          % 2-vector containing the x and y size of the desired axes grid
        margin (1, 1) double = 10;                      % Size in pixels of the margin between widgets
        preserveAspectRatio (1, 1) logical = false
    end

    % Create tile coordinates
    [xTiles, yTiles] = ndgrid(1:tileSize(1), 1:tileSize(2));

    % Calculate size of container
    originalParentUnits = parent.Units;
    parent.Units = 'pixels';
    numChildren = length(parent.Children);

    originalUnits = cell(1, numChildren);

    for childIdx = 1:numChildren
        child = parent.Children(childIdx);
        originalUnits{childIdx} = child.Units;
        child.Units = 'pixels';
    end

    if preserveAspectRatio
        rowHeights = zeros(1, tileSize(1));
        columnWidths = zeros(1, tileSize(2));
        childPositions = vertcat(parent.Children.Position);
        % Adjust figure size
        for row = 1:tileSize(2)
            childIdx = yTiles==row;
            childIdx(numChildren+1:end) = false;
            firstChildInRow = find(childIdx, 1, 'first');
            if  isempty(firstChildInRow) || firstChildInRow > numChildren
                % Not enough children to fill this row
                rowHeights(row) = 0;
            else
                rowHeights(row) = max(childPositions(childIdx, 4));
            end
        end
        rowHeights(rowHeights == 0) = mean(rowHeights(rowHeights > 0));
        for column = 1:tileSize(1)
            childIdx = xTiles==column;
            childIdx(numChildren+1:end) = false;
            firstChildInColumn = find(childIdx, 1, 'first');
            if  isempty(firstChildInColumn) || firstChildInColumn > numChildren
                % Not enough children to fill this column
                columnWidths(column) = 0;
            else
                columnWidths(column) = max(childPositions(childIdx, 3));
            end
        end
        columnWidths(columnWidths == 0) = mean(columnWidths(columnWidths > 0));
        overallAspectRatio = sum(rowHeights)/sum(columnWidths);
        parent.Position(4) = parent.Position(3) * overallAspectRatio;
    end

    effectiveParentSize = parent.Position(3:4) - margin * (tileSize + 1);
    tileDims = effectiveParentSize ./ tileSize;

    for childIdx = 1:numChildren
        if childIdx > numel(xTiles)
            % Ran out of spaces in tiling
            break;
        end

        child = parent.Children(childIdx);

        % Determine coordinates of each axes according to the grid
        % size
        % Calculate tile upper left corner coordinates
        x = (xTiles(childIdx) - 1) * tileDims(1) + xTiles(childIdx) * margin;
        y = yTiles(childIdx) * tileDims(2) + yTiles(childIdx) * margin;
        % Flip y position so tiling starts at top
        y = parent.Position(4) - y;
        if preserveAspectRatio
            [newChildWidth, newChileHeight] = fitContainer(child.Position(3), child.Position(4), tileDims(1), tileDims(2));
            newChildSize = [newChildWidth, newChileHeight];
        else
            newChildSize = tileDims;
        end
        % Assemble tiled position vector
        tiledPosition = [x, y, newChildSize];

        % Set child position
        child.Position = tiledPosition;
    end
    parent.Units = originalParentUnits;

    for childIdx = 1:numChildren
        child = parent.Children(childIdx);
        child.Units = originalUnits{childIdx};
    end
end

function [objWidth, objHeight] = fitContainer(objWidth, objHeight, containerWidth, containerHeight)
    % Shrink/grow object's size to fit in container position without
    % changing aspect ratio
    widthRatio = containerWidth/objWidth;
    heightRatio = containerHeight/objHeight;
    if widthRatio < heightRatio
        % have to shrink width more (or grow less)
        objWidth = objWidth * widthRatio;
        objHeight = objHeight * widthRatio;
    else
        objWidth = objWidth * heightRatio;
        objHeight = objHeight * heightRatio;
    end
end