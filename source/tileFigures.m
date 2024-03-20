function tiledFig = tileFigures(figureList, tileSize, margin, tightenFactor, removePanels)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tileFigures: Copy an array of figures into a single tiled figure
% usage:  tiledFig = tileFigures(figureList, tileSize, margin, tightenFactor, removePanels)
%
% where,
%    figureList is <description>
%    tileSize is a 1x2 vector containing the x and y size of the desired
%       tile grid
%    margin is the size in pixels of the margin between widgets
%    tightenFactor is a 1x2 array of tightening factors for making the
%       elements in each figure fit more tightly in the grid. For example, 
%       [0.06, 0.03] removes 8% of the space to the left and right, and 5% 
%       of the space on top and bottom of each tile. Default is [0, 0].
%    removePanels is an optional logical indicating whether or not to
%       remove the uipanels containing each figure's transferred contents.
%       If the resulting figure will be exported, this should be set to
%       true, as the exportgraphics function ignores uipanels. Default is
%       true.
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
    tightenFactor (1, 2) double = [0, 0]  % Fraction of space to remove from horizontal and vertical margins to tighten positioning of elements in grid
    removePanels (1, 1) logical = true
end

% Create the figure to tile onto
tiledFig = figure();
% Initialize the list of panels
panels = gobjects().empty;
% Loop over each input figure
for k = 1:length(figureList)
    fig = figureList(k);
    fig.Units = 'normalized';
    % Create a panel to accept the contents of this figure
    panels(k) = uipanel('Parent', tiledFig, 'BorderType', 'none');
    panels(k).Position = [panels(k).Position(1:2), fig.Position(3:4)];
    % Copy the children of the figure onto the panel
    copyobj(fig.Children, panels(k));
end
% Convert all panel children to normalized units
for k = 1:length(figureList)
    tightenChildren(panels(k), tightenFactor);
end
% Tile the panels into the desired grid
tileChildren(tiledFig, tileSize, margin, true);

if removePanels
    % Remove uipanels without removing or affecting child widgets
    tiledFig = removeUIPanels(tiledFig);
end
