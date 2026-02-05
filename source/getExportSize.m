function exportSize = getExportSize(fig, varargin)

tempImagePath = [tempname(), '.png']; %sprintf('tmp%s.raw', r);
try
    exportgraphics(fig, tempImagePath, varargin{:});
    image = imread(tempImagePath);
    exportSize = size(image);
catch ME
    try
        delete(tempImagePath);
    catch
    end
    rethrow(ME)
end