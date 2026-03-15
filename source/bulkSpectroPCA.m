function [score, transform, latent, tsquared, explained] = bulkSpectroPCA(paths, loader, fs, PCA_window, PCA_step, nT)
arguments
    paths
    loader
    fs
    PCA_window = 25
    PCA_step = 5
    nT = []
end

data = [];
for k = 1:length(paths)
    path = paths{k};
    newData = loader(path);
    data = vertcat(data, newData); %#ok<AGROW>
end

if isempty(nT)
    nT = round(length(data) / 432);
end

[score, transform, latent, tsquared, explained] = spectroPCA(data, fs, PCA_window, PCA_step, nT);