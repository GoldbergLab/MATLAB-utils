function A = multicircshift(A, K, dim, method)
if ~exist('dim', 'var') || isempty(dim)
    dim = find(size(A) > 1, 1);
end

switch method
    case 1
        idx = repmat({':'}, 1, ndims(A));
        for row = 1:size(A, dim)
            idx{dim} = row;
            A(idx{:}) = circshift(A(idx{:}), K(row));
        end
    case 2
        rowIdx = 1:size(A, dim);
        
end