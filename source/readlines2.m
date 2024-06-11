function lines = readlines2(filePath, lineSeparator)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% readlines: read a text file and output the text split by lines
% usage:  lines = readlines(filePath)
%         lines = readlines(filePath, lineSeparator)
%
% where,
%    filePath is the path to the text file
%    lineSeparator is an optional char array representing a line separator.
%       The default value is the result of:
%           sprintf('\r\n')
%    lines is a cell array containing char arrays, each of which represents
%       one line of text in the file.
%
% Simple read the lines of a file, and return it as a cell array of lines.
%
% See also: fread
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('lineSeparator', 'var') || isempty(lineSeparator)
    lineSeparator = sprintf('\r\n');
end

fileID = fopen(filePath);
rawText = char(fread(fileID)');
lines = split(rawText, lineSeparator);