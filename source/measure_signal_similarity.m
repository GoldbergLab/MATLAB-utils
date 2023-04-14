function similarity_score = measure_signal_similarity(signal1, signal2, sampling_rate, flim, method, cached_spectrograms)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% measure_signal_similarity: Measure similarity between two time series
% usage:  similarity_score = measure_signal_similarity(signal1, signal2)f
%         similarity_score = measure_signal_similarity(signal1, signal2, sampling_rate)
%         similarity_score = measure_signal_similarity(signal1, signal2, sampling_rate, flim)
%         similarity_score = measure_signal_similarity(signal1, signal2, sampling_rate, flim, method)
%         similarity_score = measure_signal_similarity(signal1, signal2, sampling_rate, flim, method, cached_spectrogram)
%
% where,
%    signal1 is a 1D time series
%    signal2 is a 1D time series
%    sampling_rate is an optional number indicating the sampling rate of 
%       the time series in Hz. If a single scalar number is provided, the  
%       samesampling rate will be used for both time series. If a 1x2 
%       vector is provided, the two values will be used for signal1 and 
%       signal2 accordingly. Default is 20,000
%    flim is an optional 1x2 vector indicating the lowest and highest 
%       frequencies to consider when comparing spectrograms. Default is 
%       [50, 7500]
%    method is an optional char array indicating which similarity
%       comparison method should be used. The options are 
%           abs_diff
%           xcorr
%       See below for explanations of the algorithms.
%    cached_spectrograms is an optional boolean flag indicating that
%       signal1 and signal2 are pre-made spectrograms, rather than 1D
%       timeseries. If this flag is true, then signal1 and signal2 must be
%       2D arrays of the same size representing spectrograms. This
%       may be useful when running multiple comparisons between signals,
%       since creating the spectrograms is computationally expensive.
%    similarity_score is a number between 0 and 1 indicating how similar
%       the two timeseries are. 0 indicates the time series are maximally
%       dissimilar, 1 indicates they are identical.
%
% Comparison methods:
%
%%% abs_diff:
% 
% The 'abs_diff' algorithm measures the similarity between two audio clips
%   like so:
%   1. Compute a spectrogram of each signal
%   2. If one of the spectrograms is shorter in the time dimension, pad it
%       with zeros equally on the left and right so the two spectrograms 
%       have the same dimensions.
%   3. Z-score the pixels of each of the two spectrograms individually so 
%       pixel values can be compared across spectrograms.
%   4. Compute the mean of the absolute value of the differences between the
%       two z-scored spectrograms
%   5. Clamp the difference value to 7 (an arbitrarily chosen
%       value that captures almost all the variability typically seen in
%       zebrafinch syllables) such that any difference values over 7 are
%       set to seven
%   6. Normalize and scale the difference value to the range from 0 to 1, 
%       where 0 is maximally dissimilar, and 1 is identical.
% 
%   The similarity score can be described succinctly as a scaled mean
%       pixelwise absolute difference between z-score normalized 
%       spectrograms with zero padding for size matching.. It has the 
%       following generally desirable properties:
%   1. The scores range from 0 to 1, where 1 indicates the clips are 
%       identical, and 0 indicates the clipls are as different or more
%       different that the most divergent zebra finch syllables commonly
%       observed.
%   2. The score algorithm is commutative - that is:
%                   score(a, b) == score(b, a)
%   3. The score of a syllable with itself is always 1:
%                   score(a, a) == 1
%   4. The score is insensitive to volume changes; i.e. roughly speaking
%                   score(a, b) == score(k*a, b)
%
%%% xcorr:
%
% The 'xcorr' algorithm compares the similarity between two audio clips
%   like so:
%   1. Compute a spectrogram of each signal
%   2. Z-score the pixels of each of the two spectrograms individually so 
%       pixel values can be compared across spectrograms.
%   3. Compute a cross-correlation along the time axis between the two
%       spectrograms, sliding the smaller one along the larger one. At each
%       time shift, the sum of the product of the two spectrograms' pixels
%       are computed.
%   4. The cross-correlation is normalized such that the autocorrelation 
%       evaluates to 1
%
%%% ssim
%
% The 'ssim' algorithm uses the built in MATLAB "ssim" (structural
%   similarity index measure of image quality) to compare the spectrograms
%   of the two signals. The algorithm proceeds like so:
%   1. Compute a spectrogram of each signal
%   2. If one of the spectrograms is shorter in the time dimension, pad it
%       with zeros equally on the left and right so the two spectrograms 
%       have the same dimensions.
%   3. Z-score the pixels of each of the two spectrograms individually so 
%       pixel values can be compared across spectrograms.
%   4. Use the ssim function to generate a similarity score
%   
%
% See also: getAudioSpectrogram
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default arguments where necessary
if ~exist('sampling_rate', 'var') || isempty(sampling_rate)
    sampling_rate = 20000;
