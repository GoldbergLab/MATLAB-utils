function fig = shrinkFigureToContent(fig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% shrinkFigureToContent: shrink a figure to fit its content
% usage:  fig = shrinkFigureToContent(fig)
%
% where,
%    fig is the figure to shrink
%
% THIS FUNCTION WILL BE REMOVED IN THE FUTURE - PLEASE USE shrinkToContent
% INSTEAD - IT IS AN EXACT REPLACEMENT.
%
% This function shrinks a figure to fit its content, without affecting the
%   size/shape/layout of the content itself.
%
% See also: tightenChildren, tileFigures
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning('shrinkFigureToContent has been replaced by shrinkToContent (a drop-in replacement), and will be removed in the future - please update your code.');

fig = shrinkToContent(fig);
