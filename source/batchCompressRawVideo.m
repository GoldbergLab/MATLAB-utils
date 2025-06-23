function record = batchCompressRawVideo(videoRoot, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% batchCompressRawVideo: <short description>
% usage: bbatchCompressRawVideo(videoRoot, "Name", "Value", ...)
%
% where,
%    videoRoot is the path to the folder to be searched for videos
%    record is a Nx2 cell array containing paths or names of videos found
%       in column 1, and paths or names of videos converted in column 2
%    Name/Value pairs can be:
%       VideoExtension: The video extension to look for. Default is "avi"
%       CRF: The h264 "constant rate factor". 0 is lossless, 52 is max
%           compression. ~23 is generally a good balance between size and 
%           quality
%       SearchSubdirectories: A logical indicating whether or not to search
%           for video files recursively. Default is false
%       CompressedVideoTag: A tag to add to the filename before the 
%           extension when writing the compressed videos. Default is ''
%       DryRun: A logical indicating whether or not to do a dry run, which
%           will print out what the command would have done, rather than
%           actually converting any videos. Default is true.
%       Overwrite: A logical indicating whether or not to overwrite files 
%           that already exist. Default is false.
%       Parallelize: A logical indicating whether or not to batch convert
%           in parallel or not. Default is true.
%       RecordNameOnly: A logical indicating if only names of files should
%           be included in the output record, rather than full paths. 
%           Default is true.
%
% This function is designed to batch convert videos encoded with the
%   "rawvideo" codec to a compressed video format.
%
% See also: compressRawVideo
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    videoRoot {mustBeTextScalar}
    options.VideoExtension {mustBeTextScalar} = 'avi'
    options.CRF {mustBeNumeric} = 0
    options.SearchSubdirectories logical = false
    options.CompressedVideoTag {mustBeTextScalar} = ''
    options.DryRun {logical} = true
    options.OverWrite logical = false
    options.Parallelize logical = true
    options.RecordNameOnly logical = true
end

% Get list of videos with that extension
options.VideoExtension = regexprep(options.VideoExtension, '[^a-zA-Z0-9]', '');
videos = findFiles( ...
    videoRoot, ...
    ['.*\.', options.VideoExtension], ...
    "SearchSubdirectories", ...
    options.SearchSubdirectories ...
    );

record = cell(length(videos), 2);

if options.Parallelize
    % Loop over videos in parallel
    parfor k = 1:length(videos)
        record(k, :) = compressSingleVideo(videos, k, options);
    end
else
    % Loop over videos
    for k = 1:length(videos)
        record(k, :) = compressSingleVideo(videos, k, options);
    end
end

% If requested, remove path info from record
if options.RecordNameOnly
    for r = 1:size(record, 1)
        for c = 1:size(record, 2)
            [~, name, ext] = fileparts(record{r, c});
            record{r, c} = [name, ext];
        end
    end
end

function record = compressSingleVideo(videos, k, options)
fprintf('Converting %d of %d\n', k, length(videos));
videoPath = videos{k};
record = {videoPath, ''};
% Construct compressed filename
[root, name, ext] = fileparts(videoPath);
compressedVideoPath = fullfile( ...
    root, ...
    [name, options.CompressedVideoTag, ext] ...
    );
try
    if strcmp(videoPath, compressedVideoPath)
        % Original and compressed paths are the same, gotta do a dance
        nameSwap = true;
        finalCompressedVideoPath = compressedVideoPath;
        [root, name, ext] = fileparts(compressedVideoPath);
        compressedVideoPath = fullfile( ...
            root, ...
            [name, '_TEMP_COMPRESSED_', char(datetime('today')), ext] ...
            );
    else
        nameSwap = false;
    end
    if ~options.DryRun
        % Not a dry run, compress the video
        compressRawVideo( ...
            videoPath, ...
            compressedVideoPath, ...
            "CheckFFmpeg", false, ...
            "CRF", options.CRF, ...
            "VerifyRaw", true, ...
            'OverWrite', options.OverWrite ...
            );
    end
    if nameSwap
        % Overwrite original
        if ~options.DryRun
            movefile(compressedVideoPath, finalCompressedVideoPath);
        end
        compressedVideoPath = finalCompressedVideoPath;
    end
    if options.DryRun
        % Dry run, print what would have been done
        fprintf( ...
            'DRY RUN: Would have converted\n\t%s \n\t\tto \n\t%s\n', ...
            videoPath, ...
            compressedVideoPath ...
            );
    end
    record{2} = compressedVideoPath;
catch ME
    if strcmp(ME.identifier, 'MATLAB_utils:notRawVideo')
        % Video is not encoded with rawvideo codec, skip it
        warning('Skipping non-raw video: %s', videoPath);
        record{2} = '*SKIPPED*';
    else
        rethrow(ME)
    end
end
