function k = mod1(k, N)
% Literally just modulus where the minimum number is 1, rather than zero.
k = 1 + mod(k-1, N);