function driveLetters = getValidDriveLetters()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getValidDriveLetters: Get a list of letters of mounted drives on Windows
% usage:  driveLetters = getValidDriveLetters()
%
% where,
%    driveLetters is a char array containing letters that correspond to a
%       valid drive mounted on the local computer
%
% This function determines which letters currently correspond to valid
% drives mounted on the local computer. Only compatible with Windows.
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% List of all possible letters
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

% Initialize list of valid drive letters
driveLetters = '';

% Loop over possible letters
for k = 1:length(letters)
    letter = letters(k);
    % Check if the drive exists
    if isfolder([letter, ':'])
        % Add it onto the list if so
        driveLetters = [driveLetters, letter]; %#ok<AGROW> 
    end
end