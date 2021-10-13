function availablePath = getNextAvailablePath(basePath, digitPad)
if ~exist('digitPad', 'var')
    digitPad = 3;
end

[path, name, ext] = fileparts(basePath);
availablePath = basePath;
index = 0;
while exist(availablePath, 'file')
    availablePath = makePath(path, name, ext, index, digitPad);
    index = index + 1;
end

function path = makePath(path, name, ext, index, digitPad)
path = fullfile(path, [sprintf(['%s_%0', num2str(digitPad), 'd'], name, index), ext]);
