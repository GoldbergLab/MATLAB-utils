classdef Path
    % Path is a class that wraps a file path, giving it a variety of useful
    %   functionality. It is closely based on python's pathlib.Path class, 
    %   though there are some differences.
    properties (Dependent = true)
        drive
        root
        anchor
        parents
        parent
        name
        suffix
        suffixes
        stem
        str
    end
    properties (Access = private)
        Segments string = string.empty()
        Separator string = "\"
        Flavor string {mustBeMember(Flavor, ["Windows", "Posix"])} = "Windows"
        RelativeRoot = "."
    end
    methods % Constructor
        function pathOut = Path(pathString, options)
            arguments
                pathString = ""
                options.Flavor {mustBeMember(options.Flavor, ["Windows", "Posix"])} = "Windows"
            end
            if isa(pathString, 'Path')
                % We've passed in another Path
                pathOut = pathString;
                return
            end
            if ~istext(pathString)
                error('pathString must be either a text scalar or a Path');
            end
            pathOut.Flavor = options.Flavor;
            switch pathOut.Flavor
                case "Windows"
                    pathOut.Separator = "\";
                case "Posix"
                    pathOut.Separator = "/";
            end
            
            pathString = string(pathString);
            pathOut.Segments = split(pathString, pathOut.Separator)';
            if ~isempty(pathOut.Segments) && pathOut.isDrive(pathOut.Segments(1))
                % Fix root segment to include separator, because that's the way that's supposed to work...
                pathOut.Segments(1) = pathOut.Segments(1) + pathOut.Separator;
            end
        end
    end
    methods % Operator overloading
        function pathOut = mrdivide(path1, path2)
            arguments
                path1
                path2
            end
            if ~ismember(class(path1), {'char', 'string', 'Path'})
                error('Path slash operator is only compatible with char, string, or another Path');
            end
                
            switch class(path1)
                case {'char', 'string'}
                    % path2 must be a Path object
                    pathOut = path2.prepend(path1);
                case 'Path'
                    switch class(path2)
                        case {'char', 'string'}
                            pathOut = path1.append(path2);
                        case 'Path'
                            pathOut = path1.append(path2.Segments);
                    end
            end
        end
        function out = eq(path1, path2)
            path2 = Path(path2);
            out = true;
            if length(path1.Segments) ~= length(path2.Segments)
                out = false;
            else
                for k = 1:length(path1.Segments)
                    if ~strcmp(path1.Segments(k), path2.Segments(k))
                        out = false;
                        break;
                    end
                end
            end
        end
        function disp(path1)
            fn = mfilename("fullpath");
            helpLink = sprintf('<a href="matlab:helpPopup ''%s''">Path</a>', fn);
            if length(path1) == 1
                str = path1.str;
                if isempty(str)
                    str = "";
                end
                fprintf('\t%s object: \n\t\t%s\n\n', helpLink, str);
            else
                sz = join(string(size(path1)), 'x');
                fprintf('\t%s %s array:\n', sz, helpLink)
                disp(arrayfun(@(p)p.str, path1))
            end
        end
%         function output = isempty(path)
%             output = isempty(path.Segments);
%         end
    end
    methods
%         function as_posix(path1)
%         end
        function absolute = is_absolute(path1)
            absolute = path1.isSegmentRoot(1);
        end
%         function is_relative_to(path1)
% 
%         end
%         function is_reserved(path1)
%         end
        function pathOut = joinpath(path1, paths)
            arguments (Repeating)
                path1 Path
                paths
            end
            pathOut = path1;
            for path2 = paths
                pathOut = pathOut / path2;
            end
        end
%         function full_match(path1)
%         end
%         function match(path1)
%         end
        function pathOut = relative_to(path1, path2)
            arguments
                path1 Path
                path2
            end
            path2 = Path(path2);
            for k = 1:length(path2.Segments)
                if k > length(path1.Segments) || ~strcmp(path1.Segments(k), path2.Segments(k))
                    error('Path:notASubfolder', 'Path %s is not a subfolder of %s', path1.str, path2.str);
                end
            end
            pathOut = path1;
            pathOut.Segments = path1.Segments(k+1:end);
        end
        function pathOut = with_name(path1, name)
            pathOut = path1;
            if isempty(pathOut.name)
                error('Path:noName', 'Cannot return path with new name if it does not already have a name');
            end

            pathOut.Segments(end) = name;
        end
        function pathOut = with_stem(path1, stem)
            pathOut = path1;
            if isempty(pathOut.name)
                error('Path:noName', 'Cannot return path with new stem if it does not already have a stem');
            end

            newStem = string(stem);
            newName = newStem + path1.suffix;
            pathOut = path1.with_name(newName);
        end
        function pathOut = with_suffix(path1, suffix)
            pathOut = path1.with_name(path1.stem + suffix);
        end
        function with_segments(path1, newSegments)
            pathOut = path1;
            pathOut.Segments = newSegments;
        end
