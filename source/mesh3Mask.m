function ax = mesh3Mask(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mesh3Mask: Make a mesh surface plot from a 3D logical mask
% usage:  ax = mesh3Mask(mask)
%         ax = mesh3Mask(___, Name, Value)
%         ax = mesh3Mask(ax, ___)
%
% where,
%    ax is an optional axes handle object. If provided, the plot will be
%       made in that axes.
%    mask is a 3D logical array to make a mesh surface plot from
%    Name, Value are name-value arguments that can be used to style the
%       plot. The same name-value pairs that the trisurf function uses are
%       available.
%
% Take a 3D logical mask and make a mesh plot of the surface of any true
%   value blobs.
%
% See also: plot3Mask, trisurf
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

blobs = get3MaskBoundaryTriangulation(mask);

originalHoldStatus = ishold(ax);
hold(ax, 'on');
for j = 1:size(blobs(1))
    connectivityList = blobs{j, 1};
    vertices = blobs{j, 2};
    trisurf(connectivityList, vertices(:, 1), vertices(:, 2), vertices(:, 3), 'Parent', ax, varargin{:});
end

if originalHoldStatus
    hold(ax, 'on');
else
    hold(ax, 'off');
end

% Get true values on the surface of any true blobs
surface_mask = get3MaskSurface(mask);

% Generate 3D coordinate index lists based on the flattened 1D indices of 
% the true values
[x, y, z] = ind2sub(size(surface_mask), find(surface_mask > 0));

k = delaunay(x, y, z);
% x = x(k(:, 1));
% y = y(k(:, 2));
% z = z(k(:, 3));

trisurf(k, x, y, z, 'Parent', ax);

% Make axes use the same unit sizes, and freeze them for 3D viewing
axis(ax, 'equal');
axis(ax, 'vis3d');

% Set axis limits so the empty areas of the mask are also faithfully
% reproduced.
xlim(ax, [1, size(mask, 1)]);
ylim(ax, [1, size(mask, 2)]);
zlim(ax, [1, size(mask, 3)]);