function v = allBut1(n, k)
v = zeros(n, 1, 'logical');
v(k) = 1;