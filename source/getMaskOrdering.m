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

if ~exist('startXY', 'var') || isempty(startXY)
    [x, y] = ind2sub(size(mask), find(mask, 1));
    startXY = [x, y];
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
    
    % Sort neighborhood by how straight each will make the path be
    [~, straightestPathSortIdx] = sort(sum(dxdy .* neighborhoodNorm, 2), 'descend');
    
    found_neighbor = false;
    for idx = straightestPathSortIdx'
        neighborXY = xy + neighborhood(idx, :);
        % Check if neighbor is a member of the set, and in bounds
        if mask(neighborXY(1), neighborXY(2)) && all(neighborXY > [0, 0]) && all(neighborXY <= size(mask))
            % Remove current pixel from set to prevent backtracking
            mask(xy(1), xy(2)) = false;
            % Record current pixel as last pixel
            lastXY = xy;
            % Record selected neigbor as new current pixelZ
            xy = neighborXY;
            found_neighbor = true;
            break;
        end
    end
    if ~found_neighbor
        % Ran out of path to order - we're done.
        break;
    end
end