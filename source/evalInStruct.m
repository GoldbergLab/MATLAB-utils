function result = evalInStruct(s, expr)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% evalInStruct: Evaluate an expression with struct fields as variables
% usage:  result = evalInStruct(s, expr)
%
% where,
%    s is a struct whose fields become local variables during evaluation
%    expr is a char array containing a MATLAB expression
%    result is the output of evaluating the expression
%
% This is useful for evaluating user-supplied filter expressions where
% each variable name corresponds to a data column. For example:
%
%    s.bSorted = [true false true true];
%    s.bHasSong = [true true false true];
%    result = evalInStruct(s, 'bSorted & bHasSong')
%    % result = [true false false true]
%
% See also: eval, struct
%
% Version: 1.0
% Author:  Brian Kardon / Claude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    s (1, 1) struct
    expr (1, :) char
end

fieldNames = fieldnames(s);
for k = 1:length(fieldNames)
    eval([fieldNames{k}, ' = s.', fieldNames{k}, ';']); %#ok<EVLC>
end
result = eval(expr); %#ok<EVLC>
