function array = cset(array, values, varargin)
% Set linear list of values from an array using linear lists of coordinates
indices = sub2ind(size(array), varargin{:});
array(indices) = values;