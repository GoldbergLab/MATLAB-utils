function showAudioSpectrogram(audio, samplingRate, ax, flim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% showAudioSpectrogram: Display a spectrogram of an audio signal as an 
%   array
% usage:  power = showAudioSpectrogram(audio, samplingRate, ax, flim)
%
% where,
%    audio is a 1D array representing an audio signal
%    samplingRate is the audio sampling rate in Hz
%    ax is a handle for an axis. If omitted or empty, the gca() function
%       is used to get or create the active axes.
%    flim is the desired frequency limits for the spectrogram array, in Hz,
%       expressed as a 1x2 array, where flim(1) is the lowest calculated 
%       frequency, and flim(2) is the highest calculated frequency. Default
%       is [50, 7500].
%    
% Display a spectrogram suitable for audio data.  Based on Aaron 
%    Andalman's electro_gui algorithm that accounts for screen resolution.
%    Use 'getAudioSpectrogram' instead if you want the spectrogram as an
%    array or image rather than displaying it.
%
% See also: getAudioSpectrogram, egs_AAquick_sonogram
%
% Version: <1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('ax', 'var') || isempty(ax)
    ax = gca();
end
if ~exist('flim', 'var') || isempty(flim)
    flim = [50, 7500];
end

nCourse = 1;

ylim(ax, flim);

originalUnits = get(ax,'units');

set(ax,'Units','pixels');
pixSize = get(ax,'Position');
tSize = pixSize(3) / nCourse;

power = getAudioSpectrogram(audio, samplingRate, flim, tSize);

nFreqBins = size(power, 1);
nTimeBins = size(power, 2);
f = linspace(flim(1),flim(2),nFreqBins);

set(ax,'units',originalUnits);

xl = xlim(ax);

imagesc(ax, linspace(xl(1),xl(2), nTimeBins),f,power);

ax.YDir = 'normal';
c = colormap;
c(1, :) = [0, 0, 0];
ax.Colormap = c;
ax.CLim = [13.0000, 24.5000];