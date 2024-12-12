function absolutePath = getAbsolutePath(path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getAbsolutePath: Compute the absolute path for a given path
% usage:  absolutePath = getAbsolutePath(path)
%
% where,
%    path is a char array representing a valid path to a file or folder.
%       path can be relative or absolute.
%
% This function returns the absolute path for a given path. The absolute
%   path is the full path that uniquely identifies a file or folder on a
%   computer. It seems like this works a little better than resolvePath in
%   certain cases.
%
% See also: what, dir, fileparts, resolvePath

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(path, 'file')
    error('getAbsolutePath:pathDoesNotExist', 'The given path %s does not appear to exist.', path);
end
[p, n, e] = fileparts(path);
w = what(p);
if isempty(w)
    error(['The directory of the given path ', p, ' does not appear to exist on this system.']);
end
absolutePath = fullfile(w.path, [n, e]);
