function [data, cache] = cacheLoadFile(path, loader, cache, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cacheLoadFile: Load a file with a cache for previously loaded files
% usage: data = cacheLoadFile(path, loader, cache)
%        data = cacheLoadFile(path, loader, cache, "LoaderArgs", {arg1, arg2, ...})
%        [data, cache] = cacheLoadFile(path, loader)
%
% where,
%    path is a path to the file to load
%    loader is a function handle that can load the file, for example @load
%    cache is a containers.Map object used as a file cache. If omitted, a 
%       new empty cache will be created, used, and returned.
%    Name/Value arguments can include:
%       LoaderArgs: A cell array of arguments to pass to the loader 
%           function after the file path.
%    data is the loaded data
%    cache is the cache. It's unnecessary to capture this argument unless 
%       a new empty cache was created. Otherwise, since the cache is a
%       handle, it will be modified in-place.
%
% Load files with a file cache to prevent re-loading files that have 
%   already been loaded
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    path {mustBeTextScalar} = ''
    loader = @()[]
    cache = struct("data", containers.Map(), "order", containers.Map())
    options.LoaderArgs = {}
    options.MaxLength = []
end

if isempty(path)
    % Just create an empty cache
    data = {};
    return;
end

if cache.data.isKey(path)
    % We've already loaded this file, get data from cache
    data = cache.data(path);
else
    % New file, load it and cache it
    data = loader(path, options.LoaderArgs{:});
    cache.data(path) = data;
    cache.order(path) = get_next_idx(cache);
end

if ~isempty(options.MaxLength)
    clean_cache(cache, options.MaxLength);
end

function next_idx = get_next_idx(cache)
if isempty(cache.order)
    next_idx = 1;
else
    next_idx = max(cell2mat(cache.order.values())) + 1;
end

function clean_cache(cache, num_to_keep)
% Get rid of oldest entries until there are at most num_to_keep left
if length(cache.order) > num_to_keep
    num_to_delete = length(cache.order) - num_to_keep;
    keys = cache.order.keys();
    order = cell2mat(cache.order.values());
    [~, idx] = sort(order);
    delete_idx = idx(1:num_to_delete);
    remove(cache.data, keys(delete_idx));
    remove(cache.order, keys(delete_idx));
end