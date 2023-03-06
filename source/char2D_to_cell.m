function cell_array = char2D_to_cell(char_array)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% char2D_to_cell: Convert a 2D char array into a cell array of rows
% usage:  cell_array = char2D_to_cell(char_array)
%
% where,
%    char_array is a 2D char array
%    cell_array is a 1D cell array containing 1D char arrays, each of which
%       is a row from char_array
%
% Sometimes MATLAB GUI widgets return multiline text as a 2D char array for
%   some weird reason. It's usually more convenient to get each line in a
%   cell array, so this does that conversion. Each row in the original 2D
%   array becomes a 1D char array in the cell array.
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if numel(char_array) == 0
    cell_array = {};
    return;
end

num_rows = size(char_array, 1);

cell_array = cell([1, num_rows]);

for row = 1:num_rows
    cell_array{row} = char_array(row, :);
end