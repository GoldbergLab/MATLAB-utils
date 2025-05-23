function videoStats = getVideoStats(videoPath, tags)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getVideoStats: Use ffprobe to extract video statistics
% usage: videoStats = getVideoStats(videoPath, tags)
%        videoStats = getVideoStats()
%
% where,
%    videoPath is a char array path to a video file
%    tags is either a single tag or a cell array of multiple tags, where a 
%       "tag" is the name of a video statistic to extract for each frames
%    videoStats is a struct array, where videoStats(k).(tag1) is the value
%       of the statistic given by tag1 for the kth frame of the video
%
% If you call this function with no arguments, a list of valid tags will
%   be printed to the console.
%
% See also: getVideoInfo, loadVideoData
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    videoPath (1, :) char = ''
    tags {mustBeText} = ''
end

valid_metadata_tags = {'YMIN', 'YLOW', 'YAVG', 'YHIGH', 'YMAX', 'UMIN', 'ULOW', 'UAVG', 'UHIGH', 'UMAX', 'VMIN', 'VLOW', 'VAVG', 'VHIGH', 'VMAX', 'SATMIN', 'SATLOW', 'SATAVG', 'SATHIGH', 'SATMAX', 'HUEMED', 'HUEAVG', 'YDIF', 'UDIF', 'VDIF', 'YBITDEPTH', 'UBITDEPTH', 'VBITDEPTH'};

if nargin == 0
    doc_url = 'https://ffmpeg.org/ffmpeg-filters.html#signalstats-1';
    fprintf('Valid tags, retrieved from %s\n', doc_url)
    fprintf([
        'YMIN\n' ...
        '  Display the minimal Y value contained within the input frame. Expressed in range of [0-255].\n' ...
        'YLOW\n' ...
        '  Display the Y value at the 10%% percentile within the input frame. Expressed in range of [0-255].\n' ...
        'YAVG\n' ...
        '  Display the average Y value within the input frame. Expressed in range of [0-255].\n' ...
        'YHIGH\n' ...
        '  Display the Y value at the 90%% percentile within the input frame. Expressed in range of [0-255].\n' ...
        'YMAX\n' ...
        '  Display the maximum Y value contained within the input frame. Expressed in range of [0-255].\n' ...
        'UMIN\n' ...
        '  Display the minimal U value contained within the input frame. Expressed in range of [0-255].\n' ...
        'ULOW\n' ...
        '  Display the U value at the 10%% percentile within the input frame. Expressed in range of [0-255].\n' ...
        'UAVG\n' ...
        '  Display the average U value within the input frame. Expressed in range of [0-255].\n' ...
        'UHIGH\n' ...
        '  Display the U value at the 90%% percentile within the input frame. Expressed in range of [0-255].\n' ...
        'UMAX\n' ...
        '  Display the maximum U value contained within the input frame. Expressed in range of [0-255].\n' ...
        'VMIN\n' ...
        '  Display the minimal V value contained within the input frame. Expressed in range of [0-255].\n' ...
        'VLOW\n' ...
        '  Display the V value at the 10%% percentile within the input frame. Expressed in range of [0-255].\n' ...
        'VAVG\n' ...
        '  Display the average V value within the input frame. Expressed in range of [0-255].\n' ...
        'VHIGH\n' ...
        '  Display the V value at the 90%% percentile within the input frame. Expressed in range of [0-255].\n' ...
        'VMAX\n' ...
        '  Display the maximum V value contained within the input frame. Expressed in range of [0-255].\n' ...
        'SATMIN\n' ...
        '  Display the minimal saturation value contained within the input frame. Expressed in range of [0-~181.02].\n' ...
        'SATLOW\n' ...
        '  Display the saturation value at the 10%% percentile within the input frame. Expressed in range of [0-~181.02].\n' ...
        'SATAVG\n' ...
        '  Display the average saturation value within the input frame. Expressed in range of [0-~181.02].\n' ...
        'SATHIGH\n' ...
        '  Display the saturation value at the 90%% percentile within the input frame. Expressed in range of [0-~181.02].\n' ...
        'SATMAX\n' ...
        '  Display the maximum saturation value contained within the input frame. Expressed in range of [0-~181.02].\n' ...
        'HUEMED\n' ...
        '  Display the median value for hue within the input frame. Expressed in range of [0-360].\n' ...
        'HUEAVG\n' ...
        '  Display the average value for hue within the input frame. Expressed in range of [0-360].\n' ...
        'YDIF\n' ...
        '  Display the average of sample value difference between all values of the Y plane in the current frame and corresponding values of the previous input frame. Expressed in range of [0-255].\n' ...
        'UDIF\n' ...
        '  Display the average of sample value difference between all values of the U plane in the current frame and corresponding values of the previous input frame. Expressed in range of [0-255].\n' ...
        'VDIF\n' ...
        '  Display the average of sample value difference between all values of the V plane in the current frame and corresponding values of the previous input frame. Expressed in range of [0-255].\n' ...
        'YBITDEPTH\n' ...
        '  Display bit depth of Y plane in current frame. Expressed in range of [0-16].\n' ...
        'UBITDEPTH\n' ...
        '  Display bit depth of U plane in current frame. Expressed in range of [0-16].\n' ...
        'VBITDEPTH\n' ...
        '  Display bit depth of V plane in current frame. Expressed in range of [0-16].\n' ...
    ])
    return
end

if ~iscell(tags)
    tags = {tags};
end

% Check that ffprobe exists on system path
[ffprobeStatus, ~] = system('where /q ffprobe');
if ffprobeStatus ~= 0
    error('To use fastVideoReader, ffprobe must be installed and available on the system path. See https://ffmpeg.org/download.html.');
end

% Format tags into the appropriate command format
formatted_tags = cell(size(tags));
for k = 1:length(tags)
    tag = tags{k};
    % Make sure each tag is valid
    if ~any(strcmp(tag, valid_metadata_tags))
        error('Invalid tag: %s', tag);
    end
    formatted_tags{k} = sprintf('lavfi.signalstats.%s', tag);
end
formatted_tags = join(formatted_tags, ',');
formatted_tags = formatted_tags{1};

% Escape video path special characters so ffprobe can parse it
videoPath = regexprep(videoPath, '\\|:', '\\$0');

% Construct ffprobe command
command = sprintf('ffprobe -v error -f lavfi "movie=''%s'',signalstats" -show_entries frame_tags=%s -of csv=p=0:nk=1', videoPath, formatted_tags);

% Call ffprobe and capture output
[status, cmdout] = system(command);

% Check if ffprobe completed successfully
if status ~= 0
    error(cmdout)
end

% Initialize videoStats struct
videoStats = struct();

% Convert csv formatted string containing statistics to a numerical matrix
values = str2num(cmdout); %#ok<ST2NM> 

% Determine number of frames
numFrames = size(values, 1);

% ffprobe seems to output the tags in a set order regardless of the user input order
ordered_tags = valid_metadata_tags(cellfun(@(t)any(strcmp(t, tags)), valid_metadata_tags));

% Load each set of statistics into the struct array under the correct tag name
for k = 1:length(ordered_tags)
    tag = ordered_tags{k};
    vals = num2cell(values(:, k));
    [videoStats(1:numFrames).(tag)] = vals{:};
end
