function videoData = createTrackingVideo(videoPath, roiPath, cropSize, isoluminant)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% createTrackingVideo: Create a video which keeps a single target stable
% usage:  videoData = createTrackingVideo(videoPath)
%         videoData = createTrackingVideo(videoPath, roiPath)
%         videoData = createTrackingVideo(videoPath, roiPath, cropSize)
%         videoData = createTrackingVideo(videoPath, [], cropSize)
%
% where,
%    videoPath is a char array representing the path to a video file
%    roiPath is an optional char array representing the path to a
%       manualObjectTracker output file corresponding to the videoPath. If
%       omitted or empty, the default path where manualObjectTracker stores
%       output files will be used.
%    cropSize is an optional 1x1 or 1x2 array representing the desired size
%       of the output video, stabilized and centered on the tracked point.
%       If 1x1, the output video will be square with cropSize as the side
%       length. If 1x2, the output video will be a rectangle with width and
%       height given by the elements of cropSize. If omitted or empty, the
%       output video will not be cropped at all.
%    isoluminant is an optional boolean flag indicating whether or not to
%       make the resulting video isoluminant. Default is false.
%    videoData is a 3D or 4D array representing the tracking video. If 3D,
%       the dimensions will be HxWxN, and if 4D, HxWx3xN
%
% This function creates a tracking video from a saved video file and a
%   manualObjectTracker output file. A typical workflow goes like so:
%   1. Open manualObjectTracker
%   2. Use "Point" mode to track a single target in the video. It's ok to
%       skip frames - missing frames will be filled in using interpolation.
%   3. manualObjectTracker should automatically save the "ROI" file, but 
%       ensure it has been saved.
%   4. Run this function to produce a modified video which keeps the target
%      stationary, and optionally crops the video around the target and/or
%      makes the resulting video isoluminant to alleviate distracting 
%      lighting changes around the target.
%
% See also: manualObjectTracker, stabilizeVideo, makeVideoIsoluminant
%
% Version: 1.1
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('roiPath', 'var') || isempty(roiPath)
    % No ROI path provided - attempt to find it in the default 
    % manualObjectTracker ROI path for this video
    [basePath, videoName, ~] = fileparts(videoPath);
    roiPath = fullfile(basePath, 'ROIs', [videoName, '_ROI.mat']);
end
if ~exist('cropSize', 'var') || isempty(cropSize)
    % No cropping
    cropSize = [];
end
if ~exist('isoluminant', 'var') || isempty(isoluminant)
    isoluminant = false;
end

if length(cropSize) == 1
    % User passed a scalar cropSize - interpret it as a square crop size
    cropSize = [cropSize, cropSize];
end

% 'C:\Users\briankardon\Downloads\pixfmttest_22138014_2022-10-14-14-10-17-477486_686_merged.avi'
% 'C:\Users\briankardon\Downloads\ROIs\pixfmttest_22138014_2022-10-14-14-10-17-477486_686_merged_ROI.mat'

if ~exist('vd', 'var')
    disp('loading video')
    videoData = loadVideoData(videoPath);
end

disp('extracting trajectories')

% Extract a list of x and y coordinates at each time index when a
% trajectory marker exists
[t1, x1, y1] = extractManualObjectTrackerPointTrajectory(roiPath);

% Place the extracted coordinates into a filled array, with one element for
% each video frame.
x2 = nan(1, size(videoData, 3));
y2 = nan(1, size(videoData, 3));
x2(t1) = x1;
y2(t1) = y1;

% Ensure the end of the trajectory is not NaN for interpolation purposes
x2(end) = x1(end);
y2(end) = y1(end);

% Interpolate missing values
x3 = fillmissing(x2, 'pchip');
y3 = fillmissing(y2, 'pchip');

% Convert any fractional interpolated coordinates to integer pixel
% coordinates
x4 = round(x3);
y4 = round(y3);

disp('stabilizing video')
[videoData, dx, dy] = stabilizeVideo(videoData, x4, y4, true);

% If requested, crop the video around the tracked point
if ~isempty(cropSize)
    disp('cropping video')
    xStablePoint = round(mean(x4 + dx));
    yStablePoint = round(mean(y4 + dy));
    
    xCrop1 = floor(xStablePoint - (cropSize(1)-1)/2);
    xCrop2 = floor(xStablePoint + (cropSize(1)-1)/2);
    yCrop1 = floor(yStablePoint - (cropSize(2)-1)/2);
    yCrop2 = floor(yStablePoint + (cropSize(2)-1)/2);

    switch ndims(videoData)
        case 3
            videoData = videoData(yCrop1:yCrop2, xCrop1:xCrop2, :);
        case 4
            videoData = videoData(yCrop1:yCrop2, xCrop1:xCrop2, :, :);
    end
end

if isoluminant
    disp('isoluminizing video')
    videoData = makeVideoIsoluminant(videoData);
end