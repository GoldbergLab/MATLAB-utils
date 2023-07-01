function close_fig()
% Close all figures, even uifigures
close(findall(0, 'type', 'figure'))