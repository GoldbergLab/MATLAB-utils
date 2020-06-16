function s = rmstructrow(s, fieldName, fieldValue, compareFunc, varargin)
if isempty(s)
    return
end
if length(varargin) > 1
    invert = varargin{2};
else
    invert = false;
end
if ~isempty(varargin)
    firstOnly = varargin{1};
else
    firstOnly = false;
end
fieldValues = {s.(fieldName)};
idx = cellfun(@(v)compareFunc(v, fieldValue), fieldValues);
if invert
    idx = ~idx;
end
if firstOnly
    idx = find(idx);
    if ~isempty(idx)
        idx = idx(1);
    end
end
s(idx) = [];
