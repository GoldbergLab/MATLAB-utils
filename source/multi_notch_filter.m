function data_filtered = multi_notch_filter(data, sample_frequency, notch_frequencies, bandwidth, filter_order, plot_results)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% multi_notch_filter: Apply multiple notch filters on data simultaneously
% usage:  data_filtered = multi_notch_filter(data, sample_frequency, notch_frequencies, bandwidth, filter_order)
%         data_filtered = multi_notch_filter(data, sample_frequency, notch_frequencies, bandwidth)
%
% where,
%    data is a 1xN vector of data
%    sample_frequency is the sampling frequency in Hz
%    notch_frequencies is a 1xF vector of center frequencies for the
%       notches
%    bandwidth is either a scalar or 1xF vector of 1/sqrt(2) widths for the
%       notch filters. If it is a scalar, all the notches will have the
%       same width. If it is a 1xF vector, a separate width will be used
%       for each notch.
%    filter_order is either a scalar or 1xF vector of integers, indicating
%       the order of each notch filter. If it is a scalar, all the notches 
%       will have the same order. If it is a 1xF vector, a separate order
%       will be used for each notch.
%    plot_results is an optional boolean flag indicating whether or not
%       before and after spectrograms should be plotted. Default is false.
%
% Apply multiple notch filters to a time series.
%
% See also: butter, filter, spectrogram
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('filter_order', 'var') || isempty(filter_order)
    filter_order = 2;
end
if ~exist('plot_results', 'var') || isempty(plot_results)
    plot_results = false;
end

if length(bandwidth) == 1
    bandwidth = bandwidth * ones(size(notch_frequencies));
end
if length(filter_order) == 1
    filter_order = filter_order * ones(size(notch_frequencies));
end

if plot_results
    % Spectrogram parameters
    sg = 400;
    ov = 300;
    % Plot before spectrogram
    figure();
    ax1 = subplot(1, 2, 1);
    spectrogram(data,sg,ov,[],sample_frequency,"yaxis")
    colormap(ax1, 'bone')
end

for notch_num = 1:length(notch_frequencies)
    f = notch_frequencies(notch_num);
    w = bandwidth(notch_num);
    n = filter_order(notch_num);

    [b_new, a_new] = butter(n, [f-w/2, f+w/2] * 2 / sample_frequency, 'stop');

    if notch_num == 1
        a = a_new;
        b = b_new;
    else
        a = conv(a, a_new);
        b = conv(b, b_new);
    end
end

% Perform filtering
data_filtered = filter(b, a, data);

if plot_results
    % Plot after spectrogram
    ax2 = subplot(1, 2, 2);
    spectrogram(data_filtered,sg,ov,[],sample_frequency,"yaxis")
    colormap(ax2, 'bone');
end
