function [B, I] = shuffleArray(A)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% shuffleArray: shuffle an array into a random order 
% usage:  B = shuffleArray(A)
%         [B, I] = shuffleArray(A)
%
% where,
%    A is an array to shuffle
%    B is the array with shuffled order
%    I is the shuffle order such that B = A(I)
%
% Shuffles an array.
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Obtain a random order
[~, I] = sort(rand(size(A)));

% Sort the array according to the random order
B = A(I);