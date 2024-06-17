function stackChildren(parent, children, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stackChildren: Arrange children of a container so they are tightly
%   stacked either vertically or horizontally
% usage:  stackChildren(parent, Name, Value, ...)
%
% where,
%    parent is a parent widget containing children to be tiled
%    Name/value arguments can be any of:
%        Direction: dimension in which to stack, either 'horizontal' or 
%           'vertical'
%        Margin: the size in pixels of the margin between widgets. Default
%           is 10.
%        SortOrder: Either "given", meaning use the order they appear in
%           the children list or the parent.Children list, or "current",
%           (the default) meaning use the current position order in the 
%           relevant dimension given by Direction
%       Orientation: Either "upwards", meaning the sort order is applied
%           from the bottom up or "downwards", meaning top down (the
%           default)
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
    parent matlab.graphics.Graphics
    children matlab.graphics.Graphics = parent.Children
    options.Margin (1, 1) double = 10;                      % Size in pixels of the margin between widgets
    options.Direction (1, :) char {mustBeMember(options.Direction, {'horizontal', 'vertical'})} = 'vertical'
    options.SortOrder (1, :) char {mustBeMember(options.SortOrder, {'given', 'current'})} = 'current'
    options.Orientation (1, :) char {mustBeMember(options.Orientation, {'upwards', 'downwards'})} = 'downwards'
end

positions = vertcat(children.Position);

switch options.Direction
    case 'horizontal'
        positionIdx = 1;
        sizeIdx = 3;
    case 'vertical'
        positionIdx = 2;
        sizeIdx = 4;
end

switch options.SortOrder
    case 'given'
        % Use order in given children list
        sortOrder = 1:length(children);
    case 'current'
        % Sort by current position in the relevant direction
        [~, sortOrder] = sort(positions(:, positionIdx));
end

if strcmp(options.Orientation, 'downwards')
    sortOrder = reverse(sortOrder);
end

children = children(sortOrder);

units = parent.Units;

setPositionWithUnits(children(1), 0, units, positionIdx);

for childIdx = 2:length(children)
    lastChildIdx = childIdx - 1;
    lastCoordinate = getPositionWithUnits(children(lastChildIdx), units, positionIdx);
    lastSize= getPositionWithUnits(children(lastChildIdx), units, sizeIdx);
    newCoordinate = lastCoordinate + lastSize + options.Margin;
    setPositionWithUnits(children(childIdx), newCoordinate, units, positionIdx);
end