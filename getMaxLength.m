function maxLength = getMaxLength(varargin)
% Get the maximum length of the provided arguments
maxLength = max(cellfun(@length, varargin));