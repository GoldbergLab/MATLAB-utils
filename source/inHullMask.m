function hull_mask = inHullMask(mask_size, hullXY, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inHullMask: Create a solid convex hull mask
% usage:  hull_mask = inHullMask(mask_size, hullXY)
%         hull_mask = inHullMask(mask_size, hullXY, tesselation)
%         hull_mask = inHullMask(mask_size, hullXY, tesselation, tolerance)
%
% where,
%    mask_size is a 1x2 vector indicating the desired output mask size
%    hullXY is a Nx2 vector of x/y pairs indicating the location of the
%       vertices of the convex hull
%    tesselation is an optional triangulation matrix for the convex hull.
%       If omitted or left empty, a triangulation will be computed
%    tolerance is an optional tolerance for considering a point inside the 
%       hull. If omitted or left empty, tolerance will be zero.
%
% Create a mask indicating which points are within the convex hull given by
%   the hullXY vertices, and which are not. This function uses the inhull
%   function written by John D'Errico.
%
% See also: inhull, plotMask
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Since all points within the convex hull are also within the convex hull
%   bounding box, for speed, we can only consider points within the 
%   bounding box. Here we find the coordinate range of those points.
minXY = min(hullXY, [], 1);
maxXY = max(hullXY, [], 1);

% Generate a list of vertices within the bounding box to check
[x, y] = ndgrid(minXY(:, 1):maxXY(:, 1), minXY(:, 2):maxXY(:, 2));
xy = [x(:), y(:)];

% Determine which of the candidate points are actually within the hull
isInHull = inhull(xy, hullXY, varargin{:});
% Find 1D indices for those points
isInHullIdx = sub2ind(mask_size, x(isInHull), y(isInHull));
% Create a blank mask
hull_mask = false(mask_size);
% Set in-hull points to true
hull_mask(isInHullIdx) = true;