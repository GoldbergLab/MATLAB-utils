function mustBeRealPath(path)
%mustBeRealPath Validate that value is a path to a real file or dir
%   mustBeRealPath(path) throws an error if path is not a path to a real 
%   file or dir
%   path must be a char array
%
%   See also mustBeRealFile, mustBeRealDir
    
% Copyright 2020 The MathWorks, Inc.

    if ~exist(path, 'file')
        pathEscaped = escapeChars(path, '\', '\');
        throwAsCaller(MException("MATLAB:validators:mustBeRealPath", sprintf('"%s" is not a real path available on the current system.', pathEscaped)));
    end

end