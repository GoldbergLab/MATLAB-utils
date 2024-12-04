function viewColors(RGBs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% viewColors: <short description>
% usage: viewColor(RGBs)
%
% where,
%    RGBs is a cell array of MATLAB color specifications
%
% <long description>
%
% See also: <related functions>
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

f = figure;
ax = axes(f);
for k = 1:length(RGBs)
    patch([k, k+1, k+1, k], [0, 0, 1, 1], RGBs{k}, 'Parent', ax);
end
