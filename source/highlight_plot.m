function rectangles = highlight_plot(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% highlight_plot: Add vertical highlight bars to a plot
% usage:  rectangles = highlight_plot(mask)
%         rectangles = highlight_plot(mask_x, mask)
%         rectangles = highlight_plot(_____, color)
%         rectangles = highlight_plot(ax, ____)
%
% where,
%    mask is a 1xN logical array indicating where the axes should be
%       highlighted.
%    mask_x (optional) is an array of x-values corresponding to each mask
%       value.
%    color (optional) is a color specification. Default is [1, 0, 0, 0.5]
%    ax (optional) is a handle to an axes object. If not provided, gca wil
%       be used.
%    rectangles is an array of rectangle handles for each of the vertical
%       highlight regions.
%
% This function adds a set of vertical highlighted regions to a plot
%   according to the true values in the 1-D mask, and, if provided, the
%   x-values in mask_x.
%
% Example:
%
%   x = 1:1000;
%   y = sin(x/50);
%   figure; plot(x, y);
%   highlight_plot(y > 0.5);
%   highlight_plot(y < -0.2, [0, 0, 1, 0.2]);
%
% See also: 
%
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if first argument is an axes handle
if isa(varargin{1}, 'matlab.graphics.axis.Axes')
    ax = varargin{1};
    varargin(1) = [];
end

% Check if next is just mask or mask_x then mask
if isa(varargin{1}, 'logical')
    % First argument is mask
    mask = varargin{1};
    varargin(1) = [];
elseif isa(varargin{1}, 'numeric')
    % First argument is mask_x
    mask_x = varargin{1};
    mask = varargin{2};
    varargin(1:2) = [];
end

% Check if we have a color at the end
if ~isempty(varargin)
    color = varargin{1};
end

if ~exist('color', 'var') || isempty('color')
    color = [1, 0, 0, 0.5];
end

if ~exist('mask_x', 'var') || isempty(mask_x)
    mask_x = 1:length(mask);
end

if ~exist('ax', 'var') || isempty(ax)
    ax = gca();
end    

% Find start/stop points for mask in indices
[ons, offs] = findOnsetOffsetPairs(mask, [], true);

% Translate indices into actual x values
ons = mask_x(ons);
offs = mask_x(offs);

% Get y-limits of axes, so we know how tall to make the rectangles
ylimits = ylim(ax);
y_min = ylimits(1);
dy = diff(ylimits);

% Loop over on/off locations, and produce rectangles to span them.
rectangles = [];
for k = 1:length(ons)
    on = ons(k);
    off = offs(k);
    dx = off - on + 1;
    rectangles(k) = rectangle(ax, 'Position', [on, y_min - dy, dx, dy * 3], 'FaceColor', color, 'EdgeColor', 'none');
end

ylim(ax, ylimits);