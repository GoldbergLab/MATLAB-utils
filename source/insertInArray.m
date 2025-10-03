function arrayOut = insertInArray(arrayIn, index, item)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% insertInArray: Insert an item into an array. How is this not already a 
%   function?
% usage:  arrayOut = insertInArray(arrayIn, index, item)
%
% where,
%    arrayIn is any 1D array or cell array
%    index is the location where the new item should be inserted
%    item is the item to insert into the array.
%
% Insert something into an array. Example:
%
%   x = [1, 2, 3, 4, 5];
%   x = insertInArray(x, 3, 99)
%   x =
%          1     2    99     3     4     5%
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arrayOut = [arrayIn(1:index-1), item, arrayIn(index:end)];