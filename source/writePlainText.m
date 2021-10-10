function writePlainText(filePath, text)
fid = fopen(filePath, 'w');
fprintf(fid, text);
fclose(fid);