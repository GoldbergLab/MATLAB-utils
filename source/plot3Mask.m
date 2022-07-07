function ax = plot3Mask(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot3Mask: Plot a 3D logical mask
% usage:  ax = plot3Mask(mask)
%         ax = plot3Mask(___, Name, Value)
%         ax = plot3Mask(ax, ___)
%
% where,
%    ax is an optional axes handle object. If provided, the plot will be
%       made in that axes.
%    mask is a 3D logical array. Any true values will be plotted
%    Name, Value are name-value arguments that can be used to style the
%       plot. The same name-value pairs that the scatter3 function uses are
%       available.
%
% Take a 3D logical mask and plot the location of the true values as a
%   scatter3 plot.
%
% See also: scatter3
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

% Generate 3D coordinate index lists based on the flattened 1D indices of 
% the true values
[x, y, z] = ind2sub(size(mask), find(mask > 0));

% Plot true values
scatter3(ax, x, y, z, varargin{:}); 

% Make axes use the same 
axis(ax, 'equal');
axis(ax, 'vis3d');

% Set axis limits so the empty areas of the mask are also faithfully
% reproduced.
xlim(ax, [1, size(mask, 1)]);
ylim(ax, [1, size(mask, 2)]);
zlim(ax, [1, size(mask, 3)]);