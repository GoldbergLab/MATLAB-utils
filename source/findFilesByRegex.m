function [filepaths, varargout] = findFilesByRegex(rootDir, regex, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findFilesByRegex: Search rootDir for file paths that match the regex
% usage:  filepaths = findFilesByRegex(rootDir, regex)
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
%
% This is a function that returns a simple cell array of paths when given a
%   root directory and a regular expression to filter the files and folders
%   within.
%
% See also: dir
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin>2
    matchPath = varargin{1};
else
    matchPath = false;
end
if nargin>3
    recurse = varargin{2};
else
    recurse = true;
end
if nargin>4
    includeFolders = varargin{3};
else
    includeFolders = false;
end
if nargin>5
    includeFiles = varargin{4};
else
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

filepaths = {};
varargout = {};
for k = 1:length(files)
    [~, name, ext] = fileparts(files(k).name);
    if matchPath
        matchName = fullfile(rootDir, files(k).name);
    else
        matchName = [name, ext];
    end
    
    [match, tokens] = regexp(matchName, regex, 'start', 'tokens');

    if match
        filepaths(end+1) = {fullfile(rootDir, files(k).name)};
        if ~isempty(tokens) && nargout > 1
            tokens = tokens{1};
            if isempty(varargout)
                varargout = cell(1, length(tokens));
                for j = 1:length(tokens)
                    varargout{j} = {};
                end
            end
            for j = 1:length(tokens)
                varargout{j}{end+1} = tokens{j};
            end
        end
    end
end

if recurse
    if ~islogical(recurse) 
        % recurse is an integer recursion depth, decrement it!
        recurse = recurse - 1;
    end
    for k = 1:length(dirs)
        if ~any(strcmp(dirs(k).name, {'.', '..'}))
            dirpath = fullfile(rootDir, dirs(k).name);
            filepaths = [filepaths, findFilesByRegex(dirpath, regex, matchPath, recurse, includeFolders, includeFiles)];
        end
    end
end

