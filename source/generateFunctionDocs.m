function documentation = generateFunctionDocs(mfilename, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generateFunctionDocs: Automatically generate function docs, like this
% usage:  documentation = generateFunctionDocs(mfilename, Name/Value, ...)
%
% where,
%    mfilename is either a function name that is on the MATLAB path, or a 
%       path to an .m file
%    Optional Name/Value pairs may include:
%       ShortDescription is a short < 1 line description of the function
%       LongDescription is a longer paragraph-format description of the
%           function
%       RelatedFunctions is a comma-separated list of related functions
%       Author is the name of the function author
%       Email is the e-mail of the function author; recommend this be
%           provided in obfuscated format with = instead of @ and * instead
%           of . to avoid spam harvesters
%    documentation is a char array containing the generated documentation.
%       Note that if the function is called with no output arguments and
%       with a ; at the end of the call, the documentation will instead by
%       printed to the screen and also copied to the system clipboard for
%       convenience.
%
% This function automatically generates documentation for a MATLAB
%   function. It relies on rudimentary text parsing, so it will probably 
%   not work for excessively complex or unusual cases.
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    mfilename
    options.ShortDescription {mustBeText} = '<short description>'
    options.LongDescription {mustBeText} = '<long description>'
    options.RelatedFunctions {mustBeText} = '<related functions>'
    options.Author {mustBeText} = 'Brian Kardon'
    options.Email {mustBeText} = 'bmk27=cornell*org, brian*kardon=google*com'
end

shortDescription = options.ShortDescription;
longDescription = options.LongDescription;
relatedFunctions = options.RelatedFunctions;
author = options.Author;
email = options.Email;

template1 = [...
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n',...
'% <function name>: <short description>\n',                                     ...
'% usage:  [<output args>] = <function name>(<input args>)\n',                  ...
'%\n',                                                                          ...
'% where,',                                                                   ...
];
template2 = ...
'%    <arg> is <description>';
template3 = [...
'%\n',                                                                          ...
'% <long description>\n',                                                       ...
'%\n',                                                                          ...
'% See also: <related functions>\n',                                            ...
'%\n',                                                                          ...
'% Version: 1.0\n',                                                             ...
'% Author:  <author name>\n',                                                    ...
'% Email:   <author email>\n',                      ...
'% Real_email = regexprep(Email,{''='',''*''},{''@'',''.''})\n',                        ...
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n',...
];

maxLineLength = max(cellfun(@length, split([template1, template2, template3], '\n')));

% Attempt to get mfile path using MATLAB path
mfilepath = which(mfilename);
if isempty(mfilepath)
    % Not found on MATLAB path, maybe it's already a full or relative path
    mfilepath = mfilename;
end
lines = readlines2(mfilepath);

regex = '\s*function\s+\[?\s*([a-zA-Z][a-zA-Z0-9_]*(\s*,\s*[a-zA-Z][a-zA-Z0-9_]*)*)\s*\]?\s*=\s*([a-zA-Z][a-zA-Z0-9_]*)\s*\(\s*([a-zA-Z][a-zA-Z0-9_]*(\s*,\s*[a-zA-Z][a-zA-Z0-9_]*)*)\s*\)';

foundCallsign = false;

for k = 1:length(lines)
    tokens = regexp(lines{k}, regex, 'tokens');
    if ~isempty(tokens)
        functionOutput = tokens{1}{1};
        functionName = tokens{1}{2};
        functionInput = tokens{1}{3};
        foundCallsign = true;
        break
    end
end

if ~foundCallsign
    error('Could not parse function at %s', mfilepath);
end

inputs = regexp(functionInput, '[a-zA-Z][a-zA-Z0-9_]*', 'match');
outputs = regexp(functionOutput, '[a-zA-Z][a-zA-Z0-9_]*', 'match');

template1 = regexprep(template1, '<function name>', functionName);
template1 = regexprep(template1, '<short description>', shortDescription);
allOutputs = join(outputs, ', ');
allInputs = join(inputs, ', ');
template1 = regexprep(template1, '<output args>', allOutputs{1});
template1 = regexprep(template1, '<input args>', allInputs{1});

argSpecs = {};
IO = [inputs, outputs];
for k = 1:length(IO)
    argSpec = regexprep(template2, '<arg>', IO{k});
    argSpecs = [argSpecs, argSpec]; %#ok<AGROW> 
end
template2 = join(argSpecs, '\n');
template2 = template2{1};

template3 = regexprep(template3, '<long description>', longDescription);
template3 = regexprep(template3, '<related functions>', relatedFunctions);
template3 = regexprep(template3, '<author name>', author);
template3 = regexprep(template3, '<author email>', email);

documentation = {};
documentation = [documentation, template1];
documentation = [documentation, template2];
documentation = [documentation, template3];

documentation = join(documentation, '\n');
documentation = documentation{1};

% Wrap any lines that are too long
documentation = wrapLongLines(documentation, maxLineLength);

documentation = sprintf(regexprep(documentation, '%', '%%'));

if nargout == 0
    disp(documentation);
    clipboard('copy', documentation);
    fprintf('\nDocumentation copied to clipboard\n')
end

function documentation = wrapLongLines(documentation, maxLineLength)
documentationUnwrapped = split(documentation, '\n');
documentation = {};
for k = 1:length(documentationUnwrapped)
    line = strtrim(documentationUnwrapped{k});
    if isempty(line)
        continue;
    end
    splitLines = {line};
    while length(splitLines{end}) > maxLineLength
        % Determine indentation level
        longLine = splitLines{end};
        indentation = regexp(longLine(2:end), '[%\s]', 'once');
        splitLines{end} = longLine(1:maxLineLength);
        splitLines{end+1} = ['%', repmat(' ', [1, indentation]), longLine(maxLineLength+1:end)]; %#ok<AGROW> 
    end
    documentation = [documentation, splitLines{:}]; %#ok<AGROW> 
end
documentation = join(documentation, '\n');
documentation = documentation{1};