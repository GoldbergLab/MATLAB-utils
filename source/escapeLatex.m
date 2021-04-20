function escapedText = escapeLatex(text)
charsToEscape = '&%$#_{}~^\';
escapeChar = '\';
escapedText = escapeChars(text, charsToEscape, escapeChar);