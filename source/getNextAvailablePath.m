function availablePath = getNextAvailablePath(basePath, digitPad)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getNextAvailablePath: Check if file path is taken, and increment if so
% usage:  availablePath = getNextAvailablePath(basePath, digitPad)
%
% where,
%    basePath is a char array representing a path to a file
%    digitPad is an optional number indicating how much to zero-pad the 
%       incrementing number in the new filename, if one is necessary. 
%       Default is 3.
%    availablePath is a char array representing a version of the base path
%       with a number added to the end if necessary such that availablePath
%       is guaranteed to not point to an existing file.
%
% Take a path, check if it is "taken" (points to an existing file). If so,
%   add a number to the end of the file name, check again, increment the
%   number if it is still taken, and continue until the path is "available"
%   (does not point to an existing file).
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if default digitPad is necessary
if ~exist('digitPad', 'var')
    digitPad = 3;
end

% Get parts of original file path
[path, name, ext] = fileparts(basePath);

availablePath = basePath;

% Loop until the file path is available
index = 0;
while exist(availablePath, 'file')
    availablePath = makePath(path, name, ext, index, digitPad);
    index = index + 1;
end

function path = makePath(path, name, ext, index, digitPad)
% Create a path from a directory, name, extension, numerical index, and
%   digitPad (how much to zero-pad the numerical index in the filename)
path = fullfile(path, [sprintf(['%s_%0', num2str(digitPad), 'd'], name, index), ext]);
