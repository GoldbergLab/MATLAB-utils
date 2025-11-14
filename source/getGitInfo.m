function [commitDate, commitHash, branchName, githubURL] = getGitInfo(functionName, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getGitInfo: Get information about a function's git repo
% usage: [commitDate, commitHash, branchName] = 
%           getGitInfo(functionNameOrPath, options)
%
% where,
%    functionName is a function name on the MATLAB path
%    Name/Value arguments can include:
%       CheckGit: Check if git is available on system first
%    commitDate is the date of the current repo commit
%    commitHash is the hash of the current repo commit
%    branchName is the name of the active repo branch
%    githubURL is the url to the GitHub repository
%
% Get the time, hash, branch and GitHub URL of the current repo commit.
%
% See also: MATLAB_utils
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    functionName char
    options.CheckGit logical = false
end

if options.CheckGit
    if ispc()
        [gitStatus, ~] = system('where /q git');
    else
        [gitStatus, ~] = system('which git');
    end
    if gitStatus ~= 0
        error('To use getGitInfo, git must be installed and available on the system path. See https://ffmpeg.org/download.html.');
    end
end

% Make sure it's not a builtin
if exist(functionName, 'builtin')
    error('function "%s" is a MATLAB builtin, not a function in a git repository.', functionName)
end

path = which(functionName);
if ~exist(functionName, 'file') || isempty(path)
    error('functionName (%s) must be a valid function name on the current MATLAB path.', functionName);
end

[functionDir, ~, ~] = fileparts(path);

% Find base repo folder (and verify it's in a repo)
while ~isfolder(fullfile(functionDir, '.git'))
    oldFunctionDir = functionDir;
    [functionDir, ~, ~] = fileparts(functionDir);
    if strcmp(functionDir, oldFunctionDir)
        % We're in a loop
        error('"%s" does not appear to be in a git repository.', functionName);
    end
end

originalDir = pwd();
cd(functionDir)
[status, commitDate] = system('git log -1 --format=%cd --date=local');
if status ~= 0
    commitDate = '<error - unable to get commit date>';
end
commitDate = strtrim(commitDate);
[status, commitHash] = system('git rev-parse --short HEAD');
if status ~= 0
    commitHash = '<error - unable to get commit hash>';
end
commitHash = strtrim(commitHash);
[status, branchName] = system('git rev-parse --abbrev-ref HEAD');
if status ~= 0
    branchName = '<error - unable to get branch name>';
end
branchName = strtrim(branchName);
[status, githubURL] = system('git config --get remote.origin.url');
if status ~= 0
    githubURL = '<error - unable to get GitHub url>';
end
githubURL = strtrim(githubURL);
cd(originalDir);

if nargout == 0
    % If no outputs are requested, print information to the terminal
    [~, functionName, ~] = fileparts(functionName);
    fprintf('\n');
    fprintf('Function <strong>%s</strong> git repository information:\n', functionName)
    fprintf('\n');
    fprintf('\t<strong>Path</strong>:              %s\n', functionDir);
    fprintf('\t<strong>Commit timestamp</strong>:  %s\n', commitDate);
    fprintf('\t<strong>git hash</strong>:          %s\n', commitHash(1:7));
    fprintf('\t<strong>git branch</strong>:        %s\n', branchName);
    fprintf('\t<strong>GitHub page</strong>:       <a href="%s">%s</a>\n', githubURL, githubURL);
end
    