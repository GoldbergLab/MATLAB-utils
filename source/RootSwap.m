function alteredPaths = RootSwap(originalPaths)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RootSwap: GUI for swapping one drive letter for another in multiple paths
% usage:  alteredPaths = RootSwap(originalPaths)
%
% where,
%    originalPaths is either a char array representing a file path, or a
%       cell array of them.
%    alteredPaths is a cell array containing the original paths with the
%       root drive letter swapped according to the user's GUI selections
%
% This is a wrapper for PathSwap that automatically fills in the
%   search/replace fields with the root directory of each path.
%
% See also: PathSwap
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is a wrapper for PathSwap that automatically fills in the
% search/replace fields with the root directory of each path.

if ischar(originalPaths)
    originalPaths = cell(originalPaths);
end

roots = {};
for k = 1:length(originalPaths)
    % Discover root by iteratively getting parent directory
    oldPathRoot = '';
    pathRoot = originalPaths{k};
    while ~strcmp(oldPathRoot, pathRoot)
        oldPathRoot = pathRoot;
        pathRoot = fileparts(pathRoot);
    end
    % If the path does not include a root directory, then we'll end up with an empty path
    if ~isempty(pathRoot)
        roots{end+1} = pathRoot;
    end
end
roots = unique(roots);

alteredPaths = PathSwap(originalPaths, roots, roots);