function func = loadFunctionFromPath(functionPath)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loadFunctionFromPath: Load a function from a file path
% usage:  func = loadFunctionFromPath(functionPath)
%
% where,
%    functionPath is a char array representing the file path to the 
%       function. The path does NOT have to be in your MATLAB path
%    func is a function handle to the loaded function
%
% This function loads a MATLAB function from a .m file into a function
%   handle from any arbitrary file path. The file path does NOT have to be
%   in your MATLAB path.
%
% See also: str2func
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parse the function parent directory and file name
[functionDir, functionName, ~] = fileparts(functionPath);

% Save current working directory so we can switch back to it afterwards
currentDir = pwd();

% Change the current working directory to the function's parent directory
cd(functionDir);

% Load the function
func = str2func(functionName);

% Change back to the initial working directory
cd(currentDir);