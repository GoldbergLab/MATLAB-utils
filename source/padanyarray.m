function B = padanyarray(A, padsize, padval, options)
arguments
    A
    padsize (1, :) double
    padval = []
    options.Direction {mustBeMember(options.Direction, {'pre', 'post', 'both'})} = 'both'
    options.Method {mustBeMember(options.Method, {'circular', 'replicate', 'symmetric', 'value'})} = 'value'
end

direction = options.Direction;
method = options.Method;

if iscell(A) && ~iscell(padval)
    padval = {padval};
end

padsize = [padsize, ones(1, length(size(A)) - length(padsize))];

B = A;

for dim = 1:ndims(A)
    padvec = size(B);
    padvec(dim) = padsize(dim);
    switch method
        case 'value'
            prepad = repmat(padval, padvec);
            postpad = repmat(padval, padvec);
        case 'replicate'
            % Create array to select first element of this dimension of B
            selectvec = arrayfun(@(s)1:s, size(B), 'UniformOutput', false);
            selectvec{dim} = 1;
            % Create single pre-pad array
            prepad = B(selectvec{:});
            % Repeat pre-pad array
            selectrepeatvec = ones(1, ndims(B));
            selectrepeatvec(dim) = padsize(dim);
            prepad = repmat(prepad, selectrepeatvec);

            % Create array to select last element of this dimension of B
            selectvec = arrayfun(@(s)1:s, size(B), 'UniformOutput', false);
            selectvec{dim} = size(B, dim);
            repmat(selectvec, selectrepeatvec);
            % Create single post-pad array
            postpad = B(selectvec{:});
            % Repeat post-pad array
            selectrepeatvec = ones(1, ndims(B));
            selectrepeatvec(dim) = padsize(dim);
            postpad = repmat(postpad, selectrepeatvec);
        otherwise
            error('Method %s not implemented', method);
    end
    switch direction
        case 'pre'
            B = cat(dim, prepad, B);
        case 'post'
            B = cat(dim, B, postpad);
        case 'both'
            B = cat(dim, prepad, B, postpad);
        otherwise
            error('Direction %s not implemented', direction);
    end
end

