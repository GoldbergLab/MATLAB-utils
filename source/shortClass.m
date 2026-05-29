function name = shortClass(obj)
longClass = class(obj);
classParts = split(longClass, '.');
name = classParts{end};
