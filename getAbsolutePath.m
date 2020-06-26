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
%   computer. 
%
% See also: what, dir, fileparts

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(path)
    error(['The given path ', path, ' does not appear to exist.']);
end
[p, n, e] = fileparts(path);
w = what(p);
if isempty(w)
    error(['The directory of the given path ', p, ' does not appear to exist on this system.']);
end
absolutePath = fullfile(w.path, [n, e]);
