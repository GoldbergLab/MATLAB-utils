function packageScript(scriptPath, varargin)
% packageScript: Create a "package" for distributing a script, containing
%   the script and all the dependencies.
% usage:  packageScript('scriptName.m')
%         packageScript('scriptName.m', '/path/where/you/want/it/to/go')
%
% where,
%    scriptPath is the name of a matlab script. If it is in the current
%       matlab path, just the script name is enough. Otherwise, a full path is
%       required.
%    destination (optional) is the folder in which you want the package 
%       folder to be saved.
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

if nargin > 1
    destinationFolder = varargin{1};
else
    destinationFolder = '.';
end

disp('Detecting dependencies...')
% Find the path to each dependency (including the script itself)
[fList,~] = matlab.codetools.requiredFilesAndProducts(scriptPath);

[~, scriptName, ~] = fileparts(scriptPath);
packagePath = fullfile(destinationFolder, [scriptName, '_package']);
% Create the package folder
mkdir(packagePath);

for k = 1:length(fList)
    dependencyPath = fList{k};
    [~, name, ext] = fileparts(dependencyPath);
    destinationPath = fullfile(packagePath, [name, ext]);
    copyfile(dependencyPath, destinationPath);
end