%         function from_uri(path1)
%         end
%         function as_uri(path1)
%         end
%         function home(path1)
%         end
%         function expanduser(path1)
%         end
        function d = cwd(~)
            d = pwd();
        end
        function pathOut = absolute(path1, checkFiles)
            arguments
                path1 Path
                checkFiles logical = true
            end
            if checkFiles && ~path1.exists()
                error('Path:fileNotFound', 'File %s not found.', path1.str);
            end
            if path1.is_absolute()
                % path1 is already absolute (even if it's fictional)
                pathOut = path1;
                return
            end
            % path1 is not absolute - attempt to make it absolute by 
            % referencing cwd in file system
            try
                pathOut = Path(getAbsolutePath(path1.str));
            catch ME
                switch ME.identifier
                    case 'getAbsolutePath:pathDoesNotExist'   
                        % Ok, doesn't exist, just tack it onto the cwd
                        pathOut = path1.cwd() / path1;
                    otherwise
                        rethrow(ME);
                end
            end
        end
%         function resolve(path1)
%         end
%         function readlink(path1)
%         end
        function stats = stat(path1)
            if ~path1.exists()
                error('File does not exist');
            end
            stats = fileattrib(path1);
        end
%         function lstat(path1)
%         end
        function ex = exists(path1)
            if exist(path1.str, 'file')
                ex = true;
                return
            end
            try
                abs_str = path1.absolute(false);
                if exist(abs_str, 'file')
                    ex = true;
                    return;
                else
                    ex = false;
                    return
                end
            catch
                ex = false;
                return
            end
        end
        function out = is_file(path1)
            out = exist(path1.str, 'file') && ~exist(path1.str, 'dir');
        end
        function out = is_dir(path1)
            out = exist(path1.str, 'dir');
        end
%         function is_symlink(path1)
%         end
%         function is_junction(path1)
%         end
        function out = is_mount(path1)
            out = length(path1.Segments) == 1 && path1.isSegmentRoot(1);
        end
%         function is_socket(path1)
%         end
%         function is_fifo(path1)
%         end
%         function is_block_device(path1)
%         end
%         function is_char_device(path1)
%         end
        function out = samefile(path1, path2)
            path1 = path1.absolute();
            path2 = path2.absolute();
            out = path1 == path2;
        end
        function fid = open(path1, mode)
            arguments
                path1 Path
                mode char {mustBeMember(mode, ["r", "w", "a", "r+", "w+", "a+", "A", "W"])} = "r"
            end
            fid = fopen(path1, mode);
        end
        function text = read_text(path1)
            fid = path1.open();
            text = string(char(fread(fid)'));
            fclose(fid);
        end
        function bytes = read_bytes(path1)
            fid = path1.open();
            bytes = fread(fid, 'uint8=>uint8')';
            fclose(fid);
        end
        function write_text(path1, text, mode)
            arguments
                path1 Path
                text {mustBeText}
                mode char {mustBeMember(mode, ["w", "a", "r+", "w+", "a+", "A", "W"])} = "r"
            end
            fid = path1.open(mode);
            fwrite(fid, text);
            fclose(fid);
        end
        function write_bytes(path1, bytes, mode)
            arguments
                path1 Path
                bytes uint8
                mode char {mustBeMember(mode, ["w", "a", "r+", "w+", "a+", "A", "W"])} = "r"
            end
            fid = path1.open(mode);
            fwrite(fid, bytes);
            fclose(fid);
        end
        function segments = iterdir(path1)
            segments = path1.Segments;
        end
        function [files, isdirs] = glob(path1, pattern)
            pattern = fullfile(path1.str, pattern);
            fileStruct = dir(pattern);
            files = [];
            isdirs = logical.empty();
            for fileInfo = fileStruct'
                if isDotDir(fileInfo.name)
                    continue
                end
                files = [files, Path(fullfile(fileInfo.folder, fileInfo.name))]; %#ok<AGROW> 
                isdirs = [isdirs, fileInfo.isdir]; %#ok<AGROW> 
            end
        end
%         function rglob(path1)
%         end
        function out = walk(path1)
            arguments
                path1 Path
            end
            if ~path1.exists()
                error('Path:fileNotFound', 'File %s not found.', path1.str);
            end
            [contents, isdirs] = path1.glob('*');
            dirInfo.root = path1;
            dirInfo.dirs = contents(isdirs);
            dirInfo.files = contents(~isdirs);
            out = dirInfo;
            for k = 1:length(dirInfo.dirs)
                out = [out, dirInfo.dirs(k).walk()]; %#ok<AGROW> 
            end
        end
%         function symlink_to(path1)
%         end
%         function hardlink_to(path1)
%         end
        function [status, msg, msgID] = rename(path1, path2)
            path1 = Path(path1);
            path2 = Path(path2);
            if path2.exists()
                error('Path:fileExists', 'Renaming would overwrite %s', path2.str);
            end
            [status, msg, msgID] = movefile(path1.str, path2.str);
        end
        function [status, msg, msgID] = replace(path1, path2)
            path1 = Path(path1);
            path2 = Path(path2);
            [status, msg, msgID] = movefile(path1.str, path2.str);
        end
%         function unlink(path1)
%         end
        function [status, msg, msgID] = rmdir(path1)
            path1 = Path(path1);
            [status, msg, msgID] = rmdir(path1.str);
        end
%         function owner(path1)
%         end
%         function group(path1)
%         end
%         function chmod(path1)
%         end
%         function lchmod(path1)
%         end
    end
    methods % Getters
        function drive = get.drive(path1)
            if path1.isSegmentRoot(1)
                drive = strrep(path1.Segments(1), path1.Separator, "");
            else
                drive = "";
            end
        end
        function root = get.root(path1)
            if path1.isSegmentRoot(1)
                root = path1.Separator;
            else
                root = "";
            end
        end
        function anchor = get.anchor(path1)
            if path1.isSegmentRoot(1)
                anchor = path1.Segments(1);
            else
                anchor = "";
            end
        end
        function parents = get.parents(path1)
            parents = path1.Segments(1:end-1);
        end
        function parent = get.parent(path1)
            parent = path1;
            if length(parent.Segments) > 1
                % More than one segment, just return last segment
                parent.Segments(end) = [];
            elseif isempty(parent.Segments) || ~parent.isSegmentRoot()
                % No segments, or only one non-root segment...return relative root
                parent.Segments = path1.RelativeRoot;
            elseif parent.isSegmentRoot()
                % Only segment is root - change nothing
            end
        end
        function name = get.name(path1)
            if isempty(path1.Segments) || path1.isSegmentRoot()
                name = "";
            else
                name = path1.Segments(end);
            end
        end
        function suffix = get.suffix(path1)
            [~, stem, suffix] = fileparts(path1.name); %#ok<*PROP> 
            if isempty(stem)
                % This is a .file
                suffix = "";
            end
        end
        function suffixes = get.suffixes(path1)
            parts = split(path1.name, ".");
            if strlength(parts(1)) == 0
                % First part is a .file
                parts(1) = [];
            end
            suffixes = arrayfun(@(x)"."+x, parts(2:end));
        end
        function stem = get.stem(path1)
            [~, stem, ext] = fileparts(path1.name);
            if strlength(stem) == 0
                % This is a .file
                stem = ext;
            end
        end
        function str = get.str(path1)
            segments = path1.Segments;
            if path1.isSegmentRoot(1)
                segments(1) = strrep(segments(1), path1.Separator, "");
            end
            str = join(segments, path1.Separator);
        end
    end
    methods (Access = private)
        function pathOut = prepend(path1, pathOrSegments)
            arguments
                path1 Path
                pathOrSegments
            end
            if isa(pathOrSegments, 'Path')
                pathOrSegments = pathOrSegments.Segments;
            end
            path2 = path1;
            path2.Segments = pathOrSegments;
            pathOut = path1;
            pathOut.Segments = [path2.Segments, path1.Segments];
        end
        function pathOut = append(path1, pathOrSegments)
            arguments
                path1 Path
                pathOrSegments
            end
            if isa(pathOrSegments, 'Path')
                pathOrSegments = pathOrSegments.Segments;
            end
            path2 = path1;
            path2.Segments = pathOrSegments;
            pathOut = path1;
            pathOut.Segments = [path1.Segments, path2.Segments];
        end
        function isRoot = isSegmentRoot(path1, segmentIdx)
            arguments
                path1 Path
                segmentIdx = length(path1.Segments)
            end
            segment = path1.Segments(segmentIdx);
            switch path1.Flavor
                case "Windows"
                    isRoot = length(regexp(segment, '^[a-zA-Z]\:\\$')) == 1;
                case "Posix"
                    isRoot = strcmp(segment, '/');
            end
        end
        function isDrive = isDrive(path1, str)
            arguments
                path1 Path
                str {mustBeTextScalar}
            end
            switch path1.Flavor
                case "Windows"
                    isDrive = length(regexp(str, '^[a-zA-Z]\:$')) == 1;
                case "Posix"
                    isDrive = isempty(str);
            end            
        end
%         function segmentIdx = parseSegmentIdx(path1, segmentIdx)
%             if segmentIdx < 0
%                 segmentIdx = 
%             end
%         end
    end
    methods (Static)
        function pathOut = pwd()
            pathOut = Path(pwd());
        end
        function mkdir(path1)
            path1 = Path(path1);
            mkdir(path1.str);
        end
%         function touch(path1)
%             path1 = Path(path1);
%             if ~path1.parent.exists()
%                 error('Path:fileNotFound', 'Directory %s not found.', path1.parent.str);
%             end
%             system(sprintf('touch, %s', path1.str));
%         end
    end
end