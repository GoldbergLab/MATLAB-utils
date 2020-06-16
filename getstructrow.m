function s = getstructrow(s, fieldName, fieldValue, compareFunc, varargin)
if isempty(s)
    return
end
if ~isempty(varargin)
    firstOnly = varargin{1};
else
    firstOnly = true;
end
fieldValues = {s.(fieldName)};
idx = cellfun(@(v)compareFunc(v, fieldValue), fieldValues);
if firstOnly
    idx = find(idx);
    if ~isempty(idx)
        idx = idx(1);
    end
end
s = s(idx);
