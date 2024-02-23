function alteredPaths = RootSwap(originalPaths, originalRoots, newRoots)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RootSwap: GUI for swapping one drive letter for another in multiple paths
% usage:  alteredPaths = RootSwap(originalPaths)
%
% where,
%    originalPaths is either a char array representing a file path, or a
%       cell array of them.
%    originalRoots is an optional cell array of original roots to swap out.
%       Along with newRoots, if provided, will skip the GUI and simply swap
%       the roots as requested.
%    newRoots is an optional cell array of new roots to swap in. If 
%       provided, it must be the same size as originalRoots Along with
%       originalRoots, if provided, will skip the GUI and simply swap the 
%       roots as requested.
%    alteredPaths is a cell array containing the original paths with the
%       root drive letter swapped according to the user's GUI selections
%
% This is a wrapper for PathSwap that automatically fills in the
%   search/replace fields with the root directory of each path.
%
% If originalRoots and newRoots are provided, this will skip the GUI and
%   simply swap the roots using corresponding elements in the originalRoots
%   and newRoots cell arrays
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

if exist('originalRoots', 'var')
    if ~exist('newRoots', 'var')
        error('If originalRoots is provided, newRoots must also be provided.');
    end
    % User has provided originalRoots and newRoots - skip the GUI and just
    % swap the roots

    if ischar(originalRoots)
        originalRoots = cell(originalRoots);
    end
    if ischar(newRoots)
        newRoots = cell(newRoots);
    end

    alteredPaths = originalPaths;
    for k = 1:length(originalRoots)
        originalRoot = escapeChars(originalRoots{k}, '\', '\\');
        newRoot = newRoots{k};
        alteredPaths = regexprep(alteredPaths, originalRoot, newRoot);
    end
else
    % User has not provided originalRoots/newRoots prepare the GUI!
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
end