function output = showGraphicsTree(obj, options)
arguments
    obj matlab.graphics.Graphics
    options.PropertyNames = {}
    options.Indent double = 0
    options.LastChild logical = false
    options.NamePad double = 0
end

name = shortClass(obj);

numChildren = length(obj.Children);

numProperties = length(options.PropertyNames);
if numProperties > 0
    PropertyNames = options.PropertyNames;
    PropertyVals = cell(1, numProperties);
    for k = 1:numProperties
        val = obj.(PropertyNames{k});
        if ~isscalar(val)
            if isnumeric(val)
                val = num2str(val);
            elseif istext(val) && ~ischar(val)
                val = join(val, ' ');
                val = val{1};
            end
        end
        val = string(val);
        if strlength(val) == 0
            val = "<none>";
        end
        PropertyVals{k} = val;
    end
    PropertyString = join(cellfun(@(n,v)sprintf('%s: %s', n, v), PropertyNames, PropertyVals, 'UniformOutput', false), ', ');
    PropertyString = PropertyString{1};
else
    PropertyString = '';
end

indent = repmat('│  ', 1, options.Indent - 1);
if options.Indent > 0
    if options.LastChild
        indent = [indent, '└─'];
    else
        indent = [indent, '├─'];
    end
    
    if numChildren == 0
        indent = [indent, '─'];
    else
        indent = [indent, '┬'];
    end
end    

nameString = padanyarray([name, ':'], [1, options.NamePad], ' ', 'Direction', 'post', 'Mode', 'PadTo');

output = [indent, sprintf('%s%s\n', nameString, PropertyString)];

for k = 1:numChildren
    child = obj.Children(k);
    output = [output, showGraphicsTree(child, "PropertyNames", options.PropertyNames, "Indent", options.Indent+1, "LastChild", k == numChildren, 'NamePad', options.NamePad)];
end

