function writeText(filePath, text, varargin)
if ~isempty(varargin)
    enc = varargin{1};
else
    enc = 'UTF-8';
end
fid = fopen(filePath, 'w');
fwrite(fid, unicode2native(text, enc));
fclose(fid);