function [p, idx] = permutations(items, n, ignore_order)
% Generate all permutations of items of length n

if ~exist('ignore_order', 'var') || isempty(ignore_order)
    ignore_order = false;
end

if n > length(items)
    error('Cannot generate permutations longer than the list of items.');
end
if n < 1
    error('Number of permutations must be an integer between 1 and the number of items (inclusive).');
end

vals = cell(1, n);
vectors = repmat({1:length(items)}, [1, n]);
[vals{:}] = ndgrid(vectors{:});


all_permutations = cell2mat(cellfun(@(L)L(:), vals, 'UniformOutput', false));

% restrict to unique groups
if ~ignore_order
    [~, idx, ~] = unique(sort(all_permutations, 2), 'rows');
    all_permutations = all_permutations(idx, :);
end

% Convert indices back to items
p = items(all_permutations);