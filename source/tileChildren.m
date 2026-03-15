function tileChildren(parent, tileSize, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tileFigures: Arrange children of a container in a tiled pattern
% usage:  tileChildren(parent, tileSize, Name, Value, ...)
%
% where,
%    parent is a parent widget containing children to be tiled
%    tileSize is a 1x2 vector containing the x and y size of the desired
%       tile grid
%    Name/value arguments can be any of:
%        Margin: the size in pixels of the margin between widgets. Default
%           is 10.
%        PreserveAspectRatio: a logical indicating whether or not to keep
%           the aspect ratio of the children unchanged. Default is false
%
% Take a container with several widgets, and reposition them so they are 
%   tiled in a grid pattern.
%
% See also: tileFigures, shrinkFigureToContent
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    arguments
        parent
        tileSize (1, 2) double                                  % 2-vector containing the x and y size of the desired axes grid
        options.Margin (1, 1) double = 10;                      % Size in pixels of the margin between widgets
        options.PreserveAspectRatio (1, 1) logical = false      % Keep aspect ratio of children when tiling
        options.Arrangement (1, :) char {mustBeMember(options.Arrangement, {'grid', 'row', 'column', 'patchwork'})} = 'grid'
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

    switch options.Arrangement
        case 'grid'
            if options.PreserveAspectRatio
                rowHeights = zeros(1, tileSize(2));
                columnWidths = zeros(1, tileSize(1));
                childPositions = vertcat(parent.Children.OuterPosition);
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
                sum(rowHeights)
                sum(columnWidths)
                overallAspectRatio = sum(rowHeights)/sum(columnWidths);
                parent.Position(4) = parent.Position(3) * overallAspectRatio;
            end
        
            effectiveParentSize = parent.Position(3:4) - options.Margin * (tileSize + 1);
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
                x = (xTiles(childIdx) - 1) * tileDims(1) + xTiles(childIdx) * options.Margin;
                y = yTiles(childIdx) * tileDims(2) + yTiles(childIdx) * options.Margin;
                % Flip y position so tiling starts at top
                y = parent.Position(4) - y;
                if options.PreserveAspectRatio
                    [newChildWidth, newChileHeight] = fitContainer(child.OuterPosition(3), child.OuterPosition(4), tileDims(1), tileDims(2));
                    newChildSize = [newChildWidth, newChileHeight];
                else
                    newChildSize = tileDims;
                end
                % Assemble tiled position vector
                tiledPosition = [x, y, newChildSize];
        
                % Set child position
                child.OuterPosition = tiledPosition;
            end

        case 'row'
            totalWidth = parent.Position(3);
            rowIdx = 1;
            rowHeights = 0;
            rowWidths = 0;
            rowAssignments = zeros(1, numChildren);
            for childIdx = 1:numChildren
                child = parent.Children(childIdx);
                width = child.OuterPosition(3);
                height = child.OuterPosition(4);

                if width > totalWidth
                    error('Child is too big for its parent');
                end

                newRowWidth = rowWidths(rowIdx) + width;
                if childIdx ~= 1
                    newRowWidth = newRowWidth + options.Margin;
                end

                if newRowWidth >= totalWidth
                    % This child belongs on the next row
                    rowIdx = rowIdx + 1;
                    rowHeights(rowIdx) = 0; %#ok<AGROW> 
                    rowWidths(rowIdx) = 0; %#ok<AGROW> 
                else
                    rowWidths(rowIdx) = newRowWidth; %#ok<AGROW> 
                end
                rowHeights(rowIdx) = max(rowHeights(rowIdx), height); %#ok<AGROW> 
                rowAssignments(childIdx) = rowIdx;
            end

            rowAssignments
            rowWidths
            rowHeights

            lastY = 0;
            numRows = max(rowAssignments);
            for rowIdx = 1:numRows
                lastX = 0;
                childIndices = find(rowAssignments == rowIdx);
                childPositions = vertcat(parent.Children(childIndices).OuterPosition);
                childWidth = sum(childPositions(:, 3));
                childHeight = max(childPositions(:, 4));
                xMargin = (parent.Position(3) - childWidth) / (length(childIndices) - 1);
                yMargin = ((parent.Position(4) - rowHeights(rowIdx)) / (numRows-1));
                for childIdx = childIndices
                    parent.Children(childIdx).OuterPosition(1) = lastX;
                    parent.Children(childIdx).OuterPosition(2) = lastY;
                    lastX = lastX + parent.Children(childIdx).OuterPosition(3) + xMargin;
                end
                lastY = lastY + childHeight + yMargin;
            end
        case 'column'
            error('column arrangement not implemented yet')
        case 'patchwork'
            error('patchwork arrangement not implemented yet')
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