function drive = getDrive(path, resolve)
% Get the drive part of a Windows path.
%   path: a Windows path
%   resolve: an optional boolean flag indicating whether to attempt
%       to resolve an absolute path before finding the drive letter.
%       This only works if the path points to a file or folder that exists.
%       If this is set to false, you must ensure that the path is an
%       absolute path first.
%       Default is true
% For example, 
% "C:\Users\Path\To\Something.txt" ==> "C:"
% Or 'this\is\a\relative\path.txt" ==> "C:"
if ~exist('resolve', 'var') || isempty(resolve)
    resolve = true;
end
if resolve
    path = getAbsolutePath(path);
end
pathParts = regexp(path, filesep, 'split');
drive = pathParts{1};