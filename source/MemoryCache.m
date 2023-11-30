classdef MemoryCache < handle
    properties
        MaxElements     double
        MaxBytes        double
    end
    properties (Access = private)
        Cache           cell = {}
        ElementBytes    double = []
        AccessLog       double = []
        NullElement     Null
        AccessCount     double = 1
    end
    methods
        function obj = MemoryCache(maxElements, maxBytes)
            obj.NullElement = Null();

            if ~exist('maxElements', 'var') || isempty(maxElements)
                obj.MaxElements = NaN;
            else
                obj.MaxElements = maxElements;
            end
            if ~exist('maxBytes', 'var') || isempty(maxBytes)
                obj.MaxBytes = NaN;
            else
                obj.MaxBytes = maxBytes;
            end
        end
        function isCached = isCached(obj, index)
            isCached = (obj.Cache{index} ~= obj.NullElement);
        end
        function areCached = areCached(obj, indices)
            areCached = cellfun(@(x)x~=obj.NullElement, obj.Cache(indices), 'UniformOutput', true);
        end
        function accessCount = get.AccessCount(obj)
            accessCount = obj.AccessCount;
            obj.AccessCount = accessCount + 1;
        end
        function removeFromCache(obj, indices)
            obj.Cache(indices) = {obj.NullElement};
            for k = size(obj.Cache, 2):-1:1
                if obj.Cache{k} ~= obj.NullElement
                    break;
                end
            end
            lastCachedIndex = k;
            obj.Cache(lastCachedIndex+1:end) = [];
            obj.ElementBytes(lastCachedIndex+1:end) = [];
            obj.AccessLog(lastCachedIndex+1:end) = [];
        end
        function [element, isCached] = retrieveElement(obj, index)
            element = obj.Cache{index};
            isCached = obj.isCached(index);
            obj.AccessLog(index) = obj.AccessCount;
        end
        function [elements, areCached] = retrieveElements(obj, indices)
            elements = obj.Cache(indices);
            areCached = obj.areCached{indices};
            for index = indices
                obj.AccessLog(index) = obj.AccessCount;
            end
        end
        function storeElement(obj, index, element)
            cacheLength = size(obj.Cache, 2);
            if index > cacheLength
                obj.Cache(cacheLength+1:index) = {obj.NullElement};
            end

            % Add new element to Cache
            obj.Cache{index} = element;
            % Record new element size
            elementInfo = whos('element');
            obj.ElementBytes(index) = elementInfo.bytes;
            % Record element access log
            obj.AccessLog(index) = obj.AccessCount;

            if ~isnan(obj.MaxElements)
                [~, accessOrder] = sort(obj.AccessLog, 2, "descend");
                idxToRemove = accessOrder(obj.MaxElements+1:end);
                obj.removeFromCache(idxToRemove);
            end
            if ~isnan(obj.MaxBytes)
                [~, accessOrder] = sort(obj.AccessCount, 2, "descend");
                totalBytes = sum(obj.AccessLog);
                if totalBytes > obj.MaxBytes
                    sortedBytes = obj.ElementBytes(accessOrder);
                    idxToRemove = accessOrder(cumsum(sortedBytes) > obj.MaxBytes);
                    obj.removeFromCache(idxToRemove);
                end
            end
        end
    end
    methods (Access = private)

    end
end