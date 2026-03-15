function mesh3MaskSurface(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mesh3MaskSurface: Display a 3D mesh of the surface of a 3D logical mask
% usage:  mesh3MaskSurface(mask)
%         mesh3MaskSurface(ax, mask)
%
% where,
%    mask is a 3D logical array
%    ax is an optional handle to an existing axes object to plot the mask
%       surface mesh in.
%
% This function displays a 3D mesh of the surface of any logical true
%   regions in the given 3D mask. Note that this uses a very simple "dumb"
%   algorithm, and does not produce a good manifold mesh - it will contain
%   lots of unnecessary overlapping and interior non-manifold faces. It
%   looks fine, but is not currently suitable for applications like 3D
%   printing.
%
% See also: plot3Mask
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if user passed in axes object
if isgraphics(varargin{1})
    ax = varargin{1};
    varargin(1) = [];
else
    % Nope, create/get one
    ax = gca();
end

% Get mask user passed in
mask = varargin{1};

% Create a set of x, y, and z coordinate arrays for the mask
[allx, ally, allz] = ndgrid(1:size(mask, 1), 1:size(mask, 2), 1:size(mask, 3));

% Get the surfaces of the mask
mask = get3MaskSurface(mask);

% Get the mask size
maskSize = size(mask);

% Get the coordinates of all the true pixels in the mask
[xs, ys, zs] = ind2sub(maskSize, find(mask > 0));

remainingNeighbors = true(1, length(xs));

for k = 1:length(xs)
    fprintf('%d of %d\n', k, length(xs))
    ix = xs(k);
    iy = ys(k);
    iz = zs(k);
    for j = 1:length(xs)
        if remainingNeighbors(j)
            nix = xs(j);
            niy = ys(j);
            niz = zs(j);
            if abs(nix - ix) < 2 && abs(niy - iy) < 2 && abs(niz - iz) < 2
                if nix ~= ix || niy ~= iy || niz ~= iz
                    % This is a neighbor
                    line(ax, [ix, nix], [iy, niy], [iz, niz]);
                end
            end
        end
        remainingNeighbors(j) = false;
    end    
end

return;

% Generate list of neighbor offset coordinates
[dxs, dys, dzs] = ndgrid(-1:1, -1:1, -1:1);
middleIdx = sub2ind([3, 3, 3], 2, 2, 2);
dxs(middleIdx) = [];
dys(middleIdx) = [];
dzs(middleIdx) = [];

% Calculate number of true pixels in the mask, each of which will be used
% as a vertex in the mesh
numVertices = length(xs);

% Prepare an empty array for holding the faces
faces = zeros([numVertices*26*25, 3]);

% Initialize the face counter
faceIdx = 0;

% Loop over surface vertices
for k = 1:numVertices
%    displayProgress('Checked %d of %d vertices\n', k, numVertices, 20);

    % Get linear index of this surface vertex
    k1 = sub2ind(maskSize, xs(k), ys(k), zs(k));
    % Get coords of neighbor points
    x = xs(k) + dxs;
    y = ys(k) + dys;
    z = zs(k) + dzs;
    % Filter neighbor point coords so we only consider neighbors in the
    % boundaries of the mask.
    inBounds = (x >= 1 & x <= maskSize(1) & y >= 1 & y <= maskSize(2) & z >= 1 & z <= maskSize(3));
    x = x(inBounds);
    y = y(inBounds);
    z = z(inBounds);
    % Get linear indices of neighbors
    idx = sub2ind(maskSize, x, y, z);
    % Filter neighbors indices to only include actual surface vertices
    x = x(mask(idx));
    y = y(mask(idx));
    z = z(mask(idx));
    idx = idx(mask(idx));
    % Loop over neighbor vertices
    for n = 1:numel(idx)
        k2 = idx(n);
        % Loop over neighbor vertices again to form a potential triangle
        for m = 1:numel(idx)
            % Check that neighbors are within 1 grid spacing of each other
            if abs(x(m)-x(n)) > 1 || abs(y(m)-y(n)) > 1 || abs(z(m)-z(n)) > 1
                continue;
            end
            k3 = idx(m);
            if k2 == k3
                continue;
            end

            % Store face in array
            faceIdx = faceIdx + 1;
            faces(faceIdx, :) = [k1, k2, k3];
        end
    end
end

% Trim array to only the faces that have been found
faces = faces(1:faceIdx, :);

% Sort each face so lowest-index coordinates come first
faces = sort(faces, 2);

% Remove duplicate faces, b
faces = unique(faces, 'rows');

trisurf(faces, allx(:), ally(:), allz(:), 'Parent', ax);

axis(ax, 'equal');
axis(ax, 'vis3d');
