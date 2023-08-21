function [paths, I, fileTimestamps] = sortFilesByTimestamp(paths, filenameTimestampParserOrTimestamps)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sortFilesByTimestamp: Sort list of files by extracted timestamp
% usage:  paths = getPathsByTimestamp(rootDir, startTimestamp, stopTimestamp, filenameTimestampParser)
%         [paths, I] = getPathsByTimestamp(rootDir, startTimestamp, stopTimestamp, filenameTimestampParser)
%
% where,
%    paths is a cell array of file paths
%    filenameTimestampParserOrTimestamps is either a function that takes a 
%       char array (a file path) and outputs a datetime object or NaT if
%       the char array is not parseable, or alternatively a list of
%       datetime objects corresponding to the list of paths.
%    I is an array of indices representing the sort order
%    fileTimestamps is the array of timestamps found for each file, NOT in
%       sorted order
%
% This function sorts a list of file paths (or other char array) by
%   timestamp, as determined by a provided timestamp parser function or a
%   simple array of timestamps. 
% 
% This function can, for example, be used in
%   conjuction with findFilesByTimestamp to ensure the files are sorted
%   properly by timestamp, rather than simply alphabetically.
%
% See also: findFilesByTimestamp, datetime, NaT
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isa(filenameTimestampParserOrTimestamps, 'function_handle')
    % User provided a timestamp parser function - parse the path timestamps
    fileTimestamps = filenameTimestampParserOrTimestamps(paths);
elseif isa(filenameTimestampParserOrTimestamps, 'datetime')
    % User provided an array of timestamps - just use them.
    fileTimestamps = filenameTimestampParserOrTimestamps;
    if length(fileTimestamps) ~= length(paths)
        error('paths array and timestamps array must have the same length')
    end
else
    error('filenameTimestampParserOrTimestamps must either be a function or a datetime object.')
end

% Sort the paths by timestamp
[~, I] = sort(fileTimestamps);
paths = paths(I);
