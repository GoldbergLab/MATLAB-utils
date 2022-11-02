function outputStruct = initStruct(fieldNames, structSize)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initStruct: Initialize a struct with given fields and size
% usage:  outputStruct = initStruct(fields, structSize)
%
% where,
%    fieldNames is a 1xN cell array of char arrays representing the names 
%       of fields the outputStruct will contain
%    structSize is an optional 1xM array of dimension sizes indicating the
%       desired shape of the outputStruct. Default is 0, which produces a
%       0x0 struct array.
%    outputStruct is a struct array of the desired structSize, with the
%       requested field names.
%
% This fills a notable gap in MATLAB builtin functions regarding struct
%   arrays - it provides a simple way to initialize struct arrays.
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If desired size is not provided, produce a size 0 struct array
if ~exist('structSize', 'var') || isempty(structSize)
    structSize = 0;
end

% Create a cell array of the desired size
placeholder = cell(structSize);
% Produce an array of values to interleave with the field names for the 
%   struct function 
values = cell(size(fieldNames));
% Set the first value to the cell array of the desired shape, which will
%   force the struct function to use that to determine the struct array 
%   shape
values{1} = placeholder;
% Interleave field names and values
pairs = [fieldNames; values];
% Construct output struct array
outputStruct = struct(pairs{:});
