function fullpath = resolvePath(path)
% Resolve a file path into a absolute path. Note that the file or folder
% must exist for the path to be resolved.
% Thanks to Ray on MATLAB Answers for this utility:
% https://www.mathworks.com/matlabcentral/answers/56363-fully-resolving-path-names#answer_68241
  file=java.io.File(path);
  if file.isAbsolute()
      fullpath = path;
  else
      fullpath = char(file.getCanonicalPath());
  end
  if file.exists()
      return
  else
      error('resolvePath:CannotResolve', 'Does not exist or failed to resolve absolute path for %s.', path);
  end