function size = getFileSize(filePath)
% getFileSize: get the size of a given file in bytes
% usage:  size = getFilesize('path/to/a/file.xxx');
%
% where,
%    filePath is the path to the file to be sized
%
% See also: 

% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

f = dir(filePath);
size = f.bytes;