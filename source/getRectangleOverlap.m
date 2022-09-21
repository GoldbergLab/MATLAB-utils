function [xo1, xo2, yo1, yo2, overlaps] = getRectangleOverlap(x1, x2, y1, y2, X1, X2, Y1, Y2, plot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getRectangleOverlap: Find the overlap between two rectangles
% usage:  [xo1, xo2, yo1, yo2, overlaps] = getRectangleOverlap(x1, x2, y1, y2, X1, X2, Y1, Y2, plot)
%
% where,
%    x1 is the left x coordinate of rectangle 1
%    x2 is the right x coordinate of rectangle 1
%    y1 is the top y coordinate of rectangle 1
%    y2 is the bottom y coordinate of rectangle 1
%    X1 is the left x coordinate of rectangle 2
%    X2 is the right x coordinate of rectangle 2
%    Y1 is the top y coordinate of rectangle 2
%    Y2 is the bottom y coordinate of rectangle 2
%    plot is an optional boolean indicating whether or not to plot a
%       graphical representation of the overlap calculation. Default is
%       false.
%    xo1 is the left x coordinate of the overlap rectangle
%    xo2 is the right x coordinate of the overlap rectangle
%    yo1 is the top y coordinate of the overlap rectangle
%    yo2 is the bottom y coordinate of the overlap rectangle
%    overlaps is a boolean indicating whether or not the two input
%       rectangles overlap
%
% This function finds the rectangular region that represents the overlap of
%   two rectangular regions. The input coordinates numbered "1" must be 
%   smaller than the corresponding coordinates numbered "2"
%
% See also: getSegmentOverlap
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('plot', 'var') || isempty(plot)
    plot = false;
end

[xo1, xo2, overlapX] = getSegmentOverlap(x1, x2, X1, X2);
[yo1, yo2, overlapY] = getSegmentOverlap(y1, y2, Y1, Y2);

overlaps = overlapX && overlapY;

if plot()
    f = figure;
    ax = axes(f);
    rectangle('Position', [x1, y1, x2-x1+1, y2-y1+1], 'Parent', ax);
    rectangle('Position', [X1, Y1, X2-X1+1, Y2-Y1+1], 'Parent', ax);
    if overlaps
        rectangle('Position', [xo1, yo1, xo2-xo1+1, yo2-yo1+1], 'Parent', ax, 'FaceColor', [0, 1, 0]);
    end
    xlim(ax, [min([x1, x2, X1, X2])-10, max([x1, x2, X1, X2])+10]);
    ylim(ax, [min([y1, y2, Y1, Y2])-10, max([y1, y2, Y1, Y2])+10]);
end