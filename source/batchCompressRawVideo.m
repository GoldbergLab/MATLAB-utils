function batchCompressRawVideo(videoRoot, options)
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