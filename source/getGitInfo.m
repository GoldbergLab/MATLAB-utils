function [commitDate, commitHash, branchName, githubURL] = getGitInfo(functionNameOrPath, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getGitInfo: Get information about a function's git repo
% usage: [commitDate, commitHash, branchName] = 
%           getGitInfo(functionNameOrPath, options)
%
% where,
%    functionNameOrPath is either a function name on the MATLAB path, or a
%       path to a .m file
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
    functionNameOrPath char
    options.CheckGit logical = false
end

if options.CheckGit
    [gitStatus, ~] = system('where /q git');
    if gitStatus ~= 0
        error('To use getGitInfo, git must be installed and available on the system path. See https://ffmpeg.org/download.html.');
    end
end

if ~exist(functionNameOrPath, 'file')
    % It's not a valid path, maybe it's a function name
    path = which(functionNameOrPath);
    if isempty(path)
        error('No function found by the name/path "%s"', functionNameOrPath);
    end
end

[source_path, ~, ~] = fileparts(mfilename('fullpath'));

while ~isfolder(fullfile(source_path, '\.git'))
    [source_path, ~, ~] = fileparts(source_path);
end

originalDir = pwd();
cd(source_path)
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