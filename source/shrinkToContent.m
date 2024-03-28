function g = shrinkToContent(g)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% shrinkToContent: shrink a container ui widget to fit its content
% usage:  g = shrinkToContent(g)
%
% where,
%    g is the container widget to shrink
%
% This function shrinks a container widget, such as a figure or a uipanel,
%   to fit its content, without affecting the size/shape/layout of the 
%   content itself.
% Please note that this used to be called shrinkFigureToContent.
%
% See also: tightenChildren, tileFigures
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Store the original child units so we can restore it later
originalUnits = {g.Children.Units};
% Set children to normalized units
set(g.Children, 'Units', 'normalized');
% Get all child positions
positions = vertcat(g.Children.OuterPosition);
% Find the coordinates of the bounding box for all the children.
x0 = positions(:, 1);
y0 = positions(:, 2);
x1 = x0 + positions(:, 3);
y1 = y0 + positions(:, 4);

x0 = min(x0);
y0 = min(y0);
x1 = max(x1);
y1 = max(y1);

% Loop over children
for k = 1:length(g.Children)
    % Translate children so their bounding box is in the lower left corner
    % of the container
    g.Children(k).Position(1) = g.Children(k).Position(1) - x0;
    g.Children(k).Position(2) = g.Children(k).Position(2) - y0;
    % Set units to pixels so the children don't changes size when we shrink
    % the container
    g.Children(k).Units = 'pixels';
end

% Get the bounding box width/height
width = x1 - x0;
height = y1 - y0;

% Shrink the container
g.Position(3) = g.Position(3) * width;
g.Position(4) = g.Position(4) * height;

% Restore the child units
for k = 1:length(g.Children)
    g.Children(k).Units = originalUnits{k};
end
