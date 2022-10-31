function xyConnected = calculateMaskPolygon(xy)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculateMaskPolygon: Calculate a list of pixels to form a polygon
% usage:  xyConnected = calculateMaskPolygon(xy)
%
% where,
%    xy is a Nx2 list of coordinates representing vertices of the polygon
%    xyConnected is a Nx2 list of coordinates representing the pixels
%       needed to form lines connecting the given vertices
%
% This function creates a list of pixels to effectively connect the given
%   vertices on a mask.
%
% See also: drawMaskPolygon
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize list of boundary coordinates
xyConnected = [];

% Ensure polygon is closed
if ~all(xy(1, :) == xy(end, :))
    xy = [xy; xy(1, :)];
end

% Loop over vertices and construct list of points to connect them with
% lines
for k = 1:(size(xy, 1)-1)
    xy1 = xy(k, :);
    xy2 = xy(k+1, :);
    if any(abs(xy2 - xy1) > 1)
        xyL = connectMaskLine(xy1, xy2);
        xyConnected = [xyConnected; xyL];
    else
        xyConnected = [xyConnected; xy(k:k+1, :)];
    end
end

% Eliminate repeats
xyConnected(all(xyConnected(1:end-1, :) == xyConnected(2:end, :), 2), :) = [];

function xyL = connectMaskLine(xy1, xy2)
n = max(round(abs(xy2-xy1)))+1;
xyL = [round(linspace(xy1(1), xy2(1), n)); round(linspace(xy1(2), xy2(2), n))]';