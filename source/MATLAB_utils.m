function MATLAB_utils()

[MATLAB_utils_source_path, ~, ~] = fileparts(mfilename('fullpath'));
MATLAB_utils_path = MATLAB_utils_source_path;

while ~isfolder(fullfile(MATLAB_utils_path, '\.git'))
    [MATLAB_utils_path, ~, ~] = fileparts(MATLAB_utils_path);
end

FETCH_HEAD = fullfile(MATLAB_utils_path, '.git', 'FETCH_HEAD');
fid = fopen(FETCH_HEAD, 'r');
head = fread(fid, '*char')';
tokens = regexp(head, '^([0-9a-f]+)\s+branch ''(.*)'' of (.*)', 'tokens');
hash = tokens{1}{1};
branch = tokens{1}{2};
url = tokens{1}{3};

functionList = findFilesByRegex(MATLAB_utils_source_path, '.*\.m');
numFunctions = length(functionList);

fprintf('\n');
fprintf('<strong>MATLAB-utils</strong> repository is installed!\n')
fprintf('\n');
fprintf('\t<strong>Path</strong>:        %s\n', MATLAB_utils_path);
fprintf('\t<strong>git hash</strong>:    %s\n', hash(1:7));
fprintf('\t<strong>git branch</strong>:  %s\n', branch);
fprintf('\t<strong>git url</strong>:     <a href="%s">GitHub page</a>\n', url);
fprintf('\n');
fprintf('<strong>Functions</strong>:\n');

commandWindowSize = matlab.desktop.commandwindow.size;

functionNameList = cell(size(functionList));
for k = 1:length(functionList)
    functionPath = functionList{k};
    [~, functionNameList{k}, ~] = fileparts(functionPath);
end

columnWidth = max(cellfun(@length, functionNameList)) + 2;
numColumns = floor(commandWindowSize(1)/columnWidth);
columnWidth = floor(commandWindowSize(1) / numColumns);
numRows = ceil(length(functionNameList) / numColumns);

functionGrid = reshape([functionNameList, repmat({''}, [1, numRows*numColumns - numFunctions])], [numRows, numColumns]);
for row = 1:numRows
    rowText = '';
    for column = 1:numColumns
        functionName = functionGrid{row, column};
        spacing = repmat(' ', [1, columnWidth - length(functionGrid{row, column})]);
        functionEntry = sprintf('<a href="matlab: edit %s">%s</a>%s', functionName, functionName, spacing);
        rowText = [rowText, functionEntry];
    end
    fprintf('%s\n', rowText);
end