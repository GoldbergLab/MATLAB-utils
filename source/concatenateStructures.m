function structArray = concatenateStructures(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% concatenateStructures: Concatenate structs into a struct array
% usage:  A = concatenateStructures(struct1, struct2, struct3, ...)
%
% where,
%    struct1, struct2, etc are structs to concatenate
%
% Concatenate multiple structs that may or may not have dissimilar fields 
%   into a struct array
%
% See also: mergeStructures
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

structs = varargin;

structArray = structs{1};

structNum = 2;
rowNum = length(structArray);
while structNum <= length(structs)
    newFieldnames = fieldnames(structs{structNum});
    numNewRows = length(structs{structNum});
    for f = 1:length(newFieldnames)
        structArray(rowNum+1:rowNum+numNewRows).(newFieldnames{f}) = structs{structNum}.(newFieldnames{f});
    end
    rowNum = rowNum + numNewRows;
    structNum = structNum + 1;
end