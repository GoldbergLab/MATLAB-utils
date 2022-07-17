function [c, ia] = notunique(a, rows)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% notunique: find non-unique elements or rows of an array
% usage:  c = notunique(a)
%         c = notunique(a, 'rows')
%         [c, ia] = notunique(___)
%
% where,
%    a is a 1xn or mxn array
%    'rows' is an option that results in non-unique rows, rather than
%       elements.
%    c is a 1xn or mxn array of non-unique elements or rows
%    ia is a 1xn array of indices, such that c = a(ia) or c = a(ia, :)
%
% By analogy to the "unique" function, find non-unique (repeated) items in
%   the input array. Like the unique function, the 'rows' option looks for
%   non-unique rows, rather than individual elements, and it's possible to
%   get an array of indices as well as the actual non-unique elements or
%   rows.
%
% See also: unique
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist('rows', 'var') && strcmp(rows, 'rows')
    rows = true;
else
    rows = false;
end
if rows
    [c, ia, ic] = unique(a, 'rows');
else
    [c, ia, ic] = unique(a);
end

not_unique = unique(ic(sum(ic == ic', 2) > 1));
if rows
    c = c(not_unique, :);
else
    c = c(not_unique);
end
ia = ia(not_unique);