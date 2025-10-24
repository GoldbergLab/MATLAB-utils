function [filePaths, varargout] = findPaths(rootDirOrTree, pattern, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findPaths: Search rootDir for file paths that match the regex
% usage:                 filePaths = findPaths(rootDir, pattern)
%   [filePaths, token1, token2...] = findPaths(rootDir, pattern, 
%                                              "Name", "Value", ...)
%
% where,
%    rootDirOrTree is a char array representing a directory to recursively 
%       search or a file tree struct of the form returned by buildFileTree
%    pattern a char array representing a file regex to match. Note that if 
%       the regex contains one or more capturing groups, the text of those
%       captured groups can be retrieved from varargout. Default is '.*'.
%    Name/Value options can include:
%       MatchWholePath: an optional boolean flag indicating whether to 
%           apply the regex to the path as well as name. Default is false.
%       SearchSubdirectories: a boolean indicating whether to apply regex 
%           recursively to subdirectories as well (default is true) or a 
%           positive integer which specifies the maximum recursion depth.
%       IncludeFolders: a boolean indicating whether to include folders in 
%           results. Default is false.
%       IncludeFiles: a boolean indicating whether to include regular files
%           in results, default true.
%       StartTimeStamp: a datetime object indicating the earliest 
%           timestamped file to include in the output (see TimeFilterMode)
%       StopTimeStamp: a datetime object indicating the latest timestamped 
%           file to include in the output (see TimeFilterMode)
%       TimeFiltermode: one of 
%               "Filename" (indicating time filtering should be done by 
%                   parsing the filename with the FilenameTimestampParser 
%                   function), 
%               "CreateTime" (indicating the time filtering should be done 
%                   according to the creation time of the files, or 
%               "ModifyTime" (indicating the time filtering should be done
%                   according to the last modified time of the files)
%       CaseSensitive: should the pattern be matched case sensitive?
%           Default is true.
%       Filter: A function that takes a file path and returns true or 
%           false, used to filter the results. For example, the function
%           might check the size or contents of the file, or do more 
%           complex tests on the file path than can be easily done with
%           regex alone.
%
%   filePaths is a cell array of file paths that matched the regex
%   token1, token2, ... is one or more cell arrays containing the tokens
%       matched by capturing groups in the regex for each file path. If
%       there are N capturing groups in the regex, there will be N tokens
%       returned.
%
% This is a function that returns a simple cell array of paths when given a
%   root directory and a regular expression to filter the files and folders
%   within, along with a variety of options about how to traverse the
%   directory structure, and how to filter the results.
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
%     [filePaths, fileNums] = findPaths(rootDir, 'test([0-9])\.txt')
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
% See also: dir, buildFileTree
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arguments
    rootDirOrTree
    pattern char = ''
    options.MatchWholePath logical = false
    options.SearchSubdirectories = true         % false or 0 means no recursion, true means infinite depth recursion, a whole number indicates how deep to go.
    options.IncludeFolders logical = false
    options.IncludeFiles logical = true
    options.StartTimestamp datetime = datetime.empty
    options.StopTimestamp datetime = datetime.empty
    options.TimeFilterMode char {mustBeMember(options.TimeFilterMode, {'Filename', 'CreateTime', 'ModifyTime'})} = 'Filename'
    options.FilenameTimestampParser function_handle = function_handle.empty
    options.CaseSensitive logical = true
    options.Filter function_handle = function_handle.empty()
end

if isstruct(rootDirOrTree)
    % rootDirOrTree must be a struct of the form returned by buildFileTree
    useTree = true;
else
    % rootDirOrTree must be a root directory path
    useTree = false;
end

if ~useTree
    % 
    if strcmp(rootDirOrTree, '.')
        % To allow for matching paths, convert '.' to absolute path
        rootDirOrTree = pwd();
    elseif strcmp(rootDirOrTree, '..')
        % To allow for matching paths, convert '..' to absolute path
        [rootDirOrTree, ~, ~] = fileparts(pwd());
    end
end

if useTree
    if options.IncludeFiles
        files = rootDirOrTree.Files;
    else
        files = {};
    end
    if ~isempty(rootDirOrTree.Dirs)
        dirs = {rootDirOrTree.Dirs.Path};
    else
        dirs = {};
    end
    if options.IncludeFolders
        files = [files, dirs];
    end
else
    files = dir(rootDirOrTree);

    % Exclude dot directores - '.' and '..'
    files = files(~cellfun(@isDotDir, {files.name}));
    
    dirs = files([files.isdir]);

    if ~options.IncludeFolders
        % Exclude directories
        files = files(~[files.isdir]);
    end
    if ~options.IncludeFiles
        % Exclude regular files
        files = files([files.isdir]);
    end
end

% Get the number of expected output tokens (captured elements of 
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
    if options.MatchWholePath
        matchName = fullfile(rootDirOrTree, filename);
    else
        [~, name, ext] = fileparts(filename);
        matchName = [name, ext];
    end
    
    if ~isempty(pattern)
        % If a regex is given, use it to search 
        if options.CaseSensitive
            [match, tokens] = regexp(matchName, pattern, 'start', 'tokens');
        else
            [match, tokens] = regexpi(matchName, pattern, 'start', 'tokens');
        end
    else
        match = true;
        tokens = {};
    end

    if match
        if useTree
            filepath = fullfile(rootDirOrTree.Path, filename);
        else
            filepath = fullfile(rootDirOrTree, filename);
        end

        % Did user supply a filter function?
        if ~isempty(options.Filter) 
            % Yes, check if the filepath passes the filter function
            if ~options.Filter(filepath)
                % Filepath does not pass the filter function - skip it
                continue
            end
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

if options.SearchSubdirectories
    % Recurse over subdirectories
    if ~islogical(options.MatchWholePath) 
        % options.MatchWholePath is an integer recursion depth, decrement it!
        options.MatchWholePath = options.MatchWholePath - 1;
    end
    % Loop over subdirectories
    for k = 1:length(dirs)
        % Make sure we're not operating on a dot pseudo directory
        if useTree
            [~, dirName, ~] = fileparts(rootDirOrTree.Dirs(k).Path);
        else
            dirName = dirs(k).name;
        end
        if ~isDotDir(dirName)
            if useTree
                newRootDirOrTree = rootDirOrTree.Dirs(k);
            else
                newRootDirOrTree = fullfile(rootDirOrTree, dirName);
            end
            % Initialize file token cell array for subfolder
            newFileTokens = cell(1, numTokens);
            % Run function recursively to capture output from subfolder 
            %   tree
            optionArgs = namedargs2cell(options);
            [newFilePaths, newFileTokens{:}] = findPaths(newRootDirOrTree, pattern, optionArgs{:});
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
