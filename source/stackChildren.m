function stackChildren(parent, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stackChildren: Arrange children of a container so they are tightly
%   stacked either vertically or horizontally
% usage:  stackChildren(parent, Name, Value, ...)
%
% where,
%    parent is a parent widget containing children to be tiled
%    Name/value arguments can be any of:
%        Direction: direction to stack, either 'horizontal' or 'vertical'
%        Margin: the size in pixels of the margin between widgets. Default
%           is 10.
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
    options.Margin (1, 1) double = 10;                      % Size in pixels of the margin between widgets
    options.Direction (1, :) char {mustBeMember(options.Direction, {'horizontal', 'vertical'})} = 'vertical'
end

positions = vertcat(parent.Children.Position);

switch options.Direction
    case 'horizontal'
        positionIdx = 1;
        sizeIdx = 3;
    case 'vertical'
        positionIdx = 2;
        sizeIdx = 4;
end

[~, sortOrder] = sort(positions(:, positionIdx));

children = parent.Children(sortOrder);

setPositionWithUnits(children(1), 0, 'normalized', positionIdx);

for childIdx = 2:length(children)
    lastChildIdx = childIdx - 1;
    lastCoordinate = getPositionWithUnits(children(lastChildIdx), 'pixels', positionIdx);
    lastSize= getPositionWithUnits(children(lastChildIdx), 'pixels', sizeIdx);
    newCoordinate = lastCoordinate + lastSize + options.Margin;
    setPositionWithUnits(children(childIdx), newCoordinate, 'pixels', positionIdx);
end