function uniqueName = getUniqueName(startingName, nameList, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <function name>: <short description>
% usage:  uniqueName = getUniqueName(startingName, nameList)
%         uniqueName = getUniqueName( __ , Name, Value)
%
% where,
%    startingName is the base name to make a unique name from
%    nameList is a cell array of existing names to avoid
%    uniqueName is a unique name generated by taking the startingName and
%       potentially adding numerals
%    'NumberingStyle' is an optional Name indicating where to look for a 
%       numeral in the starting name, and where to place a numeral when 
%       creating a unique name. NumberingStyle can take the Values:
%           'start' - at the start of the string
%           'end'   - at the end of the string (default)
%           'file'  - just before a file extension
%           'auto'  - wherever the first number appears in startingName
%    'PadLength' is an optional Name indicating how many digits to pad the
%       numeral to if adding one is necessary. It can have a Value of zero 
%       or any positive integer, but if omitted, the largest string of 
%       integers found in the names in nameList will be used.
%
% It's a common problem that you need to choose a name for something, but
%   it can't match other existing names - how can you gracefully add 
%   numbers to the name so it is unique? This function solves that.
%
% See also: regexp, unique
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    startingName (1, :) char
    nameList (1, :) cell {mustBeText}
    options.NumberingStyle (1, :) char {mustBeMember(options.NumberingStyle, {'start', 'end', 'file', 'auto'})} = 'end'
    options.PadLength (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(options.PadLength, 0)}
end

if ~any(strcmp(startingName, nameList))
    % Name is already unique
    uniqueName = startingName;
    return
end

% Determine how much to pad number
if isfield(options, 'PadLength')
    padLength = options.PadLength;
else
    digitCounts = cellfun(@maxConsecutiveDigits, nameList, 'UniformOutput', false);
    padLength = max([digitCounts{:}]);
end
if padLength > 0
    % Add padding to numeral
    formatString = sprintf('%%s%%0%dd%%s', padLength);
else
    % No padding
    formatString = '%s%d%s';
end

switch options.NumberingStyle
    case 'start'
        % Use the numeral at the start of the string
        startRegex =   '^()[0-9]*.*?';
        numeralRegex = '^([0-9]*).*?';
        endRegex =     '^[0-9]*(.*?)';
    case 'end'
        % Use the numeral at the end of the string
        startRegex =   '^(.*?)[0-9]*$';
        numeralRegex = '^.*?([0-9]*)$';
        endRegex =     '^.*?[0-9]*()$';
    case 'file'
        % Use the numeral just before a file extension
        startRegex =   '^(.*?)[0-9]*\.[0-9a-zA-Z]+';
        numeralRegex = '^.*?([0-9]*)\.[0-9a-zA-Z]+';
        endRegex =     '^.*?[0-9]*(\.[0-9a-zA-Z]+)';
    case 'auto'
        % Use the first numeral in the string, wherever it is
        startRegex =   '^([^0-9]*)[0-9]*.*';
        numeralRegex = '^[^0-9]*([0-9]*).*';
        endRegex =     '^[^0-9]*[0-9]*(.*)';
end

token = regexp(startingName, startRegex, 'tokens');
if isempty(token) || isempty(token{1}) || isempty(token{1}{1})
    nameStart = '';
else
    nameStart = token{1}{1};
end
token = regexp(startingName, numeralRegex, 'tokens');
if isempty(token) || isempty(token{1}) || isempty(token{1}{1})
    startNumeral = 1;
else
    startNumeral = str2double(token{1}{1});
end
token = regexp(startingName, endRegex, 'tokens');
if isempty(token) || isempty(token{1}) || isempty(token{1}{1})
    nameEnd = '';
else
    nameEnd = token{1}{1};
end

numeral = startNumeral;
while true
    uniqueName = sprintf(formatString, nameStart, numeral, nameEnd);
    if ~any(strcmp(uniqueName, nameList))
        break;
    end
    numeral = numeral + 1;
end

function count = maxConsecutiveDigits(str)
    % Get the maximum # of consecutive digits in a string. Return empty
    % array if there are no digits.
    match = regexp(str, '[0-9]+', 'match');
    count = max(cellfun(@length, match));