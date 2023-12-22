classdef MemoryCache < handle
    properties
        MaxElements     double
        MaxBytes        double
    end
    properties (Access = private)
        Cache           cell = {}
        Cached          logical = logical.empty()
        ElementBytes    double = []
        AccessLog       double = []
        AccessCount     double = 1
    end
    methods
        function obj = MemoryCache(maxElements, maxBytes)
            if ~exist('maxElements', 'var') || isempty(maxElements)
                obj.MaxElements = [];
            else
                obj.MaxElements = maxElements;
            end
            if ~exist('maxBytes', 'var') || isempty(maxBytes)
                obj.MaxBytes = [];
            else
                obj.MaxBytes = maxBytes;
            end
        end
        function isCached = isCached(obj, indices)
            % Check if one or more elements are cached
            lastCachedIndex = size(obj.Cache, 2);
            inRange = indices <= lastCachedIndex;
            isCached = false(size(indices));
            isCached(inRange) = obj.Cached(indices(inRange));
        end
        function accessCount = get.AccessCount(obj)
            accessCount = obj.AccessCount;
            obj.AccessCount = accessCount + 1;
        end
        function removeFromCache(obj, indices)
            lastCachedIndex = size(obj.Cache, 2);
            
            indices(indices>lastCachedIndex) = [];

            obj.Cached(indices) = false;
            obj.Cache(indices) = {[]};
            obj.ElementBytes(indices) = 0;
            obj.AccessLog(indices) = 0;

            obj.trimCache();
        end
        function [element, isCached] = retrieveElement(obj, index)
            isCached = obj.isCached(index);
            if ~isCached
                element = [];
            else
                element = obj.Cache{index};
                obj.AccessLog(index) = obj.AccessCount;
            end
        end
        function [elements, areCached] = retrieveElements(obj, indices)
            % Determine which elements are cached
            areCached = obj.isCached(indices);

            % Preallocate output array
            elements = cell(1, length(indices));

            % Filter indices for only those in cache
            indices = indices(areCached);
            elements(areCached) = obj.Cache(indices);
            for index = indices
                obj.AccessLog(index) = obj.AccessCount;
            end
        end
        function storeElement(obj, index, element)
            obj.expandCache(index)

            % Add new element to Cache
            obj.Cache{index} = element;
            % Record that element is cached
            obj.Cached(index) = true;
            % Record new element size
            elementInfo = whos('element');
            obj.ElementBytes(index) = elementInfo.bytes;
            % Record element access log
            obj.AccessLog(index) = obj.AccessCount;

            if ~isempty(obj.MaxElements)
                [~, accessOrder] = sort(obj.AccessLog, 2, "descend");
                idxToRemove = accessOrder(obj.MaxElements+1:end);
                obj.removeFromCache(idxToRemove);
            end
            if ~isempty(obj.MaxBytes)
                [~, accessOrder] = sort(obj.AccessCount, 2, "descend");
                totalBytes = sum(obj.AccessLog);
                if totalBytes > obj.MaxBytes
                    sortedBytes = obj.ElementBytes(accessOrder);
                    idxToRemove = accessOrder(cumsum(sortedBytes) > obj.MaxBytes);
                    obj.removeFromCache(idxToRemove);
                end
            end
        end
        function cacheLength = getCacheLength(obj)
            cacheLength = sum(obj.Cached);
        end
        function cacheBytes = getCacheBytes(obj)
            cacheBytes = sum(obj.ElementBytes);
        end
        function clearCache(obj)
            obj.Cache = {};
            obj.Cached = logical.empty();
            obj.ElementBytes = [];
            obj.AccessLog = [];
            obj.AccessCount = 1;
        end
    end
    methods (Access = private)
        function expandCache(obj, index)
            % Add trailing null elements up to index, if index is greater
            % than cache length
            lastCachedIndex = size(obj.Cache, 2);
            idx = lastCachedIndex+1:max(index);
            if ~isempty(idx)
                obj.Cache(idx) = {[]};
                obj.Cached(idx) = false;
                obj.ElementBytes(idx) = 0;
                obj.AccessLog(idx) = 0;
            end
        end
        function trimCache(obj)
            % Remove trailing null elements from cache
            cacheLength = size(obj.Cache, 2);
            lastCachedIndex = find(obj.Cached, 1, "last");
            if isempty(lastCachedIndex)
                idx = [];
            else
                idx = lastCachedIndex+1:cacheLength;
            end
            if ~isempty(idx)
                obj.Cache(idx) = [];
                obj.Cached(idx) = [];
                obj.ElementBytes(idx) = [];
                obj.AccessLog(idx) = [];
            end
        end
    end
end