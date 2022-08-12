function [onsets, offsets] = findOnsetOffsetPairs(signalMask, signalOnSamples, includePartialPulses)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findOnsetOffsetPairs: find onset/offset pairs for either logical signal 
%   mask or a list of signal on frames
% usage:  [onsets, offsets] = findOnsetOffsetPairs(signalMask)
%         [onsets, offsets] = findOnsetOffsetPairs([], signalOnSamples)
%         [onsets, offsets] = findOnsetOffsetPairs(signalMask, [], true)
%         [onsets, offsets] = findOnsetOffsetPairs([], signalOnSamples, true)
%
% where,
%    signalMask is a logical mask indicating where the signal is on/off
%    signalOnSamples is a list of timesteps where the signal was on. If
%       signalMask is provided, signalOnSamples is ignored; the user need
%       only provide one or the other.
%    includePartialPulses is an optional boolean flag indicating whether to
%       keep or eliminate pulses that start/end right at the beginning or
%       end of the signal. Default is false.
%
% <long description>
%
% See also: <related functions>
%
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('includePartialPulses', 'var') || isempty(includePartialPulses)
    includePartialPulses = false;
end

if isempty(signalMask)
    minFrame = min(signalOnSamples);
    maxFrame = max(signalOnSamples);
    signalMask = false(1, maxFrame+1);
    signalMask(signalOnSamples) = true;
else
    minFrame = 1;
    maxFrame = length(signalMask);
end

onsets = find(diff(signalMask)>0)+1;
offsets = find(diff(signalMask)<0);

% Handle pulses that start at (or before) the first frame
if min(offsets) < min(onsets)
    if includePartialPulses
        onsets = [minFrame, onsets];
    else
        offsets(1) = [];
    end
end

% Handle pulses that end at (or after) the last frame
if max(onsets) > max(offsets)
    if includePartialPulses
        offsets(end+1) = maxFrame;
    else
        onsets(end) = [];
    end
end