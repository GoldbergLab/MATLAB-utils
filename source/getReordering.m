function order = getReordering(A, B)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getReordering: Get the reordering vector that transforms a into b
% usage:  order = getReordering(A, B)
%
% where,
%    A is a 1D array to be reordered to match B
%    B is a 1D array that is a reordered version of A
%    order is a vector of reordered indices that transforms A into B like
%       so: A(order) => B
%
% This function finds a set of reordered indices that transforms A into B,
%   such that A(order) is the same as B. It works with any kind of array,
%   including a cell array. Note that each element in A must be equal to
%   exactly one element in B, and vice versa, or unexpected behavior or an
%   error may result.
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~iscell(A)
    A = arrayfun(@(x)x, A, 'UniformOutput', false);
end
if ~iscell(B)
    B = arrayfun(@(x)x, B, 'UniformOutput', false);
end
order = zeros(1, length(A));
for a = 1:length(A)
    for b = 1:length(B)
        if isequal(A{a}, B{b})
            order(a) = b;
            break;
        end
    end
end
% order = sum((A == B') .* (1:length(A)), 2);


