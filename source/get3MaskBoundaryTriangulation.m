function blobs = get3MaskBoundaryTriangulation(mask)

surface_mask = get3MaskSurface(mask);
blobs = {};
[surface_mask_labels, N] = bwlabeln(surface_mask);

neighborhood = [
    -1    -1    -1
    -1    -1     0
    -1    -1     1
    -1     0    -1
    -1     0     0
    -1     0     1
    -1     1    -1
    -1     1     0
    -1     1     1
     0    -1    -1
     0    -1     0
     0    -1     1
     0     0    -1
     0     0     1
     0     1    -1
     0     1     0
     0     1     1
     1    -1    -1
     1    -1     0
     1    -1     1
     1     0    -1
     1     0     0
     1     0     1
     1     1    -1
     1     1     0
     1     1     1
];

[x, y, z] = ndgrid(1:size(mask, 1), 1:size(mask, 2), 1:size(mask, 3));
xyz = [x(:), y(:), z(:)];
maskIdx = sub2ind(size(mask), x, y, z);

for j = 1:N
    surfIdx = find(surface_mask_labels == j)';
%     [x, y, z] = ind2sub(size(surface_mask_labels), surfIdx);
%     vertices = [x, y, z];
    connectivity = [];
    voxelCount = 0;
    for idx = surfIdx
        voxelCount = voxelCount + 1;
        displayProgress('%d of %d\n', voxelCount, length(surfIdx), 100)
        % Get list of neighbor coordinates
        neighbors = neighborhood + xyz(idx, :);
        % Convert coordinates to 1D mask indices
        neighborIdx = sub2ind(size(mask), neighbors(:, 1), neighbors(:, 2), neighbors(:, 3));
        % Filter for voxels in this region
        neighborIdx = neighborIdx(surface_mask_labels(neighborIdx)==j);
        % Triangulate region
        localConnectivity = permutations(neighborIdx, 2, true);
        localConnectivity(:, 3) = idx;
        connectivity = [connectivity; localConnectivity];
    end
    connectivity = unique(sort(connectivity, 2), 'rows');
%    [connectivityList, vertices] = isosurface(surface_mask_labels, j);
    DT = triangulation(connectivity, xyz);
    [connectivity, outerVertices] = DT.freeBoundary();
    blobs(j, 1:2) = {connectivity, outerVertices};
end
