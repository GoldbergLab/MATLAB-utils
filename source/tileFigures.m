function tiledFig = tileFigures(figureList, tileSize, margin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tileFigures: Copy an array of figures into a single tiled figure
% usage:  tiledFig = tileFigures(figureList, tileSize, margin)
%
% where,
%    figureList is <description>
%    tileSize is a 1x2 vector containing the x and y size of the desired
%       tile grid
%    margin is the size in pixels of the margin between widgets
%    tiledFig is the handle to the tiled figure
%
% Take a bunch of figures, tile them onto a grid on a new figure. Please
% note that Brian wrote this faster than ChatGPT could.
%
% See also: tileChildren
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    figureList matlab.ui.Figure     % List of figures to tile
    tileSize (1, 2) double          % 2-vector containing the x and y size of the desired axes grid
    margin (1, 1) double = 10;      % Size in pixels of the margin between widgets
end

% Create the figure to tile onto
tiledFig = figure();
% Initialize the list of panels
panels = gobjects().empty;
% Loop over each input figure
for k = 1:length(figureList)
    fig = figureList(k);
    % Create a panel to accept the contents of this figure
    panels(k) = uipanel('Parent', tiledFig, 'BorderType', 'none');
    % Copy the children of the figure onto the panel
    copyobj(fig.Children, panels(k));
end
% Tile the panels into the desired grid
tileChildren(tiledFig, tileSize, margin);