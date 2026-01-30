function handles = ribbonplot(x, y, yerror, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ribbonplot: Create a line plot with error ribbons
% usage: handles = ribbonplot(x, y, yerror, varargin)
%
% where,
%    x is a vector of x-values for the line plot, or an empty list to use 
%       array indices as x values
%    y is a vector of y-values for the line plot
%    yerror is either
%       A single error value giving a constant ribbon thickness for both 
%           the + and - sides
%       A 1x2 set of error values giving constant error values separately
%           for the + and - sides
%       A 1xN vector of error values, one for each y value, for both the 
%           + and - sides
%       A 1x2 cell array of 1xN error values giving a separate error value
%           for the + and - sides at each point
%       Name/Value pairs may include
%           RibbonColor - the color of the ribbon
%           RibbonAlpha - the transparency (alpha) value of the ribbon,
%               from 0 (opaque) to 1 (transparent)
%           Any other arguments that would normally be supplied to the
%               plot function.
%    handles is a 1x2 array of graphics handles for the ribbon and line 
%       plot
%
% <long description>
%
% See also: plot
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);

if isempty(x)
    x = 1:length(y);
end

if isfield(options, 'Parent')
    defaultAxes = options.Parent;
else
    defaultAxes = gca();
end

ribbonOptions = struct();
ribbonOptionNames = {'RibbonColor', 'RibbonAlpha', 'Parent'};
ribbonOptionDefaults = {'b', 1, defaultAxes};

% Separate out ribbon-specific options
for k = 1:length(ribbonOptionNames)
    ribbonOptionName = ribbonOptionNames{k};
    ribbonOptionDefault = ribbonOptionDefaults{k};
    if isfield(options, ribbonOptionName)
        ribbonOptions.(ribbonOptionName) = options.(ribbonOptionName);
        options = rmfield(options, ribbonOptionName);
    else
        ribbonOptions.(ribbonOptionName) = ribbonOptionDefault;
    end
end

plotOptions = namedargs2cell(options);

if isscalar(yerror)
    % User passed one yerror value for + and -
    yerror = {yerror*ones(size(x)), yerror*ones(size(x))};
elseif ~iscell(yerror) && isvector(yerror) && length(yerror) == 2
    % User passed two yerror values, one for + one for -
    yerror = {yerror(1)*ones([1, size(x)]), yerror(2)*ones([1, size(x)])};
elseif ~iscell(yerror) && isvector(yerror) && length(yerror) > 2 && length(yerror) == length(y)
    % User passed a 1xN vector of yerror to use for both + and -
    yerror = {yerror, yerror};
elseif iscell(yerror) && length(yerror) == 2 && isvector(yerror{1}) && length(yerror{1}) == length(y) && length(yerror{2}) == length(y)
    % User passed a 1x2 cell array of 1xN arrays of yerror values
else
    error('Invalid entry for yerror; must be a number, a 1x2 vector of numbers, a 1xN vector of numbers, or a cell array of two 1xN vectors of numbers ')
end

if ~all(yerror{1} >= 0) || ~all(yerror{2} >= 0)
    error('All yerror values must be greater than or equal to zero');
end

ribbonX = [x, flip(x)];
ribbonY = [y+yerror{1}, flip(y-yerror{2})];

handles(1) = patch(ribbonX, ribbonY, ribbonOptions.RibbonColor, ...
    'Parent', ribbonOptions.Parent, ...
    'FaceAlpha', ribbonOptions.RibbonAlpha ...
    );
hold(ribbonOptions.Parent, 'on');
handles(2) = plot(x, y, 'Parent', ribbonOptions.Parent, plotOptions{:});