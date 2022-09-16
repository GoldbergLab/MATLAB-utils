function lines = linec(x, y, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% linec: Draw a primitive line object with multiple colors
% usage:  lines = linec(x, y, ...)
%         lines = linec(x, y, 'Color', colors, ...)
%
% where,
%    x is a list of x coordinates for the line segments
%    y is a list of y coordinates for the line segments
%    colors is a color specification that can be either:
%       a) A 1x3 RGB triplet
%       b) A hexadecimal color code
%       c) A named color
%       d) A N x 3 RGB array, where N == length(x) == length(y)
%       e) A 1 x N array of color palette indices
%    lines is an array of handles to primitive line objects. Each line
%       object is a single color section of the overall line.
%    ... you may also use any other Name/Value pairs specified by the line
%       function documentation
%
% linec behaves almost exactly the same as the line function, but it allows
%   a different set of 'Color' parameter types. In addition to the normal
%   types, it also allows:
%   - Nx3 array of RGB color values, where N == length(x) == length(y)
%   - 1xN array of color palette indices, where N == length(x) == length(y)
%   One other difference is that the linec function currently only handles
%       2D lines.
%
% Note that this function can be fairly slow for a large number of 
%   different colors (> 100). For small numbers of colors, it should be
%   only slightly slowe than the line function.
%
% See also: line
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parentIdx = find(strcmp(varargin, 'Parent'));
if isempty(parentIdx)
    parent = gca();
else
    parent = varargin{parentIdx + 1};
    varargin(parentIdx:parentIdx+1) = [];
    if ~isvalid(parent)
        parent = gca();
    end
end

colorIdx = find(strcmp(varargin, 'Color'));
if isempty(colorIdx)
    colors = {[]};
    xs = {x};
    ys = {y};
else
    color = varargin{colorIdx + 1};
    varargin(colorIdx:colorIdx+1) = [];

    if ischar(color)
        % Single color string provided
        colors = {color};
        xs = {x};
        ys = {y};
    elseif isnumeric(color)
        if isrow(color) && length(color) == 3
            % Single RGB triplet provided
            colors = color;
            xs = {x};
            ys = {y};
        elseif size(color, 2) == 3 && size(color, 1) > 1
            % 3-column array of RGB triplets provided, one color
            % per row
            idx = 1;
            colors = {};
            xs = {};
            ys = {};
            while idx <= size(color, 1)
                matchColor = color(idx, :);
                matches = ismember(color(idx:end, :), matchColor, 'rows');
                firstOffset = find(~matches, 1);
                if isempty(firstOffset)
                    % No offsets, so this color goes all the way to the end
                    firstOffset = length(matches) + 1;
                end
                colors{end+1} = matchColor;
                xs{end+1} = x(idx:idx+firstOffset-2);
                ys{end+1} = y(idx:idx+firstOffset-2);
                idx = firstOffset;
            end
        elseif isvector(color)
            % Color palette index has been provided
            idx = 1;
            colors = {};
            xs = {};
            ys = {};
            while idx <= length(color)
                matchColor = color(idx);
                matches = color(idx:end) == matchColor;
                firstOffset = find(~matches, 1);
                if isempty(firstOffset)
                    % No offsets, so this color goes all the way to the end
                    firstOffset = length(matches) + 1;
                end
                colors{end+1} = matchColor;
                xs{end+1} = x(idx:min(idx+firstOffset-1, length(x)));
                ys{end+1} = y(idx:min(idx+firstOffset-1, length(x)));
                idx = idx + firstOffset - 1;
            end
            colors = cellfun(@(c)parent.Colormap(c, :), colors, 'UniformOutput', false);
        else
            error('Color argument must be a color name, RGB triplet, RGB Nx3 array, or 1xN array of palette indices.');
        end
    else
        error('Unrecognized class for Color argument: %s', class(color));
    end
end

lines = [];
for segmentNumber = 1:length(colors)
    if isempty(colors{segmentNumber})
        lines(end+1) = line(xs{segmentNumber}, ys{segmentNumber}, 'Parent', parent, varargin{:});
    else
        lines(end+1) = line(xs{segmentNumber}, ys{segmentNumber}, 'Color', colors{segmentNumber}, 'Parent', parent, varargin{:});
    end
end
