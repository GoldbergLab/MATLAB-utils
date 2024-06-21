function A = mergeStructures(A, B, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mergeStructures: Merge struct B into A
% usage:  A = mergeStructures(A, B)
%         A = mergeStructures(A, B, 'Name', 'Value', ...)
%
% where,
%    A is a struct to merge B into
%    B is a struct to merge into A
%    Name/Value pairs can be:
%       'Overwrite': if true, silently overwrite any common fields with the
%           value from struct B. If false, raise an error if there are 
%           common fields, unless they fall under the purview of the 
%           specific cases handled by 'Concatenate' or 'Recursive'.  
%           Default is true.
%       'Concatenate': if true, and 'Overwrite' is false, then common 
%           fields with values that are compatible for concatenation will 
%           be concatenated overwritten. For example if 
%               A.x = [1, 2]
%               B.x = [3, 4]
%           then
%               A = mergeStructures(A, B, 'Concatenate', true) 
%           will result in 
%               A.x = [1, 2, 3, 4];
%           If the common fields are not compatible for concatenation, an
%           error will be raised.
%       'Recursive': if true, and 'Overwrite' is false, then when common 
%           fields have values that are structures, those sub-structures 
%           will be recursively merged in the same way.
%
% Flexibly merge two structures that may or may not have common fields.
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 
% If overwrite is true, this will silently overwrite any common fields with
%   the value from struct B.
% If overwrite is false, this will raise an error if there are common
% fields, unless Concatenate is true, and the values are compatible for
% concatenation, in which case they will be concatenated in C.

arguments
    A struct
    B struct
    options.Overwrite = true
    options.Concatenate = false
    options.Recursive = false
end

fieldnamesB = fieldnames(B);
for k = 1:length(fieldnamesB)
    fieldname = fieldnamesB{k};
    if ~options.Overwrite && isfield(A, fieldname)
        % Common field found, but overwriting is disabled
        if options.Recursive && isstruct(A.(fieldname)) && isstruct(B.(fieldname))
            % Attempt to recursively merge sub-structures
            optionalArgs = namedargs2cell(options);
            A.(fieldname) = mergeStructures(A.(fieldname), B.(fieldname), optionalArgs{:});
        elseif options.Concatenate
            % Attempt to concatenate the common field values
            A.(fieldname) = [A.(fieldname), B.(fieldname)];
        else
            % Throw error because overwrite is disallowed
            error('Field %s is in both structures, and Overwrite is set to false.', fieldname);
        end
    else
        % Copy field from B to A
        A.(fieldname) = B.(fieldname);
    end
end
