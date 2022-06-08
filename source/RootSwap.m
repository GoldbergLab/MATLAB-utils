function alteredPaths = RootSwap(originalPaths)
% This is a wrapper for PathSwap that automatically fills in the
% search/replace fields with the root directory of each path.

if ischar(originalPaths)
    originalPaths = cell(originalPaths);
end

roots = {};
for k = 1:length(originalPaths)
    oldPathRoot = '';
    pathRoot = originalPaths{k};
    while ~strcmp(oldPathRoot, pathRoot)
        oldPathRoot = pathRoot;
        pathRoot = fileparts(pathRoot);
    end
    if ~isempty(pathRoot)
        roots{end+1} = pathRoot;
    end
end
roots = unique(roots);

alteredPaths = PathSwap(originalPaths, roots, roots);