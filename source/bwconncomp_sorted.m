function CC = bwconncomp_sorted(BW, conn, sort_key)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bwconncomp_sorted: bwconncomp but with ability to sort PixelIdxList
% usage:  CC = bwconncomp_sorted(BW)
%         CC = bwconncomp_sorted(BW, conn)
%         CC = bwconncomp_sorted(BW, conn, sort_key)
%
% where,
%    BW is a logical mask (see bwconncomp)
%    conn (optional) is the desired pixel connectivity (see bwconncomp)
%    sort_key (optional) is a function handle that takes a 1D array of 
%       pixel indices and returns a scalar numerical key that will be used 
%       to sort the connected components. By default, sort_key is the
%       @(x)-length(x) function
%
% Same as the built in bwconncomp but it sorts the PixelIdxList field. By
%   default the list is sorted in descending order of connected component
%   size.
%
% See also: bwconncomp
%
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('conn', 'var') || isempty(conn)
    conn = [];
end

if ~exist('sort_key', 'var') || isempty(sort_key)
    sort_key = @(x)-length(x);
end

if isempty(conn)
    CC = bwconncomp(BW);
else
    CC = bwconncomp(BW, conn);
end

% Transform PixelIdxList into a set of nuemrical keys to sort
keys = cellfun(sort_key, CC.PixelIdxList, 'UniformOutput', true);

% Sort the keys, extracting the sort order
[~, order] = sort(keys);

% Sort pixel idx list based on key sort order
CC.PixelIdxList = CC.PixelIdxList(order);