function escapedText = escapeChars(text, charsToEscape, escapeChar) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% escapeChars: <short description>
% usage:  [escapedText] = escapeChars(text, charsToEscape, escapeChar)
%
% where,
%    text is the text to escape characters in
%    charsToEscape is a 1xN char array of all the characters that need to
%       be escaped
%    escapeChar is the optional character to use to prefix the escape
%       characters when escaping them with a regular expression
%    escapedText is the altered text
%
% This function is meant to add escape characters to selected characters
%   within the text.
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    text {mustBeText}
    charsToEscape {mustBeText}
    escapeChar {mustBeText} = '\'
end

escapeCharsCell = cell(1, length(charsToEscape));
for k = 1:length(charsToEscape)
    escapeCharsCell{k} = [escapeChar, charsToEscape(k)];
end
escapeCharRegex = join(escapeCharsCell, '|');
escapeCharRegex = escapeCharRegex{1};
regex = ['(?<!\\)(', escapeCharRegex, ')'];
escapedText = regexprep(text, regex, '\\$0');

