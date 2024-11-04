function mustBeRealFile(path)
%mustBeRealFile Validate that value is a path to a real file or dir
%   mustBeRealFile(path) throws an error if path is not a path to a real 
%   file or dir
%   path must be a char array
%
%   See also mustBeRealFile, mustBeRealDir
    
% Copyright 2020 The MathWorks, Inc.

    if ~isfile(path)
        pathEscaped = escapeChars(path, '\', '\');
        throwAsCaller(MException("MATLAB:validators:mustBeRealFile", sprintf('"%s" is not a path to a file available on the current system.', pathEscaped)));
    end

end