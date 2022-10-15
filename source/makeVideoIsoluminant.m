function isoluminantVideoData = makeVideoIsoluminant(videoData, brightness)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% makeVideoIsoluminant: correct the brightness of each frame in a video
% usage:  isoluminantVideoData = makeVideoIsoluminant(videoData)
%         isoluminantVideoData = makeVideoIsoluminant(videoData, brightness)
%
% where,
%    videoData is a 3D (H x W X N) or 4D (H x W x C x N) array representing
%       a video
%    brightness is an optional parameter indicating what each frame 
%    isoluminantVideoData is the resultant array representing the video
%       with adjusted frame brightness. This will have the same size and
%       class as the input videoData
%
% This function takes a 3D or 4D stack of images (such as a video), and
%   sets the brightness of each frame to the same value; either a given
%   brightness, or the overall mean brightness of the original video.
%
% Note that as written, this uses a simplistic definition of isoluminant. 
%   It is not perceptually adjusted or whatever.
%
% See also: loadVideoData
%
% Version: 1.1
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('brightness', 'var') || isempty(brightness)
    % Brightness value not provided - use the overall video mean brightness
    %   as the target brightness
    brightness = mean(videoData, 'all');
end

originalClass = class(videoData);

% Create a 1 x N vector of mean brightness for each frame
switch ndims(videoData)
    case 3
        frameBrightness = mean(videoData, [1, 2]);
    case 4
        frameBrightness = mean(videoData, [1, 2, 3]);
    otherwise
        error('Video data must be 3D or 4D');
end

% Calculate an adjustment factor for each frame that will bring the frame
%   to the target brightness
adjustmentFactor = brightness / frameBrightness;

% Adjust frames by multiplying each one by the adjustment factor
isoluminantVideoData = cast(round(double(videoData) .* adjustmentFactor), originalClass);