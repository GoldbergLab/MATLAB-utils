function videoData = loadVideoData(videoFilename, varargin)
%This currently works with grayscale avi and tif files

if nargin > 1
    makeGrayscale = varargin{1};
else
    makeGrayscale = true;
end

[~, ~, ext] = fileparts(videoFilename);

if strcmp(ext, '.tif')
    % Check if file is a .tif file
    tiffInfo = imfinfo(videoFilename);
    numFrames = length(tiffInfo);
    width = tiffInfo(1).Width;
    height = tiffInfo(1).Height;
    videoData = zeros([height, width, numFrames]);
    for k = 1:numFrames
        videoData(:, :, k) = imread(videoFilename, k);
    end
else
    try
        video = VideoReader(videoFilename);
        videoData = read(video);
    catch
        try
            video = VideoReader(videoFilename);
            disp('Method 1 failed, attempting to load video with method #2');
            videoDataStruct = read(video, [1, video.NumberOfFrames], 'native');
            videoData = zeros([size(videoDataStruct(1).cdata), length(videoDataStruct)]);
            for k = 1:length(videoDataStruct)
                videoData(:, :, k) = videoDataStruct(k).cdata;
            end
        catch
            try
                video = VideoReader(videoFilename);
                %    disp('Attempting to load video with method #1');
                videoDataStruct = read(video, [1, Inf], 'native');
                videoData = zeros([size(videoDataStruct(1).cdata), length(videoDataStruct)]);
                for k = 1:length(videoDataStruct)
                    videoData(:, :, k) = videoDataStruct(k).cdata;
                end
            catch
                video = VideoReader(videoFilename);
                disp('Method 3 failed, attempting to load video with method #4');
                videoData = zeros(video.Height, video.Width, int32(video.Duration * video.FrameRate));
                frameNum = 1;
                while hasFrame(video)
                    videoData(:, :, frameNum) = video.readFrame('native').cdata;
                    frameNum = frameNum + 1;
                end
            end
        end
    end
end

% Get rid of duplicate RGB channels
videoDataSize = size(videoData);
if length(videoDataSize) == 4 && videoDataSize(3) == 3 && makeGrayscale
    % third dimension is probably color channels
    videoData = squeeze(videoData(:, :, 1, :));
end