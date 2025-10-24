function joined = joinchar(cellarr, delimiter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% joinchar: Join a 1D cell array of char or string array using a delimiter
% usage: joined = joinchar(cellarr, delimiter)
%
% where,
%    cellarr is a cell array of chars, or a string array
%    delimiter is a delimiter character or string
%    joined is a char array containing the joined string
%
% This is like the builtin join, but more similar to other languages'
%    join function. It just returns a char array containing the input
%    strings joined by a delimiter
%
% See also: join
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    cellarr {mustBeText}
    delimiter {mustBeTextScalar}
end

if ~isvector(cellarr) && ~isscalar(cellarr)
    error('cellarr must be a vector or scalar, not a higher dimensional array')
end

if iscolumn(cellarr)
    cellarr = cellarr';
end

N = numel(cellarr);

joined = vertcat(cellarr, repmat({delimiter}, [1, N]));
joined = reshape(joined, [1, 2*N]);
joined = char([joined{1:end-1}]);