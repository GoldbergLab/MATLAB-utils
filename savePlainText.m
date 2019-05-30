function savePlainText(filename, text)
% Just fucking write text to a file why is this not built in
if iscell(text)
    text = cell2mat(join(text, '\n'));
end
fid = fopen(filename, 'w');
fprintf(fid, '%s', text);
fclose(fid);