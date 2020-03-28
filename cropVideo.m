function cropVideo(videoPath, varargin)
% cropVideo: Save a cropped copy of a video (in space and/or time), and 
%   optionally crop a corresponding manualObjectTracker ROI mat file
% usage:  cropVideo(videoPath)
%         cropVideo(videoPath, cropROI)
%         cropVideo(videoPath, cropROI, ROIPath)
%         cropVideo(____, Name, Value)
%
% where,
%    videoPath is the path to a video file.
%    cropROI is an optional boolean flag to also crop the corresponding 
%       manual object tracking ROI. Default is false.
%    ROIPath is an optional path to an ROI file. If omitted, the default is
%       to look in the ROIs subfolder of the video folder for a .mat file
%       with the same name.
%    Any combination of the following Name/Value pairs are possible:
%        LeftTrim - amount to chop off left size of video (default 0)
%        RightTrim - amount to chop off right side of video (default 0)
%        TopTrim - amount to chop off top side of video (default 0)
%        BottomTrim - amount to chop off bottom side of video (default 0)
%        StartTrim - # of frames to chop off the start of the video (default 0)
%        EndTrim - # of frames to chop off the end of the video (default 0)
%        Width - width of video. (default - to right edge of video)
%        Height - height of video. (default - to bottom edge of video)
%        Frames - number of frames. (default - to end of video)
%        x0 - left coord of crop rectangle (default 1)
%        y0 - top coord of crop rectangle (default 1)
%        x1 - right coord of crop rectangle (default right corner of video)
%        y1 - bottom coord of crop rectangle (default bottom corner of video)
%        f0 - the start frame to crop to
%        f1 - the end frame to crop to
%
%   Argument precedence: If multiple conflicting arguments are supplied,
%       x0, y0, x1, y1 take precedence over LeftTrim, TopTrim, RightTrim, 
%       and BottomTrim (respectively), which take precedence over Width and
%       Height. On the other hand, why would you specify conflicting
%       arguments? Get your shit together!
%
%   Note that all coordinates begin at the upper left corner at pixel
%       coordinate (1, 1)
%
% See also: 
%   loadVideoData
%   saveVideoData
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})

defaultLeftTrim = 0;
defaultRightTrim = 0;
defaultTopTrim = 0;
defaultBottomTrim = 0;
defaultStartTrim = 0;
defaultEndTrim = 0;
defaultWidth = nan;
defaultHeight = nan;
defaultFrames = nan;
defaultX0 = nan;
defaultY0 = nan;
defaultX1 = nan;
defaultY1 = nan;
defaultF0 = nan;
defaultF1 = nan;

p = inputParser;
isPositiveValue = @(x1) x1 > 0;
isValidFile = @(f) exist(f, 'file');
addRequired(p, 'videoPath', isValidFile);
addOptional(p, 'cropROI', false);
addOptional(p, 'ROIPath', nan);
addParameter(p, 'LeftTrim', defaultLeftTrim);
addParameter(p, 'RightTrim', defaultRightTrim);
addParameter(p, 'TopTrim', defaultTopTrim);
addParameter(p, 'BottomTrim', defaultBottomTrim);
addParameter(p, 'StartTrim', defaultStartTrim);
addParameter(p, 'EndTrim', defaultEndTrim);
addParameter(p, 'Width', defaultWidth, isPositiveValue);
addParameter(p, 'Height', defaultHeight, isPositiveValue);
addParameter(p, 'Frames', defaultFrames, isPositiveValue);
addParameter(p, 'x0', defaultX0);
addParameter(p, 'y0', defaultY0);
addParameter(p, 'x1', defaultX1);
addParameter(p, 'y1', defaultY1);
addParameter(p, 'f0', defaultF0);
addParameter(p, 'f1', defaultF1);

parse(p, videoPath, varargin{:});

LeftTrim = p.Results.LeftTrim;
RightTrim = p.Results.RightTrim;
TopTrim = p.Results.TopTrim;
BottomTrim = p.Results.BottomTrim;
StartTrim = p.Results.StartTrim;
EndTrim = p.Results.EndTrim;
Width = p.Results.Width;
Height = p.Results.Height;
Frames = p.Results.Frames;
x0 = p.Results.x0;
y0 = p.Results.y0;
x1 = p.Results.x1;
y1 = p.Results.y1;
f0 = p.Results.f0;
f1 = p.Results.f1;
cropROI = p.Results.cropROI;
ROIPath = p.Results.ROIPath;

[videoFolder, videoName, videoExt] = fileparts(videoPath);

% Load video data
videoData = loadVideoData(videoPath);
videoSize = size(videoData);
if length(videoSize) == 3
    [vHeight, vWidth, nFrames] = size(videoData);
