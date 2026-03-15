function [score, transform, latent, tsquared, explained] = spectroPCA(data, fs, PCA_window, PCA_step, nT)
arguments
    data
    fs
    PCA_window
    PCA_step
    nT = round(length(data) / 432)
end

flim = [50, 7500];

%% Create the spectrogram
power = getAudioSpectrogram(data, fs, flim, nT);

nT = size(power, 2);

vecs = [];

for t = 1:PCA_step:(nT-PCA_window)
    win = power(:, t:(t+PCA_window));
    vecs = vertcat(vecs, win(:)'); %#ok<AGROW>
end

[coeff, score, latent, tsquared, explained, mu] = pca(vecs);

transform.coeff = coeff;
transform.mu = mu;
transform.flim = flim;
transform.fs = fs;
transform.PCA_window = PCA_window;
transform.PCA_step = PCA_step;

