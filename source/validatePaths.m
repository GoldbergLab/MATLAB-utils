function [alteredPaths, valid] = validatePaths(paths, resolve, offerSwap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% validatePaths: Check if paths point to files/folders that exist, and if
%   not, give user opportunity to quickly swap drive letter on paths using
%   a simple GUI.
% usage:  [alteredPaths, valid] = validatePaths(paths)
%         [alteredPaths, valid] = validatePaths(paths, resolve)
%         [alteredPaths, valid] = validatePaths(paths, resolve, offerSwap)
%
% where,
%    paths is a single char array path or a cell array of paths
%    resolve is an optional boolean flag indicating whether or not to
%       attempt to resolve relative paths as absolute paths (paths that 
%       start with a drive root). Default is true.
%    offerSwap is an optional boolean flag indicating whether or not to
%       offer user a chance to swap drive roots using a GUI. Default is
%       true.
%    alteredPaths is a cell array of processed paths, which may or may not
%       be resolved and fixed by swapping drive letters
%    valid is a boolean mask indicating which of the paths in alteredPaths
%       are valid (point to files/folders that exist).
%
% This function takes a list of paths and optionally resolves any relative
%   paths to absolute paths, and also offers user the opportunity to swap
%   out drive letters in paths if any of the paths do not exist.
%
% See also: RootSwap, PathSwap, exist, resolvePath
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Handle default inputs
if ~exist('resolve', 'var') || isempty(resolve)
    resolve = true;
end
if ~exist('offerSwap', 'var') || isempty(offerSwap)
    offerSwap = true;
end

if ischar(paths)
    % If user passed a single path as a char array, wrap it in a cell array
    paths = {paths};
end

alteredPaths = cell(size(paths));
swappableIdx = [];

% Loop over provided paths
for k = 1:length(paths)
    path = paths{k};
    if resolve
        % If requested by user, attempt to resolve relative paths to
        %   absolute paths.
        try
            path = resolvePath(path);
        catch ME
            if strcmp(ME.identifier, 'resolvePath:CannotResolve')
                % Can't resolve path probably because it doesn't exist, no worries, move on
            else
                % Something else went wrong
                rethrow(ME);
            end
        end
    end
    alteredPaths{k} = path;
    if offerSwap
        if ~isempty(path) && ~exist(path, 'file')
            % If this file doesn't exist, and the user wants an opportunity
            %   to swap drive roots, add this to a list to be swapped.
            swappableIdx(end+1) = k;
        end
    end
end

if offerSwap && ~isempty(swappableIdx)
    % If there is at leats one path found to not exist, and the user 
    %   requests it, offer the user the opportunity to swap paths
    answer = questdlg('Some paths cannot be resolved - would you like to try swapping the file roots?', 'Swap file roots?', 'Yes', 'No', 'Yes');
    if strcmp(answer, 'Yes')
        % Give user GUI to swap paths
        alteredPaths(swappableIdx) = RootSwap(alteredPaths(swappableIdx));
    end
end

% Make mask indicating which paths are valid after all that.
valid = cellfun(@(p)exist(p, 'file')>0, alteredPaths, 'UniformOutput', true);
