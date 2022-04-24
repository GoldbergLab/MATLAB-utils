function power = getAudioSpectrogram(audio, samplingRate, flim, tSize, color, clim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getAudioSpectrogram: Create a spectrogram of an audio signal as an array
% usage:  power = getAudioSpectrogram(audio, samplingRate, flim, 
%                                     tSize, color, clim)
%
% where,
%    power is a 2D or 3D array representing the spectrogram data either as
%       a 2D array, or formatted as a 3D color image.
%    audio is a 1D array representing an audio signal
%    samplingRate is the audio sampling rate in Hz
%    flim is the desired frequency limits for the spectrogram array, in Hz,
%       expressed as a 1x2 array, where flim(1) is the lowest calculated 
%       frequency, and flim(2) is the highest calculated frequency. Default
%       is [50, 7500].
%    tSize is the desired number of time bins for the spectrogram array.
%       Default is the number of audio samples divided by the window size.
%    color is a boolean flag indicating whether or not to output the
%       spectrogram as a 3D color image. Default is false, meaning the
%       output will be a 2D greyscale image.
%    clim is the desired color limits for the spectrogram. Any spectrogram
%       values less than or equal to clim(1) will be set to the first color
%       in the colormap. Any spectrogram values greater than or equal to
%       clim(2) will be set to the last color in the colormap. Intermediate
%       values will be spread across the colormap linearly. Default is
%       [12.5, 28]. Pass in NaN to spread the spectrogram across the entire
%       colormap. This only affects the output if the color argument is 
%       true.
%    
% Generate a spectrogram suitable for audio data.  Based on Aaron 
%    Andalman's electro_gui algorithm that accounts for screen resolution.
%    Use 'showAudioSpectrogram' instead if you just want a display and
%    don't need the array itself.
%
% See also: showAudioSpectrogram, egs_AAquick_sonogram
%
% Version: <1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NFFT = 512;
windowSize = 512;

if ~exist('flim', 'var') || isempty(flim)
    flim = [50, 7500];
end
if ~exist('color', 'var') || isempty(color)
    color = false;
end
if ~exist('clim', 'var') || isempty(clim)
    clim = [12.5, 28];
end
if ~exist('tlim', 'var') || isempty(tlim)
    tlim = round(length(audio) / windowSize);
end

numWindows = length(audio) / windowSize;
if(numWindows < tSize)
    %If we have more pixels than ffts, then increase the overlap
    %of fft windows accordingly.
    ratio = ceil(tSize/numWindows);
    windowOverlap = min(.999, 1 - (1/ratio));
    windowOverlap = floor(windowOverlap*windowSize);
else
    %If we have more ffts then pixels, then we can do things, we can
    %downsample the signal, or we can skip signal between ffts.
    %Skipping signal mean we may miss bits of song altogether.
    %Decimating throws away high frequency information.
    ratio = floor(numWindows/tSize);
    %windowOverlap = -1*ratio;
    %windowOverlap = floor(windowOverlap*windowSize);
    windowOverlap = 0;
    audio = decimate(audio, ratio);
    samplingRate = samplingRate / ratio;
end

%Compute the spectrogram
%[S,F,T,P] = spectrogram(sss,windowSize,windowOverlap,NFFT,Fs);
% [S,F,~] = specgram(audio, NFFT, samplingRate, windowSize, windowOverlap);
[S,F,~] = spectrogram(audio, windowSize, windowOverlap, NFFT, samplingRate);

freqInRange = (F>=flim(1)) & (F<=flim(2));

%The spectrogram
power = 2*log(abs(S(freqInRange,:))+eps)+20;
powerSize = size(power);

if color
    c = jet(64);
    numColors = length(c);
    c(1, :) = [0, 0, 0];
    if ~isnan(clim)
        minC = clim(1);
        maxC = clim(2);
        power = round((numColors - 1) * (power - minC) / (maxC - minC) + 1);
    else
        minPower = min(min(power));
        maxPower = max(max(power));
        power = round((numColors - 1) * (power - minPower) / (maxPower - minPower) + 1);
    end
    power(power < 1) = 1;
    power(power > numColors) = numColors;
    power = reshape(c(power, :), [powerSize, 3]);
end