function fileName = getFileName(filePath)
% A simple shortcut for getting the fileName from a filePath
[~, name, extension] = fileparts(filePath);
fileName = [name, extension];