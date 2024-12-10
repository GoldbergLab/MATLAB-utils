function [matchedFiles, unmatchedFiles, allSessionIds, fileIds] = matchFileStreams(root, streamIdentifierRegex, sessionIdentifierRegex, fileIndexRegex, options)
arguments
    root char
    streamIdentifierRegex char
    sessionIdentifierRegex char
    fileIndexRegex char
    options.Recursive logical = true
end

if isempty(sessionIdentifierRegex)
    % This regex will treat all files as the same session
    sessionIdentifierRegex = '()';
end

% Find files within root that match the stream identifier regex
paths = findFiles(root, streamIdentifierRegex, "CaseSensitive", false, "IncludeFolders", false, "IncludeFiles", true, "SearchSubdirectories", options.Recursive, "MatchWholePath", false);
% Get filenames (without paths)
[~, filenames, ~] = fileparts(paths);
% Group files according to stream identifier
[streamIds, sortedFilenames, sortedIdx] = regexpgroup(filenames, streamIdentifierRegex);
numStreamIds = length(streamIds);

% Sort file paths as well, and generate sorted list of file indices and 
%   session ids for each stream
streamFileIndices = repmat({''}, size(streamIds));
sessionFileIds = repmat({''}, size(streamIds));
sortedFilepaths = cell(size(streamIds));
for streamIdx = 1:numStreamIds
    sortedFilepaths{streamIdx} = paths(sortedIdx{streamIdx});
    streamFileIndices{streamIdx} = regexp(sortedFilenames{streamIdx}, fileIndexRegex, 'tokens');
    streamFileIndices{streamIdx} = cellfun(@flattenToken, streamFileIndices{streamIdx}, 'UniformOutput', false);
    sessionFileIds{streamIdx} = regexp(sortedFilenames{streamIdx}, sessionIdentifierRegex, 'tokens');
    sessionFileIds{streamIdx} = cellfun(@flattenToken, sessionFileIds{streamIdx}, 'UniformOutput', false);
end

% Match up files between the different streams.
allFileIdx = unique([streamFileIndices{:}]);
numFileIdx = length(allFileIdx);
allSessionIds = unique([sessionFileIds{:}]);
numSessionIds = length(allSessionIds);
% matchedFiles will hold a 3D matrix of matched files, such that
%   matchedFiles{k, :, j} will represent all the files that are matched as
%   the kth file in their respective streams for session j
matchedFiles = repmat({repmat({''}, [numFileIdx, numStreamIds])}, [1, numSessionIds]);
% Keep track of file IDs
fileIds = repmat({repmat({''}, [1, numFileIdx])}, [1, numSessionIds]);
for sessionIdx = 1:numSessionIds
    sessionId = allSessionIds{sessionIdx};
    for fileIdx = 1:numFileIdx
        fileId = allFileIdx{fileIdx};
        fileIds{sessionIdx}{fileIdx} = fileId;
        for streamIdx = 1:numStreamIds
            files = sortedFilepaths{streamIdx}(strcmp(streamFileIndices{streamIdx}, fileId) & strcmp(sessionFileIds{streamIdx}, sessionId));
            if ~isempty(files)
                matchedFiles{sessionIdx}(fileIdx, streamIdx) = files;
            end
        end
    end
end

unmatchedFiles = {};
for sessionIdx = 1:numSessionIds
    % Remove unused streams for each session
    unmatchedColumns = all(cellfun(@isempty, matchedFiles{sessionIdx}), 1);
    matchedFiles{sessionIdx}(:, unmatchedColumns) = [];

    % Record unmatched files
    unmatchedRows = any(cellfun(@isempty, matchedFiles{sessionIdx}), 2);
    unmatchedFiles = [unmatchedFiles; unique(matchedFiles{sessionIdx}(unmatchedRows, :))]; %#ok<AGROW> 
    % Remove any rows that have one or more matches missing
    matchedFiles{sessionIdx}(unmatchedRows, :) = [];
    fileIds{sessionIdx}(unmatchedRows) = [];
end

end

function token = flattenToken(token)
    while iscell(token)
        if isempty(token)
            token = '';
        else
            token = token{1};
        end
    end
end