function structure = fieldfun(fun, structure, field)
tempVector = cellfun(fun, {structure.(field)}, 'UniformOutput', false);
[structure.(field)] = tempVector{:};