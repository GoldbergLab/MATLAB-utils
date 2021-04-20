function msync(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% msync: Sync two Directorys
% usage:  msync(sourceDirectory, destinationDirectory, (Name, Value)
%
% where,
%    sourceDirectory is a path to a directory to copy
%    destinationDirectory is a path to where the sourceDirectory should be 
%       copied
%    Name/Value are property value pairs:
%       Replace = true or false (default true) - replace files that already
%           exist in the destination Directory?
%       FilterFiles = regex_filter_string - only copy files whose names
%           match the regex_filter_string. Omit or empty string will result
%           in no filtering
%       FilterDirectories = regex_filter_string - only copy files whose names
%           match the regex_filter_string. Omit or empty string will result
%           in no filtering
% <long description>
%
% See also: <related functions>

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
addRequired(p, 'sourceDirectory');
addRequired(p, 'destinationDirectory');
addParameter(p, 'Replace', true);
addParameter(p, 'FilterFiles', '');
addParameter(p, 'FilterDirectories', '');
parse(p, varargin{:});
sourceDirectory = p.Results.sourceDirectory;
destinationDirectory = p.Results.destinationDirectory;
Replace = p.Results.Replace;
FilterFiles = p.Results.FilterFiles;
FilterDirectories = p.Results.FilterDirectories;





function syncFolder(sourceParent, destinationParent, folderName)
files = 
