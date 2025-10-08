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
    path
    loader
    cache = containers.Map()
    options.LoaderArgs = {}
end

if cache.isKey(path)
    % We've already loaded this file, get data from cache
    data = path(path);
else
    % New file, load it and cache it
    data = loader(path, options.LoaderArgs{:});
    cache(path) = data;
end
