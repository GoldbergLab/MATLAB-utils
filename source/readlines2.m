function lines = readlines2(filePath, lineSeparator, maxLines)
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
%    maxLines is the maximum number of lines to return. If omitted, all 
%       lines will be returned
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
arguments
    filePath char
    lineSeparator = sprintf('\r\n');
    maxLines double = Inf
end

if isempty(lineSeparator)
    lineSeparator = sprintf('\r\n');
end

% Open file
fileID = fopen(filePath);
if fileID == -1
    error('Cannot open file "%s"', filePath);
end

try
    if isinf(maxLines)
        % All lines requested, read whole file and split it
        rawText = char(fread(fileID)');
        % Split lines on separator
        lines = split(rawText, lineSeparator);
    else
        % Only some lines requested, read in chunks until desired line count is achieved
        chunkSize = 10;
        rawText = '';
        numLines = 0;
        while numLines < maxLines
            % Read next chunk
            newText = fread(fileID, chunkSize)';
            % Append to overall data
            rawText = [rawText, newText]; %#ok<AGROW> 
            % Count how many lines we've found
            numLines = count(rawText, lineSeparator);
            if isempty(newText)
                % We've reached the end of the file before we got to the 
                % desired number of lines
                break
            end
            % Update chunk size based on previous line sizes, since reading larger chunks is probably faster
            if numLines > 0
                chunkSize = max([10, ceil(length(rawText) / numLines)]);
            end
        end
        % Split lines on separator
        lines = split(rawText, lineSeparator);
        % Discard last line, which is extra
        lines = lines(1:end-1);
    end
catch ME
    % Try to ensure graceful close
    fclose(fileID);
    rethrow(ME);
end
fclose(fileID);