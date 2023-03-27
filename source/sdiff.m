function [valueDiffs, fieldDiffs] = sdiff(sA, sB)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sdiff: find differences between two structs
% usage:  [valueDiffs, fieldDiffs] = sdiff(sA, sB)
%
% where,
%    sA is one struct to compare
%    sB is the other struct to compare
%    valueDiffs is a cell array containing field names which both
%       structures have, but for which the values differ.
%    fieldDiffs is a cell array containing field names which the two
%       structures do not share.
%
% This is a function that finds which fields differ between two structs. It
%   outputs the names of the differing fields in two arrays - valueDiffs,
%   which contains names of fields which both structs have, but for which
%   the values are different, and fieldDiffs, which contains names of
%   fields which only one of the two structures has.
%
% See also: tdiff
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fA = fieldnames(sA);
fB = fieldnames(sB);
fAll = intersect(fA, fB);
fieldDiffs = setxor(fA, fB);

valueDiffs = {};

for k = 1:length(fAll)
    fieldName = fAll{k};
    if ~isequaln({sA.(fieldName)}, {sB.(fieldName)})
        valueDiffs{end+1} = fieldName;
    end
end