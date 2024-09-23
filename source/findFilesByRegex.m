function [filePaths, varargout] = findFilesByRegex(rootDirOrTree, regex, matchPath, recurse, includeFolders, includeFiles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%           THIS FUNCTION IS DEPRECATED - USE findFiles INSTEAD
%
% findFilesByRegex: Search rootDir for file paths that match the regex
% usage:  filePaths = findFilesByRegex(rootDir, regex)
%         [filePaths, token1, token2...] = findFilesByRegex(rootDir, regex)
%
% where,
%    rootDirOrTree is a char array representing a directory to recursively 
%       search or a file tree struct of the form returned by buildFileTree
%    regex is char array representing a file regex to match. Note that if
%       the regex contains one or more capturing groups, the text of those
%       captured groups can be retrieved from varargout. Default is '.*'.
%    matchpath is an optional boolean flag indicating whether to apply 
%       the regex to path as well as name. Default is false.
%    recurse is an optional boolean flag indicating whether to apply regex 
%       recursively to subdirectories as well. Default is true. If given as
%       a positive integer, it specifies the maximum recursion depth.
%   includeFolders is an optional boolean flag, include folders in results. 
%       Default is false.
%   includeFiles is an optional boolean flag indicating whether to include 
%       regular files in results, default true.
%   filePaths is a cell array of file paths that matched the regex
%   token1, token2, ... is one or more cell arrays containing the tokens
%       matched by capturing groups in the regex for each file path.
%
% This function is deprecated in favor of 'findFiles'. It may be removed in
%   the future - please update your code accordingly.
%
% This is a function that returns a simple cell array of paths when given a
%   root directory and a regular expression to filter the files and folders
%   within.
%
% This function can also return arrays of capturing group tokens found by 
%   the regex. For example, in a directory containing the files
%
%     test1.txt
%     test4.txt
%     test7.txt
%
%   running the command
%
%     [filePaths, fileNums] = findFilesByRegex(rootDir, 'test([0-9])\.txt')
%
%   Would produce the following arrays:
%
%     filePaths =
%       {'C:\Users\Username\...\test1.txt',
%        'C:\Users\Username\...\test4.txt',
%        'C:\Users\Username\...\test7.txt'}
%
%     fileNums = 
%       {'1', '4', '7'}
%
% See also: dir, buildFileTree, findFiles
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%
%           THIS FUNCTION IS DEPRECATED - USE findFiles INSTEAD
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('regex', 'var') || isempty(regex)
    regex = '.*';
end

if ~exist('matchPath', 'var') || isempty(matchPath)
    matchPath = false;
end

if ~exist('recurse', 'var') || isempty(recurse)
    recurse = true;
end

if ~exist('includeFolders', 'var') || isempty(includeFolders)
    includeFolders = false;
end

if ~exist('includeFiles', 'var') || isempty(includeFiles)
    includeFiles = true;
end

if isstruct(rootDirOrTree)
    % This must be a struct of the form returned by buildFileTree
    useTree = true;
else
    useTree = false;
end

if ~useTree
    if strcmp(rootDirOrTree, '.')
        % To allow for matching paths, convert '.' to absolute path
        rootDirOrTree = pwd();
    elseif strcmp(rootDirOrTree, '..')
        % To allow for matching paths, convert '..' to absolute path
        [rootDirOrTree, ~, ~] = fileparts(pwd());
    end
end

if useTree
    if includeFiles
        files = rootDirOrTree.Files;
    else
        files = {};
    end
    if ~isempty(rootDirOrTree.Dirs)
        dirs = {rootDirOrTree.Dirs.Path};
    else
        dirs = {};
    end
    if includeFolders
        files = [files, dirs];
    end
else
    files = dir(rootDirOrTree);
    % Exclude dot directores - '.' and '..'
    files = files(~cellfun(@isDotDir, {files.name}));
    
    dirs = files([files.isdir]);

    if ~includeFolders
        % Exclude directories
        files = files(~[files.isdir]);
    end
    if ~includeFiles
        % Exclude regular files
        files = files([files.isdir]);
    end
end

numTokens = nargout-1;

filePaths = {};
fileTokens = cell(1, numTokens);
for k = 1:numTokens
    fileTokens{k} = {};
end

for k = 1:length(files)
    if useTree
        filename = rootDirOrTree.Files{k};
    else
        filename = files(k).name;
    end
    if matchPath
        matchName = fullfile(rootDirOrTree, filename);
    else
        [~, name, ext] = fileparts(filename);
        matchName = [name, ext];
    end
    
    [match, tokens] = regexp(matchName, regex, 'start', 'tokens');

    if match
        if useTree
            filepath = fullfile(rootDirOrTree.Path, filename);
        else
            filepath = fullfile(rootDirOrTree, filename);
        end
        filePaths{end+1} = filepath; %#ok<AGROW> 
        if ~isempty(tokens) && numTokens > 0
            tokens = tokens{1};
            for j = 1:length(tokens)
                fileTokens{j}{end+1} = tokens{j};
            end
        end
    end
end

if recurse
    % Recurse over subdirectories
    if ~islogical(recurse) 
        % Recurse is an integer recursion depth, decrement it!
        recurse = recurse - 1;
    end
    % Loop over subdirectories
    for k = 1:length(dirs)
        % Make sure we're not operating on a dot pseudo directory
        if useTree
            [~, dirName, ~] = fileparts(rootDirOrTree.Dirs(k).Path);
        else
            dirName = dirs(k).name;
        end
        if ~any(strcmp(dirName, {'.', '..'}))
            if useTree
                newRootDirOrTree = rootDirOrTree.Dirs(k);
            else
                newRootDirOrTree = fullfile(rootDirOrTree, dirName);
            end
            % Initialize file token cell array for subfolder
            newFileTokens = cell(1, numTokens);
            % Run function recursively to capture output from subfolder 
            %   tree
            [newFilePaths, newFileTokens{:}] = findFilesByRegex(newRootDirOrTree, regex, matchPath, recurse, includeFolders, includeFiles);
            % Append subfolder tree path outputs to current folder path 
            %   outputs
            filePaths = [filePaths, newFilePaths]; %#ok<AGROW> 
            % Initialize fileTokens if it doesn't have any tokens from the
            %   current folder already.
            if isempty(fileTokens)
                fileTokens = cell(1, numTokens);
                for j = 1:numTokens
                    fileTokens{j} = {};
                end
            end
            % Append subfolder tree token outputs to current folder token outputs
            for j = 1:numTokens
                fileTokens{j} = [fileTokens{j}, newFileTokens{j}];
            end
        end
    end
end

varargout = fileTokens;