end
if ~exist('flim', 'var')
    flim = [];
end
if ~exist('cached_spectrograms', 'var') || isempty(cached_spectrograms)
    cached_spectrograms = false;
end
if ~exist('method', 'var') || isempty(method)
    method = 'abs_diff';
end

% If only one sampling rate was provided, use the same sampling rate for
% both signals
if length(sampling_rate) == 1
    sampling_rate = [sampling_rate, sampling_rate];
end

% This threshold 
maximum_dissimilarity_threshold = 7;

if ~cached_spectrograms
    % User passsed in actual 1D timeseries. Create the spectrograms

    % Generate spectrograms
    spectrogram1 = getAudioSpectrogram(signal1, sampling_rate(1), flim);
    spectrogram2 = getAudioSpectrogram(signal2, sampling_rate(2), flim);
else
    % User passed in pre-created spectrograms.
    spectrogram1 = signal1;
    spectrogram2 = signal2;
end

switch method
    case {'abs_diff', 'ssim'}
        pad_spect = true;
    case 'xcorr'
        pad_spect = false;
end

% Record mean/std before padding arrays
mean1 = mean(spectrogram1(:));
std1 = std(spectrogram1(:));
% Record mean/std before padding arrays
mean2 = mean(spectrogram2(:));
std2 = std(spectrogram2(:));

num_time_points1 = size(spectrogram1, 2);
num_time_points2 = size(spectrogram2, 2);

if pad_spect
    % Determine which spectrogram is smaller, and pad that with zeros to 
    % match the other one.
    size_diff = num_time_points1 - num_time_points2;
    pad = abs(size_diff/2);
    padval = 0;
    if size_diff > 0
        spectrogram2 = padarray(spectrogram2, [0, floor(pad)], padval, 'pre');
        spectrogram2 = padarray(spectrogram2, [0, ceil(pad)], padval, 'post');
    elseif size_diff < 0
        spectrogram1 = padarray(spectrogram1, [0, floor(pad)], padval, 'pre');
        spectrogram1 = padarray(spectrogram1, [0, ceil(pad)], padval, 'post');
    end
end

% Convert spectrograms to z-scores for comparison purposes
spectrogram1 = (spectrogram1 - mean1) / std1;
spectrogram2 = (spectrogram2 - mean2) / std2;

% % If an axes was provided, plot the spectrograms on it
% if ~isempty(ax)
%     hold(ax, 'on');
%     clim(ax, [-1.5, 1.5]);
%     image(1, 1, spectrogram1, 'CDataMapping', 'scaled');
%     image(size(spectrogram1, 2)+1, 1, spectrogram2, 'CDataMapping', 'scaled');
% end

