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
%       1. A 2D grid of integers which represent the indices of the 
%           graphics objects supplied in the children argumen iu the 
%           desired layout. To allow one graphics object to span multiple 
%           rows and/or columns, simply place its index in multiple array
%           cells.
%    The following Name/Value arguments:
%       ColumnWidths: Either a single number or a 1xN array of numbers
%           representing either the desired width of all columns or of each
%           column individually, in the units specified by ColumnUnits. If
%           omitted, each column will be sized according to the largest
%           object assigned to it.
%       RowHeights: Either a single number or a 1xM array of numbers
%           representing either the desired height of all rows or of each
%           row individually, in the units specified by RowUnits. If
%           omitted, each row will be sized according to the largest
%           object assigned to it.
%       FitToWidth: Logical indicating whether or not to size columns so
%           the grid fills the entire width of the parent container. If 
%           true, provided ColumnWidths and ColumnMargins will be scaled 
%           down to fit. Default is false.
%       FitToHeight: Logical indicating whether or not to size rows so
%           the grid fills the entire height of the parent container. If 
%           true, provided RowWidths and RowMargins will be scaled down to 
%           fit. Default is false.
%       ColumnUnits: Either a single string/char array representing a valid
%           MATLAB graphics unit, or a 1xN cell array of them, representing
%           the units for ColumnWidths and ColumnMargins
%       RowUnits: Either a single string/char array representing a valid
%           MATLAB graphics unit, or a 1xN cell array of them, representing
%           the units for RowHeights and RowMargins
%       ColumnMargins: Either a single number or a 1xN array of numbers
%           representing either the desired margin before all columns or 
%           before each column individually, in the units specified by 
%           ColumnUnits
%       RowMargin: Either a single number or a 1xM array of numbers
%           representing either the desired margin before all rows or 
%           before each row individually, in the units specified by 
%           RowUnits
%
% This is meant to be a quick and easy way to arrange MATLAB objects in a
%   grid. Example usage:
%
%   f = figure();
%   ax1 = axes(f);
%   ax2 = axes(f);
%   ax3 = axes(f);
%   gl = gobjects(3, 3)
%   gl(1:3, 1) = ax1;
%   gl(1:2, 2) = ax2;
%   gl(3, 3) = ax3;
%   gridChildren(gl);
%
% See also: <related functions>
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    gridLayout {mustBeA(gridLayout, {'matlab.graphics.Graphics', 'double'})}
    children matlab.graphics.Graphics = gobjects().empty
    options.ColumnWidths double = NaN
    options.RowHeights double = NaN
    options.FitToWidth logical = false
    options.FitToHeight logical = false
    options.ColumnUnits = 'inches'
    options.RowUnits = 'inches'
    options.ColumnMargins = 0
    options.RowMargins = 0
end

if any(isgraphics(gridLayout), 'all')
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
    % User passed a grid of child indices - check that the children
    % argument is an appropriate list of graphics objects
    children = options.Children;
    mustBeInteger(gridLayout)
    if ~all(ismember(unique(gridLayout(:)), children))
        error(['gridLayout contains indices that are out of range for the ' ...
            'provided list of children']);
    end
end
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
for k = 1:length(children)
    [xCoords, yCoords] = ind2sub(size(gridLayout), find(gridLayout == k));
    [isRect, yRange, xRange] = isFilledRectangle(xCoords, yCoords);
    if ~isRect
        error('Invalid grid layout - make sure each child object is represented by a single solid rectangle within the gridLayout');
    end
    childCoords{k, 1} = yRange;
    childCoords{k, 2} = xRange;
    columnSpans(k) = diff(xRange) + 1;
    rowSpans(k) = diff(yRange) + 1;
end

if ischar(columnUnits)
    columnUnits = repmat({columnUnits}, 1, numColumns);
end
if ischar(rowUnits)
    rowUnits = repmat({rowUnits}, 1, numRows);
end
if length(columnWidths) == 1
    columnWidths = repmat(columnWidths, 1, numColumns);
end
if length(rowHeights) == 1
    rowHeights = repmat(rowHeights, 1, numRows);
end

if length(columnMargins) == 1
    columnMargins = repmat(columnMargins, 1, numColumns+1);
end
if length(rowMargins) == 1
    rowMargins = repmat(rowMargins, 1, numRows+1);
end

% Translate all row heights/column widths into a common unit, and determine
% the x/y position of the bottom/left side of each row/column, plus the 
% top/right side of the last row/column
dummyElement = uipanel(parent, 'Visible', false);

for k = 1:numColumns+1
    setPositionWithUnits(dummyElement, columnMargins(k), columnUnits{min(k, numColumns)}, 3);
    columnMargins(k) = getPositionWithUnits(dummyElement, parent.Units, 3);
end
for k = 1:numRows+1
    setPositionWithUnits(dummyElement, rowMargins(k), rowUnits{min(k, numRows)}, 4);
    rowMargins(k) = getPositionWithUnits(dummyElement, parent.Units, 4);
end

