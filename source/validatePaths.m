function [alteredPaths, valid] = validatePaths(paths, resolve, offerSwap)

if ~exist('resolve', 'var') || isempty(resolve)
    resolve = true;
end
if ~exist('offerSwap', 'var') || isempty(offerSwap)
    offerSwap = true;
end

alteredPaths = {};
swappableIdx = [];

for k = 1:length(paths)
    path = paths{k};
    if resolve
        try
            path = resolvePath(path);
        catch ME
            if strcmp(ME.identifier, 'resolvePath:CannotResolve')
            else
                rethrow(ME);
            end
        end
    end
    alteredPaths{end+1} = path;
    if offerSwap
        if ~exist(path, 'file')
            swappableIdx(end+1) = k;
        end
    end
end

if offerSwap
    answer = questdlg('Some paths cannot be resolved - would you like to try swapping the file roots?', 'Swap file roots?', 'Yes', 'No', 'Yes');
    if strcmp(answer, 'Yes')
        alteredPaths(swappableIdx) = RootSwap(alteredPaths(swappableIdx));
    end
end

valid = cellfun(@(p)exist(p, 'file')>0, alteredPaths, 'UniformOutput', true);
