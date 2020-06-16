function escapedText = escapeChars(text, charsToEscape, escapeChar) 
%charsToEscape = '&%$#_{}~^\';
escapeCharsCell = {};
for k = 1:length(charsToEscape)
    escapeCharsCell{k} = [escapeChar, charsToEscape(k)];
end
escapeCharRegex = join(escapeCharsCell, '|');
escapeCharRegex = escapeCharRegex{1};
regex = ['(?<!\\)(', escapeCharRegex, ')'];
escapedText = regexprep(text, regex, '\\$0');

