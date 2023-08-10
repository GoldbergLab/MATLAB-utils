function varargout = ndgridrange(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ndgridrange: create coordinate grids based on grid ranges
% usage:  [X1, X2, ..., XN] = <function name>(endRange)
%         [X1, X2, ..., XN] = <function name>(startRange, endRange)
%
% where,
%    endRange is a 1xN vector containing the desired end of the coordinate
%       ranges
%    startRange is an optional 1xN vector containing the desired start of
%       the coordinate ranges. If omitted, each coordinate range will start
%       at 1.
%    X1, X2, ..., XN are coordinate grid arrays as given by ndgrid
%
% This is a shortcut for the built in ndgrid function for the common use
%   case that you want to specify a range of consecutive integers as the
%   grid vectors. Thus these two calls are equivalent:
%
%   [x1, x2, ..., xN] = ndgrid(a1:b1, a2:b2, ..., aN:bN);
%   [x1, x2, ..., xN] = ndgridrange([a1, a2, ..., aN], [b1, b2, ..., bN]);
%
% as are these:
%
%   [x1, x2, ..., xN] = ndgrid(1:b1, 1:b2, ..., 1:bN);
%   [x1, x2, ..., xN] = ndgridrange([b1, b2, ..., bN]);
%
% See also: ndgrid
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if user supplied start coordinates
if nargin == 2
    % Yep
    ends = varargin{2};
    starts = varargin{1};
else
    % Nope
    ends = varargin{1};
    starts = ones(size(ends));
end

% Construct grid vectors
ranges = arrayfun(@(a, b)a:b, starts, ends, 'UniformOutput', false);
% Prepare output array
varargout = cell(size(ends));
% Construct coordinate grids
[varargout{:}] = ndgrid(ranges{:});