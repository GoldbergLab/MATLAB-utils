function mesh3D = assembleDicomMask3D(dicom_root, threshold)
dcms = findPaths(dicom_root, '.*\.dcm');

mesh3D = [];

for k = 1:length(dcms)
    dcm = dcms{k};
    im = dicomread(dcm);
    if isempty(mesh3D)
        mesh3D = false([size(im), length(dcms)]);
    end
    mesh3D(:, :, k) = im > threshold; %#ok<AGROW>
end