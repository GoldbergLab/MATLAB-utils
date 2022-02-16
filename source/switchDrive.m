function newPath = switchDrive(path, newDrive, resolve)
% Swap out a path's drive letter
%   path: a Windows path
%   newDrive: a drive letter to swap into the path (with or without a
%       colon)
%   resolve: an optional boolean flag indicating whether to attempt
%       to resolve an absolute path before swapping the drive letter.
%       This only works if the path points to a file or folder that exists.
%       If this is set to false, you must ensure that the path is an
%       absolute path first.
%       Default is true
% For example, 
% switchDrive("C:\Users\Path\To\Something.txt", 'D') ==> "C:"
% Or 'this\is\a\relative\path.txt" ==> "C:"
if ~exist('resolve', 'var') || isempty(resolve)
    resolve = true;
end
if resolve
    path = resolvePath(path);
end

% Add on a colon if it doesn't exist
if ~strcmp(newDrive(end), ':')
    newDrive = [newDrive, ':'];
end
% Ensure user has not included a file separator character in the new drive
newDrive = regexprep(newDrive, filesep, '');

if length(newDrive) ~= 2
    error('New drive specified has more than two characters: %s\n', newDrive);
end

pathParts = regexp(path, filesep, 'split');
pathParts{1} = newDrive;
newPath = fullfile(pathParts{:});