% Determine edge positions of columns and rows
columnXs = zeros(numColumns, 2) + columnMargins(1);
rowYs =    zeros(numRows, 2) + rowMargins(1);
resizeToColumn = false(1, numColumns);
resizeToRow = false(1, numRows);

lastColumnX = 0;
for k = 1:numColumns
    if ~isnan(columnWidths(k))
        % Determine width based on requested column widths/units
        resizeToColumn(k) = true;
        setPositionWithUnits(dummyElement, columnWidths(k), columnUnits{k}, 3);
        columnWidths(k) = getPositionWithUnits(dummyElement, parent.Units, 3);
    else
        % Determine width based on existing sizes of children
        notEmptyMask = gridLayout(:, k) > 0;
        childIdxInColumn = unique(gridLayout(notEmptyMask, k));
        childrenInColumn = children(childIdxInColumn);
        childWidths = arrayfun(@(c)getPositionWithUnits(c, parent.Units, 3), childrenInColumn);
        columnWidths(k) = max(childWidths ./ columnSpans(childIdxInColumn), [], 'all');
    end
    columnXs(k, 1) = lastColumnX + columnMargins(k);  % X of left side of column k
    columnXs(k, 2) = lastColumnX + columnMargins(k) + columnWidths(k);  % X of right side of column k
    lastColumnX = columnXs(k, 2);
end
lastRowY = 0;
for k = 1:numRows
    if ~isnan(rowHeights(k))
        % Determine height based on requested row heights/units
        resizeToRow(k) = true;
        setPositionWithUnits(dummyElement, rowHeights(k), rowUnits{k}, 4);
        rowHeights(k) = getPositionWithUnits(dummyElement, parent.Units, 4);
    else
        % Determine width based on existing sizes of children
        notEmptyMask = gridLayout(k, :) > 0;
        childIdxInRow = unique(gridLayout(k, notEmptyMask));
        childrenInRow = children(childIdxInRow);
        childHeights = arrayfun(@(c)getPositionWithUnits(c, parent.Units, 4), childrenInRow);
        rowHeights(k) = max(childHeights ./ rowSpans(childIdxInRow), [], 'all');
    end
    rowYs(k, 1) = lastRowY + rowMargins(k);  % Y of bottom side of row k
    rowYs(k, 2) = lastRowY + rowMargins(k) + rowHeights(k);  % Y of top side of row k
    lastRowY = rowYs(k, 2);
end

delete(dummyElement);

if fitToHeight
    % User requested fit to width - determine total parent height
    switch parent.Units
        case 'normalized'
            totalSize = 1;
        otherwise
            totalSize = parent.Position(4);
    end
    % Scale row heights
    rowScale = (totalSize / (max(rowYs(:) - min(rowYs(:))) + 2*rowMargins(end)));
    rowYs = rowYs * rowScale;
end
if fitToWidth
    % User requested fit to width - determine total parent width
    switch parent.Units
        case 'normalized'
            totalSize = 1;
        otherwise
            totalSize = parent.Position(3);
    end
    % Scale column widths
    columnScale = (totalSize / (max(columnXs(:) - min(columnXs(:))) + 2*columnMargins(end)));
    columnXs = columnXs * columnScale;
end

for k = 1:numChildren
    startColumn = childCoords{k, 2}(1);
    endColumn = childCoords{k, 2}(2);
    startRow = childCoords{k, 1}(1);
    endRow = childCoords{k, 1}(2);
    x = columnXs(startColumn, 1);
    y = rowYs(startRow, 1);
    x2 = columnXs(endColumn, 2);
    y2 = rowYs(endRow, 2);

    w = getPositionWithUnits(children(k), parent.Units, 3);
    if any(resizeToColumn(startColumn:endColumn)) || w > (x2 - x)
        w = x2 - x;
    else
        x = (x + x2)/2 - w/2;
    end
    setPositionWithUnits(children(k), [x, w], parent.Units, [1, 3]);

    h = getPositionWithUnits(children(k), parent.Units, 4);
    if any(resizeToRow(startRow:endRow)) || h > (y2 - y)
        h = y2 - y;
    else
        y = (y + y2)/2 - h/2;
    end
    setPositionWithUnits(children(k), [y, h], parent.Units, [2, 4]);
end

end

function [isRect, xRange, yRange] = isFilledRectangle(xCoords, yCoords)
    xMin = min(xCoords);
    xMax = max(xCoords);
    yMin = min(yCoords);
    yMax = max(yCoords);
    xRange = [xMin, xMax];
    yRange = [yMin, yMax];
    isRect = true;
    if ~ismember(xMin:xMax, xCoords)
        isRect = false;
        return;
    end
    if any(~ismember(xCoords, xMin:xMax))
        isRect = false;
        return;
    end
    if any(~ismember(yMin:yMax, yCoords)) 
        isRect = false;
        return;
    end
    if any(~ismember(yCoords, yMin:yMax))
        isRect = false;
        return;
    end
end

function idx = childToIndex(child, children)
    if ~isgraphics(child)
        idx = 0;
    else
        idx = find(child==children, 1);
    end
end