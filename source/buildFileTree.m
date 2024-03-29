function tree = buildFileTree(rootDir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% buildFileTree: Build a file tree for the given root directory
% usage:  tree = buildFileTree(rootDir)
%
% where,
%    rootDir is a char array representing a directory to recursively build
%       a file tree for
%    tree is a recursive struct containing the following fields:
%       Path = a char array representing the directory path
%       Dirs = an array of trees, one for each subdirectory
%       Files = a cell array of char arrays representing filenames within 
%           this directory.
%
% This is a function that builds a file tree representing all the files and
%   folders within a given root directory. It is built to use with
%   findFilesByRegex, to greatly speed up repeated searches of large file
%   systems. For example, this code can be sped up:
%
%       rootDir = 'C:\path\to\root';
%       list1 = findFilesByRegex(rootDir, regex1);
%       list2 = findFilesByRegex(rootDir, regex2);
%       ...
%       listN = findFilesByRegex(rootDir, regexN);
%
%   by building a tree first, like so:
%
%       rootDir = 'C:\path\to\root';
%       tree = buildFileTree(rootDir);
%       list1 = findFilesByRegex(tree, regex1);
%       list2 = findFilesByRegex(tree, regex2);
%       ...
%       listN = findFilesByRegex(tree, regexN);
%
% See also: findFilesByRegex, dir
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% Create a list of files and subdirectories
dirMask = [files.isdir];
dirs = files(dirMask);
files = files(~dirMask);

% Construct full paths for files and directories
fullpathify = @(d)fullfile(rootDir, d.name);
dirPaths = arrayfun(fullpathify, dirs, 'UniformOutput', false);
filePaths = {files.name};

% Assign the root dir path to the Path field
tree.Path = rootDir;
% Recursively create trees for each subdirectory in the Dirs field
tree.Dirs = cellfun(@buildFileTree, dirPaths);
% Assign the filenames to the Files field
tree.Files = filePaths;

