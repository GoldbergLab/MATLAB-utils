function values = extractField(structVar, fieldName)
% Attempt to intelligently extract a field from a struct as a vector

if ~isfield(structVar, fieldName)
    error(['field name ', fieldName, ' is not a field of the given struct.']);
end
try
    if all(arrayfun(@(x)length(x.(fieldName))==1, structVar, 'UniformOutput', true))
        % Attempt horizontal concatenation
        values = [structVar.(fieldName)];
    else
        % Data is non-scalar - cell concatenate it
        values = {structVar.(fieldName)};
    end
catch ME
    % Didn't work - do cell concatenation instead
    values = {structVar.(fieldName)};
end
