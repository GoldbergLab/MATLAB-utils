function setTreeNodeIndex(node, newIndex)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setTreeNodeIndex: Set the index of a uitreenode in a uitree
% usage:  setTreeNodeIndex(node, newIndex)
%
% where,
%    node is a uitreenode
%    newIndex is the index where node should be moved to. If the index is
%       greater than the number of children in the uitree, the node will be
%       put at the end.
%
% This is a convenience function to make it easier to order uitree nodes.
%   The built in 'move' function is a little inconvenient for some use
%   cases.
%
% See also: orderTreeNodes, move, uitree, uitreenode
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get list of child nodes, which should include the node in question
siblings = node.Parent.Children;
% Remove the node in question from the list of siblings
siblings(siblings == node) = [];
if isempty(siblings)
    % There are no other nodes, just the node to be moved, so there's
    % nothing to do.
    return
end
if newIndex > length(siblings)
    newIndex = length(siblings);
    direction = 'after';
else
    direction = 'before';
end
move(node, siblings(newIndex), direction);