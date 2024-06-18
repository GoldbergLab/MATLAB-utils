function g = shrinkToContent(g, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% shrinkToContent: shrink a container ui widget to fit its content
% usage:  g = shrinkToContent(g)
%         g = shrinkToContent(g, Name, Value, ...)
%
% where,
%    g is the container widget to shrink
%    Name/Value pairs can include
%       Margin: amount in pixels to add around the child objects. Can be a
%           single number, which will be applied to both the horizontal and
%           vertical edges, or a 1x2 vector, in which case the first
%           element will be the horizontal margin, and the second will be
%           the vertical margin
%       PositionType: Which Position property to use to shrink to - either
%           InnerPosition, OuterPosition, or Position
%       ShrinkX: Shrink object in the horizontal direction? Default is true
%       ShrinkY: Shrink object in the vertical direction? Default is true
%
% This function shrinks a container widget, such as a figure or a uipanel,
%   to fit its content, without affecting the size/shape/layout of the 
%   content itself. Despite the name, it can shrink or expand the parent
%   widget.
% Please note that this used to be called shrinkFigureToContent, which is
%   deprecated and will be removed in the future.
%
% See also: tightenChildren, tileFigures
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    g
    options.Margin (1, :) double = [0, 0]
    options.MarginUnits = 'pixels'
    options.PositionType (1, :) char {mustBeMember(options.PositionType, {'Position', 'InnerPosition', 'OuterPosition'})} = 'InnerPosition'
    options.ShrinkX = true
    options.ShrinkY = true
end

if length(options.Margin) == 1
    options.Margin = [options.Margin, options.Margin];
end

% Store the original child & parent units so we can restore it later (have 
%   to use arrayfun in case children are not all the same type).
originalChildUnits = arrayfun(@(c)c.Units, g.Children, 'UniformOutput', false);
originalParentUnits = g.Units;
% Set children to normalized units
set(g.Children, 'Units', 'pixels');
g.Units = 'pixels';
% Get all child positions (have to use arrayfun in case children are not
%   all the same type)
positions = arrayfun(@(c)c.Position, g.Children, 'UniformOutput', false);
positions = vertcat(positions{:});
% Find the coordinates of the bounding box for all the children.
x0 = positions(:, 1);
y0 = positions(:, 2);
x1 = x0 + positions(:, 3);
y1 = y0 + positions(:, 4);

x0 = min(x0);
y0 = min(y0);
x1 = max(x1);
y1 = max(y1);

if strcmp(options.PositionType, 'InnerPosition')
    % Adjust to make coordinate relative to inner position
    xInnerMargin = [g.InnerPosition(1) - g.Position(1), g.Position(1) + g.Position(3) - (g.InnerPosition(1) + g.InnerPosition(3))];
    yInnerMargin = [g.InnerPosition(2) - g.Position(2), g.Position(2) + g.Position(4) - (g.InnerPosition(2) + g.InnerPosition(4))];
else
    xInnerMargin = [0, 0];
    yInnerMargin = [0, 0];
end

% Get the necessary bounding box width/height
width = (x1 - x0);
height = (y1 - y0);

% Loop over children
for k = 1:length(g.Children)
    % Translate children so their bounding box is in the lower left corner
    % of the container
    g.Children(k).Position(1) = g.Children(k).Position(1) - x0 + xInnerMargin(1);
    g.Children(k).Position(2) = g.Children(k).Position(2) - y0 + yInnerMargin(1);
    % Set units to pixels so the children don't changes size when we shrink
    % the container
    g.Children(k).Units = 'pixels';
end

% Shrink the container horizontally
if options.ShrinkX
    g.Position(3) = width + sum(xInnerMargin);
else
    options.Margin(1) = 0;
end

% Shrink the container vertically
if options.ShrinkY
    g.Position(4) = height + sum(yInnerMargin);
else
    options.Margin(2) = 0;
end

if any(options.Margin ~= 0)
    sz = getPositionWithUnits(g, options.MarginUnits, 3:4);
    sz = sz + 2*options.Margin;
    setPositionWithUnits(g, sz, options.MarginUnits, 3:4);
    for k = 1:length(g.Children)
        changePositionWithUnits(g.Children(k), options.Margin, options.MarginUnits, 1:2);
    end
end

% Restore the child and parent units
for k = 1:length(g.Children)
    g.Children(k).Units = originalChildUnits{k};
end
g.Units = originalParentUnits;
