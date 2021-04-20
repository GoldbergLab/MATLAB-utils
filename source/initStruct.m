function newStruct = initStruct(fieldNames)
c = cell(length(fieldNames),1);
newStruct = cell2struct(c,fieldNames);
newStruct = newStruct([]);