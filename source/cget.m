function values = cget(array, varargin)
% Get values from an array using lists of coordinates
indices = sub2ind(size(array), varargin{:});
values = array(indices);