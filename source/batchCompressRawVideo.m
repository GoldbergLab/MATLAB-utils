function batchCompressRawVideo(videoRoot, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% batchCompressRawVideo: <short description>
% usage: bbatchCompressRawVideo(videoRoot, "Name", "Value", ...)
%
% where,
%    videoRoot is <description>
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
end

% Get list of videos with that extension
options.VideoExtension = regexprep(options.VideoExtension, '[^a-zA-Z0-9]', '');
videos = findFiles(videoRoot, ['.*\.', options.VideoExtension], "SearchSubdirectories", options.SearchSubdirectories);

% Loop over videos
parfor k = 1:length(videos)
    fprintf('Converting %d of %d\n', k, length(videos));
    videoPath = videos{k};

    % Construct compressed filename
    [root, name, ext] = fileparts(videoPath);
    compressedVideoPath = fullfile(root, [name, options.CompressedVideoTag, ext]);
    try
        if ~options.DryRun
            % Not a dry run, compress the video
            compressRawVideo(videoPath, compressedVideoPath, "CheckFFmpeg", false, "CRF", options.CRF, "VerifyRaw", true, 'OverWrite', options.OverWrite);
        else
            % Dry run, print what would have been done
            fprintf('DRY RUN: Would have converted\n\t%s \n\t\tto \n\t%s\n', videoPath, compressedVideoPath);
        end
    catch ME
        if strcmp(ME.identifier, 'MATLAB_utils:notRawVideo')
            % Video is not encoded with rawvideo codec, skip it
            warning('Skipping non-raw video: %s', videoPath);
        else
            rethrow(ME)
        end
    end
end