elseif length(videoSize) == 4
    [vHeight, vWidth, nFrames, nChannels] = size(videoData);
end

% Calculate UL and LR coordinates of crop rectangle
if isnan(x0)
    x0 = 1 + LeftTrim;
end
if isnan(x1)
    if isnan(Width)
        if isnan(RightTrim)
            % No RightTrim given, default to right edge of video
            x1 = vWidth;
        else
            % No Width given, get it from RightTrim
            x1 = vWidth - RightTrim;
        end
    else
        % Width given - use that to get x1
        x1 = x0 + Width;
    end
end
if isnan(y0)
    y0 = 1 + TopTrim;
end
if isnan(y1)
    if isnan(Height)
        if isnan(BottomTrim)
            % No BottomTrim given, default to bottom edge of video
            y1 = vHeight;
        else
            % No Height given, get it from BottomTrim
            y1 = vHeight - BottomTrim;
        end
    else
        % Height given - use that to get x1
        y1 = y0 + Height;
    end
end
if isnan(f0)
    f0 = 1 + StartTrim;
end
if isnan(f1)
    if isnan(Frames)
        if isnan(EndTrim)
            % No EndTrim given, default to last frame of video
            f1 = nFrames;
        else
            % No Frames given, get it from EndTrim
            f1 = nFrames - EndTrim;
        end
    else
        % Frames given - use that to get f1
        f1 = f0 + Frames;
    end
end

if x0 <= 0 || y0 <= 0
    error('Upper left corner coordinates must be >= 1')
end
if f0 <= 0
    error('First frame number must be >= 1')
end

% Warn if crop rectangle is off the edge of the video frame
if x1 > vWidth || y1 > vHeight
    error('Crop rectangle is not contained within video frame.')
end
if f1 > nFrames
    error('Cannot crop to frame after end of video.')
end

% Crop!
croppedVideoData = videoData(y0:y1, x0:x1, f0:f1);
croppedVideoFile = fullfile(videoFolder, [videoName, '_cropped', videoExt]); 
saveVideoData(croppedVideoData, croppedVideoFile);

% Crop ROI
if cropROI
    if isnan(ROIPath)
        ROIPath = fullfile(videoFolder, 'ROIs', [videoName, '_ROI.mat']);
    end
    [croppedVideoFolder, croppedVideoName, ~] = fileparts(croppedVideoFile);
    ROICroppedPath = fullfile(croppedVideoFolder, 'ROIs', [croppedVideoName, '_ROI.mat']);
    load(ROIPath);

    outputStruct.videoFile = croppedVideoFile;
    outputStruct.videoSize = [y1 - y0 + 1, x1 - x0 + 1, f1 - f0 + 1];

    users = fieldnames(outputStruct.ROIData);
    for k=1:numel(users)
        outputStruct.ROIData.(users{k}).xPoints = outputStruct.ROIData.(users{k}).xPoints(:, f0:f1);
        outputStruct.ROIData.(users{k}).yPoints = outputStruct.ROIData.(users{k}).yPoints(:, f0:f1);
        outputStruct.ROIData.(users{k}).xFreehands = outputStruct.ROIData.(users{k}).xFreehands(:, f0:f1);
        outputStruct.ROIData.(users{k}).yFreehands = outputStruct.ROIData.(users{k}).yFreehands(:, f0:f1);
        outputStruct.ROIData.(users{k}).xProj = outputStruct.ROIData.(users{k}).xProj(:, f0:f1);
        outputStruct.ROIData.(users{k}).zProj = outputStruct.ROIData.(users{k}).zProj(:, f0:f1);
        structSize = size(outputStruct.ROIData.(users{k}).xFreehands);
        nROIs = structSize(1);
        for f=1:(f1 - f0 + 1)
            for r=1:nROIs
                outputStruct.ROIData.(users{k}).xPoints{r, f} = outputStruct.ROIData.(users{k}).xPoints{r, f} - x0 + 1;
                outputStruct.ROIData.(users{k}).yPoints{r, f} = outputStruct.ROIData.(users{k}).yPoints{r, f} - y0 + 1;
                outputStruct.ROIData.(users{k}).xFreehands{r, f} = outputStruct.ROIData.(users{k}).xFreehands{r, f} - x0 + 1;
                outputStruct.ROIData.(users{k}).yFreehands{r, f} = outputStruct.ROIData.(users{k}).yFreehands{r, f} - y0 + 1;
                outputStruct.ROIData.(users{k}).xProj{r, f} = outputStruct.ROIData.(users{k}).xProj{r, f} - x0 + 1;
                outputStruct.ROIData.(users{k}).zProj{r, f} = outputStruct.ROIData.(users{k}).zProj{r, f} - y0 + 1;
            end
        end
    end
    save(ROICroppedPath, 'outputStruct');
end