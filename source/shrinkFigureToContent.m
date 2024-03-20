function fig = shrinkFigureToContent(fig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% shrinkFigureToContent: shrink a figure to fit its content
% usage:  fig = shrinkFigureToContent(fig)
%
% where,
%    fig is the figure to shrink
%    <arg2> is <description>
%    <argN> is <description>
%
% This function shrinks a figure to fit its content, without affecting the
%   size/shape/layout of the content itself.
%
% See also: tightenChildren, tileFigures
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Store the original child units so we can restore it later
originalUnits = {fig.Children.Units};
% Set children to normalized units
set(fig.Children, 'Units', 'normalized');
% Get all child positions
positions = vertcat(fig.Children.OuterPosition);
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
for k = 1:length(fig.Children)
    % Translate children so their bounding box is in the lower left corner
    % of the figure
    fig.Children(k).Position(1) = fig.Children(k).Position(1) - x0;
    fig.Children(k).Position(2) = fig.Children(k).Position(2) - y0;
    % Set units to pixels so the children don't changes size when we shrink
    % the figure
    fig.Children(k).Units = 'pixels';
end

% Get the bounding box width/height
width = x1 - x0;
height = y1 - y0;

% Shrink the figure
fig.Position(3) = fig.Position(3) * width;
fig.Position(4) = fig.Position(4) * height;

% Restore the child units
for k = 1:length(fig.Children)
    fig.Children(k).Units = originalUnits{k};
end
