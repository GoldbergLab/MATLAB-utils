function convhull_mask = convhull3Mask(mask)
[x, y, z] = ind2sub(size(mask), find(mask > 0));
xyz = [x, y, z];
k = convhulln(xyz);
x = x(k(:, 1));
y = y(k(:, 1));
z = z(k(:, 1));

convhull_mask = coordsTo3Mask(size(mask), x, y, z);