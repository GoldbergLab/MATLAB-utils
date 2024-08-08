function documentation = generateFunctionDocs(mfilename, options)
arguments
    mfilename
    options.shortDescription {mustBeText} = '<short description>'
    options.longDescription {mustBeText} = '<long description>'
    options.relatedFunctions {mustBeText} = '<related functions>'
    options.author {mustBeText} = 'Brian Kardon'
    options.email {mustBeText} = 'bmk27=cornell*org, brian*kardon=google*com'
end

shortDescription = options.shortDescription;
longDescription = options.longDescription;
relatedFunctions = options.relatedFunctions;
author = options.author;
email = options.email;

template1 = [...
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n',...
'% <function name>: <short description>\n',                                     ...
'% usage:  [<output args>] = <function name>(<input args>)\n',                  ...
'%\n',                                                                          ...
'% where,',                                                                   ...
];
template2 = [...
'%    <arg> is <description>',                                               ...
];
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

lines = readlines2(mfilename);

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
    error('Could not parse function at %s', mfilename);
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
    argSpecs = [argSpecs, argSpec];
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
documentation = sprintf(regexprep(documentation, '%', '%%'));

if nargout == 0
    disp(documentation);
    clipboard('copy', documentation);
    fprintf('\nDocumentation copied to clipboard\n')
end