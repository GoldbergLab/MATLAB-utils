function [angle, xr, yr] = findFunctionalRotation(x, y, angles)
% Find an angle to rotate the coordinates given by the vectors x and y such
% that the resulting points could be from a function (they are ordered and
% have unique x-values)
foundAngle = false;
if ~exist('angles', 'var') || isempty(angles)
%    angles = (pi/8) * [0, 1, -1, 2, -2, 3, -3, 4, -4];
    angles = 0.005 * [0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 10, -10, 100, -100, 200, -200, 300, -300];
end
c = (x + 1i*y);
for angle = angles
    cr = exp(-angle*1i) * c;
    xr = real(cr);
    if all(diff(xr) > 0)
        foundAngle = true;
        break;
    end
end
if foundAngle
    yr = imag(cr);
else
    angle = NaN;
    xr = x;
    yr = y;
end
