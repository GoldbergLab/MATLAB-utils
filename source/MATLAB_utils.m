function MATLAB_utils_path = MATLAB_utils(display)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATLAB_utils: reference/indicator function for MATLAB-utils repo
% usage:  MATLAB_utils_path = MATLAB_utils(display)
%
% where,
%    display is an optional boolean indicating whether or not to display
%       info about the MATLAB-utils repo in the command window, or a regex
%       to search for within the names of the functions in the repo
%    MATLAB_utils_path is the path to the MATLAB-utils repository
%
% This function can both display useful info about the MATLAB-utils
%   repository, but also serve as a litmus test to see if the user has the
%   MATLAB-utils repo installed:
%
%   if ~exist(MATLAB_utils, 'file')
%       disp('MATLAB-utils not detected, please install and try again.');
%   end
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    arguments
        display = true
    end
    
    [MATLAB_utils_source_path, ~, ~] = fileparts(mfilename('fullpath'));
    MATLAB_utils_path = MATLAB_utils_source_path;
    
    while ~isfolder(fullfile(MATLAB_utils_path, '\.git'))
        [MATLAB_utils_path, ~, ~] = fileparts(MATLAB_utils_path);
    end
    
    if ischar(display)
        % User supplied regex to search for functions
        functionRegex = display;
        functionRegexDisplayText = [' matching ''', functionRegex, ''''];
        display = true;
    else
        % If user requested display, display all functions
        functionRegex = '.*\.m';
        functionRegexDisplayText = '';
    end

    if islogical(display) && display
        originalDir = pwd();
        cd(MATLAB_utils_path)
        [status, commitDate] = system('git log -1 --format=%cd --date=local');
        if status ~= 0
            commitDate = '<error - unable to get commit date>';
        end
        commitDate = strtrim(commitDate);
        [status, commitHash] = system('git rev-parse --short HEAD');
        if status ~= 0
            commitHash = '<error - unable to get commit hash>';
        end
        commitHash = strtrim(commitHash);
        [status, branchName] = system('git rev-parse --abbrev-ref HEAD');
        if status ~= 0
            branchName = '<error - unable to get branch name>';
        end
        branchName = strtrim(branchName);
        [status, url] = system('git config --get remote.origin.url');
        if status ~= 0
            url = '<error - unable to get GitHub url>';
        end
        url = strtrim(url);
        cd(originalDir);
    
        fprintf('\n');
        fprintf('<strong>MATLAB-utils</strong> repository is installed!\n')
        fprintf('\n');
        fprintf('\t<strong>Path</strong>:              %s\n', MATLAB_utils_path);
        fprintf('\t<strong>Commit timestamp</strong>:  %s\n', commitDate);
        fprintf('\t<strong>git hash</strong>:          %s\n', commitHash(1:7));
        fprintf('\t<strong>git branch</strong>:        %s\n', branchName);
        fprintf('\t<strong>GitHub page</strong>:       <a href="%s">%s</a>\n', url, url);
        fprintf('\n');
        fprintf('<strong>Functions%s</strong>:\n', functionRegexDisplayText);
        
        functionList = findFilesByRegex(MATLAB_utils_source_path, functionRegex);
        displayFunctionList(functionList)
    end
end

function displayFunctionList(functionPaths)
    % Display a list of functions in a nice looking grid
    numFunctions = length(functionPaths);

    if numFunctions == 0
        fprintf('No functions found\n\n');
        return
    end
    
    commandWindowSize = matlab.desktop.commandwindow.size;
    
    functionNameList = cell(size(functionPaths));
    for k = 1:length(functionPaths)
        functionPath = functionPaths{k};
        [~, functionNameList{k}, ~] = fileparts(functionPath);
    end
    functionNameList = sort(functionNameList);
    
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
            rowText = [rowText, functionEntry]; %#ok<AGROW> 
        end
        fprintf('%s\n', rowText);
    end
end