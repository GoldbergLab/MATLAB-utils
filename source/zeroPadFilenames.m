function zeroPadFilenames(baseFolder, filePattern, varargin)
% Look for files that match filePattern in baseFolder, and if dryrun=False,
% move the files to a new name that is the same except the integer in the
% filename is zeropadded to the maximum required to match the largest
% integer in the matching filenames in that folder.
if nargin == 2
    dryrun = true;
elseif nargin == 3
    dryrun = varargin{1};
end

files = dir(fullfile(baseFolder, filePattern));

fieldWidth = max(cellfun(@(s)length(cell2mat(regexp(s, '[0-9]+', 'match'))), {files.name}));
for k = 1:length(files)
    file = files(k);
    number = str2num(cell2mat(regexp(file.name, '[0-9]+', 'match')));
    newNumber = num2str(number, ['%0', num2str(fieldWidth),'.f']);
    newName = strrep(file.name, num2str(number), newNumber);
    oldFilePath = fullfile(file.folder, file.name);
    newFilePath = fullfile(file.folder, newName);
    if ~strcmp(oldFilePath, newFilePath)
        if dryrun
            disp('This command would move')
            disp(oldFilePath)
            disp('    to')
            disp(newFilePath)
        else
            movefile(oldFilePath, newFilePath);
        end
    end
end