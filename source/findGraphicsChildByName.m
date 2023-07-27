function children = findGraphicsChildByName(parent, name, maxDepth)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findGraphicsChildByName: Find graphics object by name in graphics tree
% usage:  children = findGraphicsChildByName(parent, name)
%         children = findGraphicsChildByName(parent, name, maxDepth)
%
% where,
%    parent is a graphics object that may or may not contain a child
%       somewhere within its graphics object hierarchical tree which
%       matches the given name
%    name is a char array to match to a graphics object's 'String' property
%    maxDepth is the maximum recursion depth to search. If omitted or
%       empty, the function will search infinitely deep.
%    children is am array of one or more graphics objects that match the 
%       given name
%
% This function searches through a graphics "tree" for a given graphics 
%   object (all the graphics objects that are its descendant via the
%   'Child' and 'Parent' properties of graphics objects) to find one or
%   more descendant graphics objects that have a 'String' property that
%   matches the given name.
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Apply defaults
if ~exist('maxDepth', 'var') || isempty(maxDepth)
    maxDepth = [];
end

% Prepare empty array to hold matching children
children = [];

% Check if this graphics object even has children to search through
if ~isprop(parent, 'Children')
    % Nope.
    return;
end

% If max depth is specified, decrement it for the next recursion layer
if ~isempty(maxDepth)
    maxDepth = maxDepth - 1;
end

% Loop over children
for c = 1:length(parent.Children)
    child = parent.Children(c);

    % Does this child match?
    if isprop(child, 'String') && strcmp(child.String, name)
        % It matches - add it to the list of matching children
        children = [children, child];
    end

    % Are we supposed to keep recursing down through the tree?
    if isempty(maxDepth) || maxDepth > 0
        % Yes we are - recursively search the next layer down
        nextChildren = findGraphicsChildByName(child, name, maxDepth);
        % Append any recursively discovered children to the list
        children = [children, nextChildren];
    end
end
