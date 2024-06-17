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
%           column individually, in the units specified by ColumnUnits
%       RowHeights: Either a single number or a 1xM array of numbers
%           representing either the desired height of all rows or of each
%           row individually, in the units specified by RowUnits
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
    options.ColumnWidths double = 1
    options.RowHeights double = 1
    options.ColumnUnits = 'inches'
    options.RowUnits = 'inches'
    options.ColumnMargins = 0.1
    options.RowMargins = 0.1
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

parent = unique([children.Parent]);
if length(parent) ~= 1
    error('All children in the grid layout must have the same parent graphics object.')
end

numChildren = length(children);
numRows = size(gridLayout, 1);
numColumns = size(gridLayout, 2);

childCoords = cell(numChildren, 2);

% Make sure this is a valid grid layout:
for k = 1:length(children)
    [xCoords, yCoords] = ind2sub(size(gridLayout), find(gridLayout == k));
    [isRect, xRange, yRange] = isFilledRectangle(xCoords, yCoords);
    childCoords{k, 1} = xRange;
    childCoords{k, 2} = yRange;
    if ~isRect
        error('Invalid grid layout - make sure each child object is represented by a single solid rectangle within the gridLayout');
    end
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

for k = 1:numColumns
    setPositionWithUnits(dummyElement, columnMargins(k), columnUnits{k}, 3);
    columnMargins(k) = getPositionWithUnits(dummyElement, parent.Units, 3);
end
for k = 1:numRows
    setPositionWithUnits(dummyElement, rowMargins(k), rowUnits{k}, 4);
    rowMargins(k) = getPositionWithUnits(dummyElement, parent.Units, 4);
end

columnXs = zeros(numColumns, 2) + columnMargins(1);
rowYs =    zeros(numRows, 2) + rowMargins(1);
lastColumnX = 0;
for k = 1:numColumns
    setPositionWithUnits(dummyElement, columnWidths(k), columnUnits{k}, 3);
    columnWidths(k) = getPositionWithUnits(dummyElement, parent.Units, 3);
    columnXs(k, 1) = lastColumnX + columnMargins(k);  % X of left side of column k
    columnXs(k, 2) = lastColumnX + columnMargins(k) + columnWidths(k);  % X of right side of column k
    lastColumnX = columnXs(k, 2);
end
lastRowY = 0;
for k = 1:numRows
    setPositionWithUnits(dummyElement, rowHeights(k), rowUnits{k}, 4);
    rowHeights(k) = getPositionWithUnits(dummyElement, parent.Units, 4);
    rowYs(k, 1) = lastRowY + rowMargins(k);  % Y of bottom side of row k
    rowYs(k, 2) = lastRowY + rowMargins(k) + rowHeights(k);  % Y of top side of row k
    lastRowY = rowYs(k, 2);
end

delete(dummyElement);

for k = 1:numChildren
    startColumn = childCoords{k, 2}(1);
    endColumn = childCoords{k, 2}(2);
    startRow = childCoords{k, 1}(1);
    endRow = childCoords{k, 1}(2);
    x = columnXs(startColumn, 1);
    y = rowYs(startRow, 1);
    x2 = columnXs(endColumn, 2);
    y2 = rowYs(endRow, 2);
    w = x2 - x;
    h = y2 - y;
    setPositionWithUnits(children(k), [x, w], parent.Units, [1, 3]);
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