function plotOval(ax, center, radii, color)

N = 100;
step = 2*radii / N;
x = center(1) + (-radii(1):step:radii(1));
y = center(2) + ((radii(2)^2) * (1 - ((x - center(1)).^2)/(radii(1)^2))).^0.5;
y2 = center(2) - ((radii(2)^2) * (1 - ((x - center(1)).^2)/(radii(1)^2))).^0.5;
plot(ax, [x, flip(x)], [y, flip(y2)], 'Color', color);