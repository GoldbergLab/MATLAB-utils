function structArray = concatenateStructArrays(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% concatenateStructArrays: Concatenate dissimilar struct arrays together
% usage:  A = concatenateStructures(structArr1, structArr2, ...)
%
% where,
%    structArr1, structArr2, etc are struct arrays to concatenate. Struct 
%       arrays must both be 1D vectors
%
% Concatenate multiple struct arrays that may or may not have dissimilar 
%   fields into a struct array
%
% See also: nextStructArray.(newFieldnames{fieldNum})
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structArrays = varargin;

structArray = [];

while isempty(structArray)
    structArray = structArrays{1};
    structArrays = structArrays(2:end);
end

rowNum = length(structArray);
for structNum = 1:length(structArrays)
    nextStructArray = structArrays{structNum};
    if isempty(nextStructArray)
        if ~isstruct(nextStructArray)
            % If this is [] or something similar, just convert to empty struct
            nextStructArray = struct.empty();
        end
    end
    newFieldnames = fieldnames(nextStructArray);
    numNewRows = length(nextStructArray);
    for fieldNum = 1:length(newFieldnames)
        [structArray(rowNum+1:rowNum+numNewRows).(newFieldnames{fieldNum})] = nextStructArray.(newFieldnames{fieldNum});
    end
    rowNum = rowNum + numNewRows;
end