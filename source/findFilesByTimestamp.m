function paths = findFilesByTimestamp(rootDir, startTimestamp, stopTimestamp, filenameTimestampParser, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getPathsByTimestamp: Find files within a range of timestamps
% usage:  paths = getPathsByTimestamp(rootDir, startTimestamp, stopTimestamp, filenameTimestampParser)
%
% where,
%    rootDir is the directory in which to look for files
%    startTimeStamp is a datetime object defining the earliest timestamp to
%       include in the output paths
%    stopTimeStamp is a datetime object defining the latest timestamp to
%       include in the output paths
%    filenameTimestampParser is a function that takes a char array (a file
%       path) and outputs a datetime object. If the provided char array
%       does not contain a valid timestamp, the function should return an
%       empty array.
%    Other arguments: Additional arguments may be provided; these will be
%       passed to the findFilesByRegex function before the timestamp filter
%       is applied.
%
% This function finds the paths to all files in a directory that contain
%   timestamps that fall between the two provided timestamps (inclusive).
%   Since timestamps can be formatted in any number of ways, this function
%   requires a function handle that can convert a filename to a datetime
%   object; this function should be tailored to the expected timestamp
%   format in the chosen root directory.
% Additional arguments can be passed in, and will be forwarded to the
%   findFilesByRegex function, allowing other filtering to take place
%   before the timestamp filter.
%
% See also: findFilesByRegex, datetime
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get list of all the files
paths = findFilesByRegex(rootDir, varargin{:});

% Prepare a mask indicating whether or not each path is in the timestamp
% range.
inRangePathMask = false(size(paths));

% Loop over the paths
for k = 1:length(paths)
    path = paths{k};
    try
        % Extract the timestamp from the filename
        fileTimestamp = filenameTimestampParser(path);
        % Check if filename was un-parseable
        if isempty(fileTimestamp)
            error('Timestamp format not recognized');
        end
        % Check if timestamp is in range
        inRangePathMask(k) = (startTimestamp <= fileTimestamp) && (fileTimestamp <= stopTimestamp);
    catch ME
        % Filename was un-parseable
        fprintf('Failed to parse file %s:\n', path);
        warning(getReport(ME));
    end
end

% Filter paths
paths = paths(inRangePathMask);