function ax = plotMask(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plotMask: Plot a 3D logical mask
% usage:  ax = plotMask(mask)
%         ax = plotMask(___, Name, Value)
%         ax = plotMask(ax, ___)
%
% where,
%    ax is an optional axes handle object. If provided, the plot will be
%       made in that axes.
%    mask is a 2D logical array. Any true values will be plotted
%    Name, Value are name-value arguments that can be used to style the
%       plot. The same name-value pairs that the scatter3 function uses are
%       available.
%
% Take a 2D logical mask and plot the location of the true values as a
%   scatter plot.
%
% See also: scatter
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
    firstArgumentIsAxes = strcmp(get(varargin{1}, 'type'), 'axes');
catch
    firstArgumentIsAxes = false;
end

if firstArgumentIsAxes
    ax = varargin{1};
    mask = varargin{2};
    varargin(1:2) = [];
else
    f = figure;
    ax = axes(f);
    mask = varargin{1};
    varargin(1) = [];
end

% Generate 2D coordinate index lists based on the flattened 1D indices of 
% the true values
[x, y] = ind2sub(size(mask), find(mask > 0));

% Plot true values
scatter(ax, x, y, varargin{:}); 

% Make axes use the same unit sizes, and freeze them for 3D viewing
axis(ax, 'equal');

% Set axis limits so the empty areas of the mask are also faithfully
% reproduced.
xlim(ax, [1, size(mask, 1)]);
ylim(ax, [1, size(mask, 2)]);