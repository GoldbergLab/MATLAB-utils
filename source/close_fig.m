function close_fig()
% Close all figures, even uifigures, even if someone messed with the
% CloseRequestFcn

try
    close(findall(0, 'type', 'figure'));
end

remainingFigs = findall(0, 'type', 'figure');
for k = 1:length(remainingFigs)
    try
        remainingFigs(k).CloseRequestFcn = 'closereq';
        close(remainingFigs(k));
    end
end