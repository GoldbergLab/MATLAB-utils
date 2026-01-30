function reconstructedAudio = audioSpectrogramReconstruction(audio, samplingRate, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% audioSpectrogramReconstruction: Compute stft, then invert back to signal
% usage: reconstructedAudio = audioSpectrogramReconstruction(audio, 
%                               samplingRate, "Name", "Value", ...)
%
% where,
%    audio is a 1D audio signal
%    samplingRate is the sampling rate of the audio
%    Name/Value pairs may include:
%       FLim: Frequency limits of spectrogram. Default is [50, 7500]
%       NFFT: Number of FFT points. Default is 512
%       WindowSize: Size of STFT window. Default is 512
%       TSize
%       Color
%       CLim = [12.5, 28]
%       Axes = gca()
%       SpectrogramModifier: A function handle that takes a spectrogram
%           and returns a potentially modified spectrogram before 
%           reconstruction. Default is @(x)x
%   
%    reconstructedAudio is a reconstructed audio signal
%
% This function takes an audio signal, processes it with the short time
%    fourier transform function (STFT), optionally modifies the 
%    spectrogram, then inverts the STFT function and returns a 
%    reconstructed audio signal.
%
% See also: getAudioSpectrogram, spectrogramPhaseRandomizer
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    audio
    samplingRate
    options.FLim = [50, 7500]
    options.NFFT = 512
    options.WindowSize = 512
    options.TSize = []
    options.Color = false
    options.CLim = [12.5, 28]
    options.Axes = gca()
    options.SpectrogramModifier = @(x)x
end

if isempty(options.TSize)
    options.TSize = round(length(audio) / options.WindowSize);
end

numWindows = length(audio) / options.WindowSize;
if(numWindows < options.TSize)
    %If we have more pixels than ffts, then increase the overlap
    %of fft windows accordingly.
    ratio = ceil(options.TSize/numWindows);
    windowOverlap = min(.999, 1 - (1/ratio));
    windowOverlap = floor(windowOverlap*options.WindowSize);
else
    %If we have more ffts then pixels, then we can do things, we can
    %downsample the signal, or we can skip signal between ffts.
    %Skipping signal mean we may miss bits of song altogether.
    %Decimating throws away high frequency information.
    ratio = floor(numWindows/options.TSize);
    %windowOverlap = -1*ratio;
    %windowOverlap = floor(windowOverlap*options.WindowSize);
    windowOverlap = 0;
    audio = decimate(audio, ratio);
    samplingRate = samplingRate / ratio;
end

%Compute the spectrogram
%[S,F,T,P] = spectrogram(sss,options.WindowSize,windowOverlap,options.NFFT,Fs);
% [S,F,~] = specgram(audio, options.NFFT, samplingRate, options.WindowSize, windowOverlap);
% [S,F, T] = spectrogram(audio, options.WindowSize, windowOverlap, options.NFFT, samplingRate);

[S, F, T] = stft(audio, samplingRate, 'Window', hamming(options.WindowSize), "OverlapLength", windowOverlap, "FFTLength", options.NFFT, "FrequencyRange", "onesided");

S = options.SpectrogramModifier(S);

reconstructedAudio = istft(S, samplingRate, "Window", hamming(options.WindowSize), "OverlapLength", windowOverlap, "FFTLength", options.NFFT, "FrequencyRange", "onesided");

freqInRange = (F>=options.FLim(1)) & (F<=options.FLim(2));

%The spectrogram
power = 2*log(abs(S(freqInRange,:))+eps)+20;
powerSize = size(power);

if options.Color
    c = jet(64);
    numColors = length(c);
    c(1, :) = [0, 0, 0];
    if ~isnan(options.CLim)
        minC = options.CLim(1);
        maxC = options.CLim(2);
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

displayAudioSpectrogram(power, options.Axes, options.FLim, options.CLim);

