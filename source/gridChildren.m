function gridChildren(gridLayout, children, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gridChildren: Arrange a group of graphics children in a grid
% usage:  gridChildren(gridLayout, children, options)
%
% where,
%    gridLayout is either
%       1. A MxN 2D grid of graphics objects which represents the desired
%           layout. To allow one graphics object to span multiple rows
%           and/or columns, simply place its handle in multiple array
%           cells. The children argument will be ignored.
%       2. A 2D grid of integers which represent the indices of the
%           graphics objects supplied in the children argument in the
%           desired layout. Use 0 for empty cells. To allow one graphics
%           object to span multiple rows and/or columns, simply place its
%           index in multiple array cells.
%    The following Name/Value arguments:
%       ColumnWidths: Either a single number or a 1xN array of numbers
%           representing either the desired width of all columns or of each
%           column individually, in the units specified by ColumnUnits. If
%           omitted or NaN, each column will be sized according to the
%           largest object assigned to it.
%       RowHeights: Either a single number or a 1xM array of numbers
%           representing either the desired height of all rows or of each
%           row individually, in the units specified by RowUnits. If
%           omitted or NaN, each row will be sized according to the largest
%           object assigned to it.
%       FitToWidth: Logical indicating whether or not to size columns so
%           the grid fills the entire width of the parent container. If
%           true, provided ColumnWidths and ColumnMargins will be scaled
%           to fit. Default is false.
%       FitToHeight: Logical indicating whether or not to size rows so
%           the grid fills the entire height of the parent container. If
%           true, provided RowHeights and RowMargins will be scaled to
%           fit. Default is false.
%       ColumnUnits: Either a single string/char array representing a valid
%           MATLAB graphics unit, or a 1xN cell array of them, representing
%           the units for ColumnWidths and ColumnMargins
%       RowUnits: Either a single string/char array representing a valid
%           MATLAB graphics unit, or a 1xN cell array of them, representing
%           the units for RowHeights and RowMargins
%       ColumnMargins: Either a single number or a 1x(N+1) array of numbers
%           representing either the desired margin before all columns (and
%           after the last) or before each column individually plus a
%           trailing margin, in the units specified by ColumnUnits
%       RowMargins: Either a single number or a 1x(M+1) array of numbers
%           representing either the desired margin before all rows (and
%           after the last) or before each row individually plus a trailing
%           margin, in the units specified by RowUnits
%
% This is meant to be a quick and easy way to arrange MATLAB objects in a
%   grid. Row 1 of the gridLayout matrix corresponds to the top visual row.
%
%   Example usage:
%
%   f = figure();
%   ax1 = axes(f);
%   ax2 = axes(f);
%   ax3 = axes(f);
%   gl = gobjects(3, 3);
%   gl(1:3, 1) = ax1;    % ax1 spans all 3 rows in column 1
%   gl(1:2, 2) = ax2;    % ax2 spans rows 1-2 in column 2
%   gl(3, 3) = ax3;       % ax3 in bottom-right cell
%   gridChildren(gl);
%
% See also: setPositionWithUnits, getPositionWithUnits
%
% Version: 2.0
% Author:  Brian Kardon / Claude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    gridLayout {mustBeA(gridLayout, {'matlab.graphics.Graphics', 'double'})}
    children matlab.graphics.Graphics = gobjects().empty
    options.ColumnWidths double = NaN
    options.RowHeights double = NaN
    options.FitToWidth logical = false
    options.FitToHeight logical = false
    options.ColumnUnits {mustBeGraphicsUnit} = 'pixels'
    options.RowUnits {mustBeGraphicsUnit} = 'pixels'
    options.ColumnMargins double = 0
    options.RowMargins double = 0
end

if isa(gridLayout, 'matlab.graphics.Graphics')
    % User has passed in a grid of graphics objects - convert it to indices
    if ~isempty(children)
        warning(['If gridLayout is provided as a 2D array of graphics ' ...
            'objects, the ''children'' argument will be ignored']);
    end
    children = unique(gridLayout(:));
    children = children(isgraphics(children));
    c2i = @(g)childToIndex(g, children);
    gridLayout = arrayfun(c2i, gridLayout);
else
    % User passed a grid of child indices - validate the indices
    mustBeInteger(gridLayout);
    validIndices = unique(gridLayout(:));
    validIndices = validIndices(validIndices > 0);  % Ignore zeros (empty cells)
    if any(validIndices > length(children)) || any(validIndices < 1)
        error(['gridLayout contains indices that are out of range for the ' ...
            'provided list of children (expected 1 to %d)'], length(children));
    end
end

% Flip grid layout so row 1 of the matrix appears at the top of the
% parent (MATLAB positions from bottom-up, but users think top-down).
gridLayout = flipud(gridLayout);

columnWidths = options.ColumnWidths;
rowHeights = options.RowHeights;
columnUnits = options.ColumnUnits;
rowUnits = options.RowUnits;
columnMargins = options.ColumnMargins;
rowMargins = options.RowMargins;
fitToWidth = options.FitToWidth;
fitToHeight = options.FitToHeight;

parent = unique([children.Parent]);
if length(parent) ~= 1
    error('All children in the grid layout must have the same parent graphics object.')
end

numChildren = length(children);
numRows = size(gridLayout, 1);
numColumns = size(gridLayout, 2);

childCoords = cell(numChildren, 2);
columnSpans = zeros(1, numChildren);
rowSpans = zeros(1, numChildren);

% Make sure this is a valid grid layout, and extract row and column ranges
% for each child
for childNum = 1:numChildren
    [rowCoords, colCoords] = ind2sub(size(gridLayout), find(gridLayout == childNum));
    [isRect, rowRange, colRange] = isFilledRectangle(rowCoords, colCoords);
    if ~isRect
        error('Invalid grid layout - make sure each child object is represented by a single solid rectangle within the gridLayout');
    end
    childCoords{childNum, 1} = rowRange;
    childCoords{childNum, 2} = colRange;
    columnSpans(childNum) = diff(colRange) + 1;
    rowSpans(childNum) = diff(rowRange) + 1;
end

% Expand scalar options to per-column/row arrays
if istext(columnUnits)
    columnUnits = repmat({columnUnits}, 1, numColumns);
end
if istext(rowUnits)
    rowUnits = repmat({rowUnits}, 1, numRows);
end
if isscalar(columnWidths)
    columnWidths = repmat(columnWidths, 1, numColumns);
end
if isscalar(rowHeights)
    rowHeights = repmat(rowHeights, 1, numRows);
end
if isscalar(columnMargins)
    columnMargins = repmat(columnMargins, 1, numColumns + 1);
end
if isscalar(rowMargins)
    rowMargins = repmat(rowMargins, 1, numRows + 1);
end

% Convert all margins and explicit sizes into the parent's units using
% a temporary dummy element for unit translation.
dummyElement = uipanel(parent, 'Visible', 'off', 'Units', 'pixels', ...
    'Position', [0, 0, 100, 100]);

for colNum = 1:numColumns + 1
    unitIdx = min(colNum, numColumns);
    columnMargins(colNum) = convertSize(dummyElement, columnMargins(colNum), ...
        columnUnits{unitIdx}, parent.Units, 'width');
end
for rowNum = 1:numRows + 1
    unitIdx = min(rowNum, numRows);
    rowMargins(rowNum) = convertSize(dummyElement, rowMargins(rowNum), ...
        rowUnits{unitIdx}, parent.Units, 'height');
end

% Determine column widths and edge positions
columnXs = zeros(numColumns, 2);
resizeToColumn = false(1, numColumns);
lastColumnX = 0;

for colNum = 1:numColumns
    if ~isnan(columnWidths(colNum))
        % Explicit width: convert to parent units
        resizeToColumn(colNum) = true;
        columnWidths(colNum) = convertSize(dummyElement, columnWidths(colNum), ...
            columnUnits{colNum}, parent.Units, 'width');
    else
        % Auto width: measure the widest child in this column
        notEmptyMask = gridLayout(:, colNum) > 0;
        childIdxInColumn = unique(gridLayout(notEmptyMask, colNum));
        if isempty(childIdxInColumn)
            columnWidths(colNum) = 0;
        else
            childrenInColumn = children(childIdxInColumn);
            childWidths = arrayfun(@(c)getPositionWithUnits(c, parent.Units, 3), childrenInColumn);
            % Divide by column span so multi-column children don't inflate single columns
            columnWidths(colNum) = max(childWidths(:) ./ columnSpans(childIdxInColumn(:)), [], 'all');
        end
    end
    columnXs(colNum, 1) = lastColumnX + columnMargins(colNum);
    columnXs(colNum, 2) = lastColumnX + columnMargins(colNum) + columnWidths(colNum);
    lastColumnX = columnXs(colNum, 2);
end

% Determine row heights and edge positions
rowYs = zeros(numRows, 2);
resizeToRow = false(1, numRows);
lastRowY = 0;

for rowNum = 1:numRows
    if ~isnan(rowHeights(rowNum))
        % Explicit height: convert to parent units
        resizeToRow(rowNum) = true;
        rowHeights(rowNum) = convertSize(dummyElement, rowHeights(rowNum), ...
            rowUnits{rowNum}, parent.Units, 'height');
    else
        % Auto height: measure the tallest child in this row
        notEmptyMask = gridLayout(rowNum, :) > 0;
        childIdxInRow = unique(gridLayout(rowNum, notEmptyMask));
        if isempty(childIdxInRow)
            rowHeights(rowNum) = 0;
        else
            childrenInRow = children(childIdxInRow);
            childHeights = arrayfun(@(c)getPositionWithUnits(c, parent.Units, 4), childrenInRow);
            rowHeights(rowNum) = max(childHeights(:) ./ rowSpans(childIdxInRow(:)), [], 'all');
        end
    end
    rowYs(rowNum, 1) = lastRowY + rowMargins(rowNum);
    rowYs(rowNum, 2) = lastRowY + rowMargins(rowNum) + rowHeights(rowNum);
    lastRowY = rowYs(rowNum, 2);
end

delete(dummyElement);

% Scale to fit parent container if requested
if fitToHeight
    parentH = getParentExtent(parent, 4);
    totalH = max(rowYs(:)) + rowMargins(end);
    if totalH > 0
        scale = parentH / totalH;
        rowYs = rowYs * scale;
    end
end
if fitToWidth
    parentW = getParentExtent(parent, 3);
    totalW = max(columnXs(:)) + columnMargins(end);
    if totalW > 0
        scale = parentW / totalW;
        columnXs = columnXs * scale;
    end
end

% Position each child within its grid cell(s)
for childNum = 1:numChildren
    startColumn = childCoords{childNum, 2}(1);
    endColumn = childCoords{childNum, 2}(2);
    startRow = childCoords{childNum, 1}(1);
    endRow = childCoords{childNum, 1}(2);

    % Cell bounds
    cellX = columnXs(startColumn, 1);
    cellX2 = columnXs(endColumn, 2);
    cellY = rowYs(startRow, 1);
    cellY2 = rowYs(endRow, 2);
    cellW = cellX2 - cellX;
    cellH = cellY2 - cellY;

    % If the column(s) have explicit widths, resize the child to fill.
    % Otherwise, center the child within the cell.
    childW = getPositionWithUnits(children(childNum), parent.Units, 3);
    if any(resizeToColumn(startColumn:endColumn)) || childW > cellW
        childW = cellW;
        childX = cellX;
    else
        childX = (cellX + cellX2) / 2 - childW / 2;
    end

    childH = getPositionWithUnits(children(childNum), parent.Units, 4);
    if any(resizeToRow(startRow:endRow)) || childH > cellH
        childH = cellH;
        childY = cellY;
    else
        childY = (cellY + cellY2) / 2 - childH / 2;
    end

    setPositionWithUnits(children(childNum), [childX, childY, childW, childH], parent.Units);
end

end

%% Local helper functions

function [isRect, rowRange, colRange] = isFilledRectangle(rowCoords, colCoords)
    % Check if the given row/column coordinate pairs form a filled rectangle.
    rowMin = min(rowCoords);
    rowMax = max(rowCoords);
    colMin = min(colCoords);
    colMax = max(colCoords);
    rowRange = [rowMin, rowMax];
    colRange = [colMin, colMax];

    % A filled rectangle must contain every (row, col) pair in the range
    expectedCount = (rowMax - rowMin + 1) * (colMax - colMin + 1);
    isRect = (length(rowCoords) == expectedCount) && ...
             all(ismember(rowMin:rowMax, rowCoords)) && ...
             all(ismember(colMin:colMax, colCoords));
end

function idx = childToIndex(child, children)
    if ~isgraphics(child)
        idx = 0;
    else
        idx = find(child == children, 1);
    end
end

function sizeInTarget = convertSize(dummyElement, sizeValue, fromUnits, toUnits, dimension)
    % Convert a size value between units using a dummy element.
    % dimension is 'width' or 'height'.
    if strcmp(fromUnits, toUnits) || sizeValue == 0
        sizeInTarget = sizeValue;
        return;
    end
    switch dimension
        case 'width'
            posIdx = 3;
        case 'height'
            posIdx = 4;
    end
    dummyElement.Units = fromUnits;
    dummyElement.Position(posIdx) = sizeValue;
    dummyElement.Units = toUnits;
    sizeInTarget = dummyElement.Position(posIdx);
end

function extent = getParentExtent(parent, posIdx)
    % Get the usable extent of a parent container in its own units.
    switch parent.Units
        case 'normalized'
            extent = 1;
        otherwise
            extent = parent.Position(posIdx);
    end
end