switch method
    case 'abs_diff'
        % Find the mean absolute difference between the spectrograms
        dissimilarity_score = mean(abs(spectrogram1 - spectrogram2), 'all');
        
        % Clamp values over the max to the max
        if dissimilarity_score > maximum_dissimilarity_threshold
            dissimilarity_score = maximum_dissimilarity_threshold;
        end
        
        % Rescale the scores so they go from 0 (dissimilar) to 1 (identical)
        similarity_score = (maximum_dissimilarity_threshold - dissimilarity_score) / maximum_dissimilarity_threshold;
    case 'xcorr'
        % Sort the spectrograms by width (number of time points)
        if num_time_points1 < num_time_points2
            smaller_spectrogram = spectrogram1;
            larger_spectrogram =  spectrogram2;
            smaller_time_points = num_time_points1;
            larger_time_points =  num_time_points2;
        else
            smaller_spectrogram = spectrogram2;
            larger_spectrogram =  spectrogram1;
            smaller_time_points = num_time_points2;
            larger_time_points =  num_time_points1;
        end
        % Calculate how many times we'll need to shift the smaller
        %   spectrogram as we "slide" it across the larger spectrogram
        num_shifts = larger_time_points - smaller_time_points;
        % Initialize the vector of cross-correlation values, one for each
        %   shift.
        xcorr = zeros(1, num_shifts+1);
        % Calculate the auto-correlation of the smaller spectrogram, for
        %   normalization purposes later on.
        smaller_total = sum(smaller_spectrogram .^ 2, 'all');
        % Calculate the square of the larger spectrogram. We can't find the
        %   autocorrelation value yet, because it will be different for each 
        %   shift.
        larger_spectrogram_squared = larger_spectrogram .^ 2;
        % Initialize the vector that will hold the larger spectrogram's
        %   auto-correlation values.
        larger_total = zeros(1, num_shifts);
        % Loop over window start times, sliding the smaller spectrogram
        %   across the larger one along the time dimension, computing the
        %   product for each window.
        for w = 1:num_shifts+1
            % Compute the cross-correlation value for this shift
            xcorr(w) = sum(larger_spectrogram(:, w:w + smaller_time_points - 1) .* smaller_spectrogram, 'all');
            % Compute the auto-correlation value for this shift
            larger_total(w) = sum(larger_spectrogram_squared(:, w:w + smaller_time_points - 1), 'all');
        end
        % Normalize the cross-correlation values so they range from 0 to 1
        xcorr_normalized = xcorr ./ sqrt(larger_total * smaller_total);
        % Find the similarity score by taking the maximum cross-correlation
        %   value.
        similarity_score = max(xcorr_normalized);
    case 'ssim'
        % ssim needs a "dynamic range" for some reason, so we'll use 6
        %   sigma
        dynamic_range = max([6*std1, 6*std2]);
        % Compute the similarity score
        similarity_score = ssim(spectrogram1, spectrogram2, 'DynamicRange', dynamic_range);
end

return


% Other partial algorithms that I'm not 100% ready to give up on:

% % similarity_score = ssim(spectrogram1, spectrogram2);
% correlations = zeros(size(spectrogram1, 1), size(spectrogram1, 2) + size(spectrogram2, 2) - 1);
% autocorrelations1 = zeros(size(correlations));
% autocorrelations2 = zeros(size(correlations));
% 
% for frequency_idx = 1:size(spectrogram1, 1)
%     % Loop over frequency bands and obtain crosscorrelation
%     correlations(frequency_idx, :) =      xcorr(spectrogram1(frequency_idx, :), spectrogram2(frequency_idx, :), 'unbiased');
%     autocorrelations1(frequency_idx, :) = xcorr(spectrogram1(frequency_idx, :), spectrogram1(frequency_idx, :), 'unbiased');
%     autocorrelations2(frequency_idx, :) = xcorr(spectrogram2(frequency_idx, :), spectrogram2(frequency_idx, :), 'unbiased');
% end
% 
% center = size(spectrogram1, 2);
% max_shift = round(center/4);
% 
% correlations =           correlations(:, center-max_shift:center+max_shift);
% autocorrelations1 = autocorrelations1(:, center-max_shift:center+max_shift);
% autocorrelations2 = autocorrelations2(:, center-max_shift:center+max_shift);
% 
% correlations = mean(correlations, 1);
% autocorrelations1 = mean(autocorrelations1, 1);
% autocorrelations2 = mean(autocorrelations2, 1);
% 
% % Find the maximum cross-correlation
% similarity_score = max(correlations)/max(max(autocorrelations1), max(autocorrelations2));