function [xo1, xo2, overlaps] = getSegmentOverlap(x1, x2, X1, X2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getSegmentOverlap: Find the overlap between two 1D segments
% usage:  [xo1, xo2, overlaps] = getSegmentOverlap(x1, x2, X1, X2)
%
% where,
%    x1 is the left x coordinate of segment 1
%    x2 is the right x coordinate of segment 1
%    X1 is the left x coordinate of segment 2
%    X2 is the right x coordinate of segment 2
%    xo1 is the left x coordinate of the overlap segment
%    xo2 is the right x coordinate of the overlap segment
%    overlaps is a boolean indicating whether or not the two input
%       segments overlap
%
% This function finds the 1D segment that represents the overlap of
%   two input segments regions. The input coordinates numbered "1" must be 
%   smaller than the corresponding coordinates numbered "2"
%
% See also: getRectangleOverlap
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xo1 = max(x1, X1);
xo2 = min(x2, X2);

overlaps = (x1 <= X1 && x2 >= X1) || (X1 <= x1 && X2 >= x1);
