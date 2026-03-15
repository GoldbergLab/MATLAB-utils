function gridV = mapCloudToGrid(x, y, z, v, xg, yg, zg, maxDistance)
% x, y, z are lists of coordinates for cloud of points, and v are the 
% values for each point
% xg, yg, zg are grid vectors of x, y, and z coordinates, as in the
% inputs to ndgrid

%[X, Y, Z] = ndgrid(xg, yg, zg);

gridV = nan(length(xg), length(yg), length(zg));

for xk = 1:length(xg)
    for yk = 1:length(yg)
        for zk = 1:length(zg)
            squareDistances = (x - xk).^2 + (y - yk).^2 + (z - zk).^2;
            [minDistance, idx] = min(squareDistances);
            if minDistance < maxDistance
                gridV(xk, yk, zk) = v(idx);
            end
        end
    end
end