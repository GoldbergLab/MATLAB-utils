function [xOrdered, yOrdered] = getMaskOrdering(mask, startXY, startDXDY)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getMaskOrdering: Get the straightest ordering of a mask's true values
% usage:  [xOrdered, yOrdered] = getMaskOrdering(mask)
%         [xOrdered, yOrdered] = getMaskOrdering(mask, startXY, startDXDY)
% where,
%    mask is a 2D logical mask
%    startXY is an optional argument indicating which coordinates to use as
%       a starting point for the ordering
%    startDXDY is an optional argument indicating which initial direction
%       to aim for in the ordering.
%       
% This function creates an ordering for a mask. That is, it attempts to
%   plot the straightest path possible through the true vertices of the 
%   mask. The output is lists of ordered x and y coordinates
%
% See also: plotMask
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

neighborhoodX = [1, 1, 1, 0, -1, -1, -1, 0];
neighborhoodY = [-1, 0, 1, 1, 1, 0, -1, -1];
neighborhood = [neighborhoodX', neighborhoodY'];
neighborhoodNorm = neighborhood ./ sqrt(sum(neighborhood .* neighborhood, 2));
[x, y] = ind2sub(size(mask), find(mask));
indices = sub2ind(size(mask), x, y);
indexArray = cset(nan(size(mask)), indices, x, y);

if ~exist('startXY', 'var') || isempty(startXY)
    startXY = [x(1), y(1)];
end
if ~exist('startDXDY', 'var') || isempty(startDXDY)
    startDXDY = [1, 0];
end
xy = startXY;
lastXY = xy - startDXDY;
if ~mask(xy(1), xy(2))
    error('Starting point was not in the set of true points in mask');
end
xOrdered = [];
yOrdered = [];
while true
    xOrdered = [xOrdered, xy(1)];
    yOrdered = [yOrdered, xy(2)];
    dxdy = xy - lastXY;
    neighborsXY = xy + neighborhood;
    inBoundsNeighborMask = all(neighborsXY > [0, 0], 2) & all(neighborsXY <= size(mask), 2);
    neighborsXY = neighborsXY(inBoundsNeighborMask, :);
    neighborhoodNorm = neighborhoodNorm(inBoundsNeighborMask, :);
    validNeighborMask = cget(mask, neighborsXY(:, 1), neighborsXY(:, 2));
    if sum(validNeighborMask) == 0
        % No valid neighbors left - we're done.
        break;
    end
    validNeighborsXY = neighborsXY(validNeighborMask, :);
    validNeighborhoodNorm = neighborhoodNorm(validNeighborMask, :);
    [~, straightestIdx] = max(sum(dxdy .* validNeighborhoodNorm, 2));
    mask(xy(1), xy(2)) = false;
    lastXY = xy;
    xy = validNeighborsXY(straightestIdx, :);
end