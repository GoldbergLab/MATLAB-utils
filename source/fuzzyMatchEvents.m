function scale = fuzzyMatchEvents(events1, events2, min_scale, max_scale)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fuzzyMatchEvents: Find best scaling match between two event vectors
% usage: scale = fuzzyMatchEvents(events1, events2, min_scale, max_scale)
%
% where,
%    events1 is a list of event times, potentially with some missing or 
%       inaccurate
%    events2 is another list of the same event times also potentially with
%       some missing or inaccurate, also potentially with a different
%       scale/unit/sampling rate as the first event list.
%    min_scale is the minimum possible scaling factor difference between
%       the two time series.
%    max_scale is the maximum possible scaling factor difference between
%       the two time series
%    scale is the best scale found to match the two event series, such that
%       events1 ~~ events2 * scale
%
% This function tries to find the best scaling factor to match two time
%   series, even if the time series are missing data points, or have 
%   spurious time points. Note that this function assumes that the first
%   event time in events1 and events2 definitely correspond to the same
%   event.
%
% See also: <related functions>
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    events1
    events2
    min_scale = 0.1
    max_scale = 10
end

% Ensure first events are aligned
events1 = events1 - events1(1);
events2 = events2 - events2(1);

options = optimset( ...
    'Display','none', ...
    'TolFun', 1e-12, ...
    'MaxFunEvals', 2000, ...
    'MaxIter', 2000 ...
    );
scale = fminbnd( ...
    @(scale)-getSimilarity(events1, events2, [scale, 0]), ...
    min_scale, ...
    max_scale, ...
    options ...
    );

function similarity = getSimilarity(vec1, vec2, transform, options)
arguments
    vec1
    vec2
    transform (1, 2) double
    options.Output = 'similarity'  % or 'struct'
end

scale = transform(1);
offset = transform(2);

vec2 = vec2 * scale + offset;

% Truncate longer vector
if length(vec2) ~= length(vec1)
    if length(vec2) > length(vec1)
        vec2 = vec2(1:length(vec1)+1);
    else
        vec1 = vec1(1:length(vec2)+1);
    end
end

if iscolumn(vec1)
    vec1 = vec1';
end
if iscolumn(vec2)
    vec2 = vec2';
end

distances = abs(vec1' - vec2);

[min_distances, min_idx] = min(distances, [], 2);

similarity = - mean(min_distances);

% fprintf('Scale=%f Offset=%f Sim=%f\n', transform(1), transform(2), similarity)
% disp(vec1)
% disp(vec2)
% disp('\/')
% disp(vec2*transform(1) + transform(2))
if strcmp(options.Output, 'struct')
    output.similarity = similarity;
    output.matches = vec2(min_idx);
    output.distances = min_distances;
    similarity = output;
end