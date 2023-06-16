function [filePaths, varargout] = findFilesByRegex(rootDir, regex, matchPath, recurse, includeFolders, includeFiles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findFilesByRegex: Search rootDir for file paths that match the regex
% usage:  filePaths = findFilesByRegex(rootDir, regex)
%         [filePaths, token1, token2...] = findFilesByRegex(rootDir, regex)
%
% where,
%    rootDir is a char array representing a directory to recursively search
%    regex is char array representing a file regex to match. Note that if
%       the regex contains one or more capturing groups, the text of those
%       captured groups can be retrieved from varargout
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
%     fileNms = 
%       {'1', '4', '7'}
%
% See also: dir
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

if strcmp(rootDir, '.')
    % To allow for matching paths, convert '.' to absolute path
    rootDir = pwd();
elseif strcmp(rootDir, '..')
    % To allow for matching paths, convert '..' to absolute path
    [rootDir, ~, ~] = fileparts(pwd());
end

files = dir(rootDir);
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

numTokens = nargout-1;

filePaths = {};
fileTokens = cell(1, numTokens);
for k = 1:numTokens
    fileTokens{k} = {};
end

for k = 1:length(files)
    [~, name, ext] = fileparts(files(k).name);
    if matchPath
        matchName = fullfile(rootDir, files(k).name);
    else
        matchName = [name, ext];
    end
    
    [match, tokens] = regexp(matchName, regex, 'start', 'tokens');

    if match
        filePaths(end+1) = {fullfile(rootDir, files(k).name)};
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
        if ~any(strcmp(dirs(k).name, {'.', '..'}))
            dirpath = fullfile(rootDir, dirs(k).name);
            % Initialize file token cell array for subfolder
            newFileTokens = cell(1, numTokens);
            % Run function recursively to capture output from subfolder 
            %   tree
            [newFilePaths, newFileTokens{:}] = findFilesByRegex(dirpath, regex, matchPath, recurse, includeFolders, includeFiles);
            % Append subfolder tree path outputs to current folder path 
            %   outputs
            filePaths = [filePaths, newFilePaths];
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
