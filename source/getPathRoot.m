function pathRoot = getPathRoot(path, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getPathRoot: get the root (drive) for a given path
% usage:  pathRoot = getPathRoot(path, Name, Value, ...)
%
% where,
%    path is a char array representing a file path
%    Name/value arguments can include:
%       LetterOnly: Logical, if true, only includes the drive letter (for
%           example 'C') rather than the full root (for example 'C:\')
%
% Take a path, get the root. If there is no root, for example
%   'no/root/path', then an empty char array will be returned.
%
% See also: RootSwap
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arguments
    path (1, :) char
    options.LetterOnly (1, 1) logical = false
end

% Discover root by iteratively getting parent directory
oldPathRoot = '';
pathRoot = path;
while ~strcmp(oldPathRoot, pathRoot)
    oldPathRoot = pathRoot;
    pathRoot = fileparts(pathRoot);
end

if ~isempty(pathRoot) && options.LetterOnly
    pathRoot = pathRoot(1);
end