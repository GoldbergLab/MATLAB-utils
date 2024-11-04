function mustBeRealDir(path)
%mustBeRealDir Validate that value is a path to a real file or dir
%   mustBeRealDir(path) throws an error if path is not a path to a real 
%   file or dir
%   path must be a char array
%
%   See also mustBeRealDir, mustBeRealDir
    
% Copyright 2020 The MathWorks, Inc.

    if ~isfolder(path)
        pathEscaped = escapeChars(path, '\', '\');
        throwAsCaller(MException("MATLAB:validators:mustBeRealDir", sprintf('"%s" is not a path to a directory available on the current system.', pathEscaped)));
    end

end