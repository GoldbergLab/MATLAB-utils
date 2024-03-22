function uniqueName = getUniqueName(startingName, nameList, options)
% Get a unique name for the given starting name, to ensure no
% two axes have the same name
arguments
    startingName (1, :) char
    nameList (1, :) cell {mustBeText}
    options.NumberingStyle (1, :) char {mustBeMember(options.NumberingStyle, {'start', 'end', 'file'})} = 'end'
    options.PadLength (1, 1) double {mustBeInteger, mustBePositive}
end

if ~any(strcmp(startingName, nameList))
    % Name is already unique
    uniqueName = startingName;
    return
end

switch options.NumberingStyle
    case 'start'
        startRegex =   '^()[0-9]*.*?';
        numeralRegex = '^([0-9]*).*?';
        endRegex =     '^[0-9]*(.*?)';
    case 'end'
        startRegex =   '^(.*?)[0-9]*$';
        numeralRegex = '^.*?([0-9]*)$';
        endRegex =     '^.*?[0-9]*()$';
    case 'file'
        startRegex =   '^(.*?)[0-9]*\.[0-9a-zA-Z]+';
        numeralRegex = '^.*?([0-9]*)\.[0-9a-zA-Z]+';
        endRegex =     '^.*?[0-9]*(\.[0-9a-zA-Z]+)';
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