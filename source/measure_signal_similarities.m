function similarity_scores = measure_signal_similarities(signal_group1, signal_group2, sampling_rate, flim, method, parallelize)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% measure_signal_similarities: Measure similarity between groups of time series
% usage:  similarity_scores = measure_signal_similarities(signal_group1, signal_group2)
%         similarity_scores = measure_signal_similarities(signal_group1, signal_group2, sampling_rate)
%         similarity_scores = measure_signal_similarities(signal_group1, signal_group2, sampling_rate, flim)
%         similarity_scores = measure_signal_similarities(signal_group1, signal_group2, sampling_rate, flim, method)
%
% where,
%    signal_group1 is a 1D cell array containing one or more 1D time series
%    signal_group2 is a 1D cell array containing one or more 1D time series
%    sampling_rate is an optional number indicating the sampling rate of 
%       the signal groups in Hz. If a single scalar number is provided, the 
%       same sampling rate will be used for both signal groups. If a 1x2  
%       vector is provided, the two values will be used for signal_group1  
%       and signal_group2 accordingly. Default is 20,000.
%    flim is an optional 1x2 vector indicating the lowest and highest 
%       frequencies to consider when comparing spectrograms. Default is 
%       [50, 7500]
%    method is an optional char array indicating which similarity
%       comparison method should be used. The options are 
%           abs_diff
%           xcorr
%           ssim
%       See measure_signal_similarity for explanation of the methods.
%    parallelize is an optional boolean that indicates parallel processing
%       should be used to speed up computation. Default is true.
%    similarity_scores is a matrix of similiarity scores, where
%       similarity_scores(k, j) gives the similarity score between 
%       signal_group1(k) and signal_group2(j). Each similarity score is a
%       number between 0 and 1 indicating how similar the two timeseries 
%       are. 0 indicates the time series are maximally dissimilar, 1 
%       indicates they are identical.
%
% See also: measure_signal_similarity, getAudioSpectrogram
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
if ~exist('method', 'var') || isempty(method)
    method = 'abs_diff';
end
if ~exist('parallelize', 'var') || isempty(parallelize)
    parallelize = true;
end

if parallelize
    numWorkers = Inf;
else
    numWorkers = 0;
end

% If only one sampling rate was provided, use the same sampling rate for
% both signals
if length(sampling_rate) == 1
    sampling_rate = [sampling_rate, sampling_rate];
end

% Determine number of signals in each group
n1 = length(signal_group1);
n2 = length(signal_group2);

% Convert signals to spectrograms
spectrograms1 = {};
parfor (k = 1:n1, numWorkers)
    spectrograms1{k} = getAudioSpectrogram(signal_group1{k}, sampling_rate(1), flim);
end
spectrograms2 = {};
parfor (j = 1:n2, numWorkers)
    spectrograms2{j} = getAudioSpectrogram(signal_group2{j}, sampling_rate(2), flim);
end

cached_spectrograms = true;

% Compute similarity scores for each pair of signals between group 1 and 2
similarity_scores = nan(length(spectrograms1), length(spectrograms2));
parfor (k = 1:n1, numWorkers)
    for j = 1:n2
        similarity_scores(k, j) = measure_signal_similarity(spectrograms1{k}, spectrograms2{j}, sampling_rate, flim, method, cached_spectrograms);
    end
end