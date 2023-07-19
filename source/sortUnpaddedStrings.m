function [B, I] = sortUnpaddedStrings(A)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sortUnpaddedStrings: Sort strings w/ implicit number padding
% usage:  [B, I] = sortUnpaddedStrings(A)
%
% where,
%    A is a cell array of character arrays to be sorted
%    B is a cell array containing the same character arrays as A, but in
%       "natural" sorted order
%    I is an index array representing the sort order, such that A(I) = B
%
% This function sorts an array of strings in "natural" order, such that any
%   numerical parts of the strings are implicitly padded before sorting.
%   For example, a naive alphabetical sort would sort this array of strings
%
%       {'test11.txt', 'test9.txt', 'test10.txt'}
%
%   into this order:
%
%       {'test10.txt', 'test11.txt', 'test9.txt'}
%
%   However this function implicitly pads the '9' in 'test9.txt' such that 
%       it sorts like the string 'test09.txt'. Thus that first array would
%       sort into this order:
%
%       {'test9.txt', 'test10.txt', 'test11.txt'}
%
%
% See also: sort
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make a copy of the array to pad
A_padded = A;

% Find where the numerical portions of each string is
numberFieldExtents = regexp(A, '([0-9]+)', 'tokenExtents');

maxNumberLength = 0;

% Determine what the maximum number length is in this array of strings
% Loop over array
for k = 1:length(A)
    % Loop over each number in this string
    for j = 1:length(numberFieldExtents{k})
        % Calculate the length of this numerical portion
        extent = numberFieldExtents{k}{j};
        start = extent(1);
        stop = extent(2);
        if stop-start+1 > maxNumberLength
            % Record a new record long number
            maxNumberLength = stop-start+1;
        end        
    end
end

% Pad each number in each string with zeros up to the maximum number length
% Loop over array
for k = 1:length(A)
    % Loop over each number in this string
    for j = 1:length(numberFieldExtents{k})
        extent = numberFieldExtents{k}{j};
        start = extent(1);
        stop = extent(2);
        number = str2double(A_padded{k}(start:stop));
        numberLength = stop-start+1;
        % Pad this number in the string
        A_padded{k} = [A_padded{k}(1:start-1), sprintf(['%0', num2str(maxNumberLength), 'd'], number), A_padded{k}(stop+1:end)];
        for j2 = j+1:length(numberFieldExtents{k})
            % Adjust indices for the next number fields in this string
            numberFieldExtents{k}{j2} = numberFieldExtents{k}{j2} + maxNumberLength - numberLength;
        end
    end
end

% Sort padded array to obtain sort order
[~, I] = sort(A_padded);

% Sort original array
B = A(I);
