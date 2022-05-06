function orderTreeNodes(tree, order)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% orderTreeNodes: Reorder the nodes of a uitree
% usage:  orderTreeNodes(tree, order)
%
% where,
%    tree is a uitree
%    order is a list of integers representing the desired order of the
%       uitreenodes within the uitree. For example, [1, 3, 2] would result
%       in the first node staying first, the third node being moved to
%       second place, and the second node in third place.
%
% This is a convenience function to make it easier to order uitree nodes.
%   The built in 'move' function is a little inconvenient for some use
%   cases.
%
% See also: setTreeNodeIndex, move, uitree, uitreenode
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nodes = tree.Children;
nodes = nodes(order);
for k = 1:length(nodes)
    setTreeNodeIndex(nodes(k), k);
end